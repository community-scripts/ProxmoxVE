// Copyright (c) 2021-2025 community-scripts ORG
// Author: Michel Roegl-Brunner (michelroegl-brunner)
// License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	"github.com/rs/cors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var client *mongo.Client
var collection *mongo.Collection

func loadEnv() {
	if err := godotenv.Load(); err != nil {
		log.Fatal("Error loading .env file")
	}
}

// DataModel represents a single document in MongoDB
type DataModel struct {
	ID         primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	CT_TYPE    uint               `json:"ct_type" bson:"ct_type"`
	DISK_SIZE  float32            `json:"disk_size" bson:"disk_size"`
	CORE_COUNT uint               `json:"core_count" bson:"core_count"`
	RAM_SIZE   uint               `json:"ram_size" bson:"ram_size"`
	OS_TYPE    string             `json:"os_type" bson:"os_type"`
	OS_VERSION string             `json:"os_version" bson:"os_version"`
	DISABLEIP6 string             `json:"disableip6" bson:"disableip6"`
	NSAPP      string             `json:"nsapp" bson:"nsapp"`
	METHOD     string             `json:"method" bson:"method"`
	CreatedAt  time.Time          `json:"created_at" bson:"created_at"`
	PVEVERSION string             `json:"pve_version" bson:"pve_version"`
	STATUS     string             `json:"status" bson:"status"`
	RANDOM_ID  string             `json:"random_id" bson:"random_id"`
	TYPE       string             `json:"type" bson:"type"`
	ERROR      string             `json:"error" bson:"error"`
}

type StatusModel struct {
	RANDOM_ID string `json:"random_id" bson:"random_id"`
	ERROR     string `json:"error" bson:"error"`
	STATUS    string `json:"status" bson:"status"`
}

type CountResponse struct {
	TotalEntries int64            `json:"total_entries"`
	StatusCount  map[string]int64 `json:"status_count"`
	NSAPPCount   map[string]int64 `json:"nsapp_count"`
}

// ConnectDatabase initializes the MongoDB connection
func ConnectDatabase() {
	loadEnv()

	mongoURI := fmt.Sprintf("mongodb://%s:%s@%s:%s",
		os.Getenv("MONGO_USER"),
		os.Getenv("MONGO_PASSWORD"),
		os.Getenv("MONGO_IP"),
		os.Getenv("MONGO_PORT"))

	database := os.Getenv("MONGO_DATABASE")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var err error
	client, err = mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal("Failed to connect to MongoDB!", err)
	}
	collection = client.Database(database).Collection("data_models")
	fmt.Println("Connected to MongoDB on 10.10.10.18")
}

// UploadJSON handles API requests and stores data as a document in MongoDB
func UploadJSON(w http.ResponseWriter, r *http.Request) {
	var input DataModel

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	input.CreatedAt = time.Now()

	_, err := collection.InsertOne(context.Background(), input)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Println("Received data:", input)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "Data saved successfully"})
}

// UpdateStatus updates the status of a record based on RANDOM_ID
func UpdateStatus(w http.ResponseWriter, r *http.Request) {
	var input StatusModel

	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	filter := bson.M{"random_id": input.RANDOM_ID}
	update := bson.M{"$set": bson.M{"status": input.STATUS, "error": input.ERROR}}

	_, err := collection.UpdateOne(context.Background(), filter, update)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	log.Println("Updated data:", input)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Record updated successfully"})
}

// GetDataJSON fetches all data from MongoDB
func GetDataJSON(w http.ResponseWriter, r *http.Request) {
	var records []DataModel
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.M{})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var record DataModel
		if err := cursor.Decode(&record); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		records = append(records, record)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(records)
}
func GetPaginatedData(w http.ResponseWriter, r *http.Request) {
	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	skip := (page - 1) * limit
	var records []DataModel
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	options := options.Find().SetSkip(int64(skip)).SetLimit(int64(limit))
	cursor, err := collection.Find(ctx, bson.M{}, options)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var record DataModel
		if err := cursor.Decode(&record); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		records = append(records, record)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(records)
}

