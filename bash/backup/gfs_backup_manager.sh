#!/usr/bin/env bash

# === Konfiguration ===
DAILY_RETENTION_DAYS="8"    # Tage für tägliche Backups
WEEKLY_RETENTION_WEEKS="12" # Wochen für wöchentliche Archive
MONTHLY_RETENTION_MONTHS="12" # Monate für monatliche Archive

DRY_RUN="1" # 1: Nur anzeigen. 0: Tatsächlich löschen (VORSICHT!).
LOG_FILE="/var/log/lxc_backup_cleanup.log"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
STORAGE_CFG_FILE="/etc/pve/storage.cfg"

# === Hilfsfunktionen für Logging ===
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
log_info() { log "INFO: $1"; }
log_warning() { log "WARNUNG: $1"; }
log_error() { log "FEHLER: $1"; }

# === Hauptskript ===
set -e 
set -o pipefail

log_info "Starte LXC Backup GFS Cleanup Skript."
log_info "Aufbewahrungsregeln: Täglich=${DAILY_RETENTION_DAYS}d, Wöchentlich=${WEEKLY_RETENTION_WEEKS}w, Monatlich=${MONTHLY_RETENTION_MONTHS}m. Dry Run: ${DRY_RUN}."

for cmd in pct pvesm awk date; do
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Benötigter Befehl '$cmd' nicht gefunden. Bitte installieren."
        exit 1
    fi
done
log_info "Alle Abhängigkeiten sind vorhanden."

LXC_IDS_RAW=$(pct list | awk 'NR>1 {print $1}')
if [ -z "$LXC_IDS_RAW" ]; then
    log_warning "Keine LXC Container gefunden. Beende Skript."
    exit 0
fi
LXC_IDS_STR=$(echo "$LXC_IDS_RAW" | tr '\n' ' ')
log_info "Gefundene LXC IDs: $LXC_IDS_STR"

if [ ! -r "$STORAGE_CFG_FILE" ]; then
    log_error "Speicher Konfigurationsdatei '$STORAGE_CFG_FILE' nicht lesbar. Beende Skript."
    exit 1
fi
BACKUP_STORAGES_RAW=$(awk '/^([a-z]+):/ { current_id = $2 } /^\s+content\s+/ { if (current_id && $0 ~ /backup/) { print current_id; current_id = "" } }' "$STORAGE_CFG_FILE")
if [ -z "$BACKUP_STORAGES_RAW" ]; then
    log_warning "Keine Backup-Speicher in '$STORAGE_CFG_FILE' gefunden. Beende Skript."
    exit 0
fi
log_info "Gefundene Backup-Speicher: $(echo "$BACKUP_STORAGES_RAW" | tr '\n' ' ')"

CURRENT_EPOCH=$(date +%s)
TOTAL_IDENTIFIED_FOR_DELETION=0
TOTAL_ACTUALLY_DELETED_COUNT=0

for storage_name in $BACKUP_STORAGES_RAW; do
    log_info "Verarbeite Speicher: $storage_name"
    
    ALL_BACKUPS_ON_STORAGE_RAW=$(pvesm list "$storage_name" --content backup 2>&1)
    pvesm_exit_code=$?

    if [ $pvesm_exit_code -ne 0 ]; then
        log_error "Fehler beim Auflisten der Backups auf Speicher '$storage_name'. Ausgabe: $ALL_BACKUPS_ON_STORAGE_RAW"
        continue
    fi

    for lxc_id in $LXC_IDS_STR; do
        log_info "Analysiere Backups für LXC ID $lxc_id auf Speicher $storage_name"

        vm_backup_data_for_awk=$(echo "$ALL_BACKUPS_ON_STORAGE_RAW" | awk -v vmid_filter="$lxc_id" '
            NR > 1 && $NF == vmid_filter && $1 ~ /vzdump-lxc-/ {
                volid = $1;
                if (match(volid, /([0-9]{4})_([0-9]{2})_([0-9]{2})/)) {
                    year = substr(volid, RSTART, 4);
                    month_num = substr(volid, RSTART + 5, 2);
                    day_num = substr(volid, RSTART + 8, 2);
                    date_str = year "-" month_num "-" day_num;
                    
                    cmd_epoch = "date -d \"" date_str "\" +%s";
                    cmd_yw = "date -d \"" date_str "\" +\"%G-%V\""; 
                    cmd_ym = "date -d \"" date_str "\" +\"%Y-%m\""; 
                    
                    epoch = ""; yw = ""; ym = "";
                    if ((cmd_epoch | getline epoch) > 0) close(cmd_epoch); else epoch="ERROR";
                    if ((cmd_yw | getline yw) > 0) close(cmd_yw); else yw="ERROR";
                    if ((cmd_ym | getline ym) > 0) close(cmd_ym); else ym="ERROR";

                    if (epoch != "ERROR" && yw != "ERROR" && ym != "ERROR") {
                        print epoch, volid, yw, ym;
                    }
                }
            }
        ' | sort -k1,1nr) 

        if [ -z "$vm_backup_data_for_awk" ]; then
            log_info "Keine gültigen Backup-Einträge für LXC ID $lxc_id auf $storage_name gefunden oder Fehler bei der Datumsverarbeitung."
            continue
        fi

        gfs_awk_output=$(echo "$vm_backup_data_for_awk" | awk \
            -v DAILY_DAYS="$DAILY_RETENTION_DAYS" \
            -v WEEKLY_WEEKS="$WEEKLY_RETENTION_WEEKS" \
            -v MONTHLY_MONTHS="$MONTHLY_RETENTION_MONTHS" \
            -v CURRENT_EPOCH_AWK="$CURRENT_EPOCH" \
            -v lxc_id_awk="$lxc_id" '
        BEGIN {
            kept_weekly_slots_count = 0;
            kept_monthly_slots_count = 0;
            identified_for_deletion_this_vm = 0;
        }
        {
            epoch = $1; volid = $2; year_week = $3; year_month = $4;
            age_seconds = CURRENT_EPOCH_AWK - epoch;
            age_days = int(age_seconds / 86400);
            keep_this_backup = 0; 
            reason = "";

            if (age_days <= DAILY_DAYS) {
                keep_this_backup = 1;
                reason = "Täglich (innerhalb " DAILY_DAYS " Tagen)";
            }

            if (keep_this_backup == 0 && age_days <= (WEEKLY_WEEKS * 7)) {
                if (!(year_week in kept_weekly_slots)) {
                    keep_this_backup = 1;
                    kept_weekly_slots[year_week] = volid; 
                    reason = "Wöchentliches Archiv für Woche " year_week;
                }
            }

            if (keep_this_backup == 0 && age_days <= (MONTHLY_MONTHS * 31)) { 
                if (!(year_month in kept_monthly_slots)) {
                    keep_this_backup = 1;
                    kept_monthly_slots[year_month] = volid; 
                    reason = "Monatliches Archiv für Monat " year_month;
                }
            }

            if (keep_this_backup == 1) {
                printf "GFS_KEEP_INFO: %s (LXC: %s, Alter: %d Tage, Grund: %s)\n", volid, lxc_id_awk, age_days, reason;
            } else {
                printf "GFS_DELETE_INFO: %s (LXC: %s, Alter: %d Tage, keine GFS-Regel zur Aufbewahrung)\n", volid, lxc_id_awk, age_days;
                print "GFS_DELETE_CMD: pvesm free " volid;
                identified_for_deletion_this_vm++;
            }
        }
        END {
            print "AWK_IDENTIFIED_COUNT:"identified_for_deletion_this_vm;
        }
        ')

        while IFS= read -r line; do
            case "$line" in
                GFS_KEEP_INFO:*|GFS_DELETE_INFO:*)
                    log_info "${line#*: }" 
                    ;;
                GFS_DELETE_CMD:*)
                    actual_cmd="${line#*: }"
                    log_info "Befehl (aus GFS): $actual_cmd"
                    if [ "$DRY_RUN" -eq "0" ]; then
                        log_info "Führe aus (aus GFS): $actual_cmd"
                        if eval "$actual_cmd"; then
                            log_info "ERFOLG (aus GFS): $actual_cmd"
                            TOTAL_ACTUALLY_DELETED_COUNT=$((TOTAL_ACTUALLY_DELETED_COUNT + 1))
                        else
                            log_error "FEHLER beim Ausführen von (aus GFS): $actual_cmd (Exit-Code: $?)"
                        fi
                    fi
                    ;;
                AWK_IDENTIFIED_COUNT:*)
                    CURRENT_IDENTIFIED_COUNT=${line#*:}
                    TOTAL_IDENTIFIED_FOR_DELETION=$((TOTAL_IDENTIFIED_FOR_DELETION + CURRENT_IDENTIFIED_COUNT))
                    ;;
            esac
        done < <(echo "$gfs_awk_output")
    done 
done 

log_info "LXC Backup GFS Cleanup Skript beendet."
if [ "$DRY_RUN" -eq "1" ]; then
    log_info "Dry Run: ${TOTAL_IDENTIFIED_FOR_DELETION} Backup(s) würden gemäß GFS-Regeln gelöscht werden."
else
    log_info "Tatsächliches Löschen: ${TOTAL_ACTUALLY_DELETED_COUNT} Backup(s) wurden erfolgreich gelöscht."
    log_info "${TOTAL_IDENTIFIED_FOR_DELETION} Backup(s) wurden insgesamt zur Löschung identifiziert."
fi

set +e
set +o pipefail
exit 0