func GetSummary(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	totalCount, err := collection.CountDocuments(ctx, bson.M{})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	statusCount := make(map[string]int64)
	nsappCount := make(map[string]int64)

	pipeline := []bson.M{
		{"$group": bson.M{"_id": "$status", "count": bson.M{"$sum": 1}}},
	}
	cursor, err := collection.Aggregate(ctx, pipeline)
	if err == nil {
		for cursor.Next(ctx) {
			var result struct {
				ID    string `bson:"_id"`
				Count int64  `bson:"count"`
			}
			if err := cursor.Decode(&result); err == nil {
				statusCount[result.ID] = result.Count
			}
		}
	}

	pipeline = []bson.M{
		{"$group": bson.M{"_id": "$nsapp", "count": bson.M{"$sum": 1}}},
	}
	cursor, err = collection.Aggregate(ctx, pipeline)
	if err == nil {
		for cursor.Next(ctx) {
			var result struct {
				ID    string `bson:"_id"`
				Count int64  `bson:"count"`
			}
			if err := cursor.Decode(&result); err == nil {
				nsappCount[result.ID] = result.Count
			}
		}
	}

	response := CountResponse{
		TotalEntries: totalCount,
		StatusCount:  statusCount,
		NSAPPCount:   nsappCount,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func GetByNsapp(w http.ResponseWriter, r *http.Request) {
	nsapp := r.URL.Query().Get("nsapp")
	var records []DataModel
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.M{"nsapp": nsapp})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var record DataModel
		if err := cursor.Decode(&record); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		records = append(records, record)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(records)
}

func GetByDateRange(w http.ResponseWriter, r *http.Request) {

	startDate := r.URL.Query().Get("start_date")
	endDate := r.URL.Query().Get("end_date")

	if startDate == "" || endDate == "" {
		http.Error(w, "Both start_date and end_date are required", http.StatusBadRequest)
		return
	}

	start, err := time.Parse("2006-01-02T15:04:05.999999+00:00", startDate+"T00:00:00+00:00")
	if err != nil {
		http.Error(w, "Invalid start_date format", http.StatusBadRequest)
		return
	}

	end, err := time.Parse("2006-01-02T15:04:05.999999+00:00", endDate+"T23:59:59+00:00")
	if err != nil {
		http.Error(w, "Invalid end_date format", http.StatusBadRequest)
		return
	}

	var records []DataModel
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.M{
		"created_at": bson.M{
			"$gte": start,
			"$lte": end,
		},
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var record DataModel
		if err := cursor.Decode(&record); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		records = append(records, record)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(records)
}
func GetByStatus(w http.ResponseWriter, r *http.Request) {
	status := r.URL.Query().Get("status")
	var records []DataModel
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.M{"status": status})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var record DataModel
		if err := cursor.Decode(&record); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		records = append(records, record)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(records)
}

func GetByOS(w http.ResponseWriter, r *http.Request) {
	osType := r.URL.Query().Get("os_type")
	osVersion := r.URL.Query().Get("os_version")
	var records []DataModel
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.M{"os_type": osType, "os_version": osVersion})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var record DataModel
		if err := cursor.Decode(&record); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		records = append(records, record)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(records)
}

func GetErrors(w http.ResponseWriter, r *http.Request) {
	errorCount := make(map[string]int)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.M{"error": bson.M{"$ne": ""}})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var record DataModel
		if err := cursor.Decode(&record); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if record.ERROR != "" {
			errorCount[record.ERROR]++
		}
	}

	type ErrorCountResponse struct {
		Error string `json:"error"`
		Count int    `json:"count"`
	}

	var errorCounts []ErrorCountResponse
	for err, count := range errorCount {
		errorCounts = append(errorCounts, ErrorCountResponse{
			Error: err,
			Count: count,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(struct {
		ErrorCounts []ErrorCountResponse `json:"error_counts"`
	}{
		ErrorCounts: errorCounts,
	})
}

func main() {
	ConnectDatabase()

	router := mux.NewRouter()
	router.HandleFunc("/upload", UploadJSON).Methods("POST")
	router.HandleFunc("/upload/updatestatus", UpdateStatus).Methods("POST")
	router.HandleFunc("/data/json", GetDataJSON).Methods("GET")
	router.HandleFunc("/data/paginated", GetPaginatedData).Methods("GET")
	router.HandleFunc("/data/summary", GetSummary).Methods("GET")
	router.HandleFunc("/data/nsapp", GetByNsapp).Methods("GET")
	router.HandleFunc("/data/date", GetByDateRange).Methods("GET")
	router.HandleFunc("/data/status", GetByStatus).Methods("GET")
	router.HandleFunc("/data/os", GetByOS).Methods("GET")
	router.HandleFunc("/data/errors", GetErrors).Methods("GET")

	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST"},
		AllowedHeaders:   []string{"Content-Type", "Authorization"},
		AllowCredentials: true,
	})

	handler := c.Handler(router)

	fmt.Println("Server running on port 8080")
	log.Fatal(http.ListenAndServe(":8080", handler))
}
