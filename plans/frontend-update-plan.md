# Frontend Update Plan: Syncing with Community-Scripts

## Overview

This plan outlines the updates needed to sync the Heretek-AI frontend with the community-scripts/ProxmoxVE frontend while preserving Heretek's unique styling and branding.

## Current State Analysis

### Heretek Customizations to Preserve

1. **Theme & Colors (globals.css)**
   - Rust/Corruption themed color palette
   - Custom CSS effects: noise-overlay, rust-border, corruption-glow, brass-text, copper-accent, glitch, scan-lines, flicker, corrupted-pulse, metal-surface, heresy-warning
   - Custom scrollbar styling with gradients
   - Glass effect with corruption theme

2. **Fonts (layout.tsx)**
   - Cinzel font for headings (gothic/medieval feel)
   - JetBrains Mono for body (industrial/tech feel)

3. **Branding (site-config.tsx)**
   - GitHub links point to Heretek-AI organization
   - Custom analytics endpoint
   - Custom AlertColors for Heretek theme

4. **Content Customizations**
   - Page title: "Heretek AI" instead of "Proxmox VE Helper-Scripts"
   - Custom hero text: "Heretek-AI" and "Uncompliant scripts, made quicker"
   - Custom metadata and SEO

### Files Already Up to Date

| File | Status | Notes |
|------|--------|-------|
| `not-found.tsx` | ✅ Identical | No changes needed |
| `faq-config.tsx` | ✅ Identical | No changes needed |
| `manifest.ts` | ✅ Customized | Already has Heretek branding |

### Files Needing Updates

| File | Priority | Changes |
|------|----------|---------|
| `layout.tsx` | High | Add CopycatWarningToast component |
| `copycat-warning-toast.tsx` | High | New file to create |

## Detailed Changes

### 1. Create `copycat-warning-toast.tsx`

**Location:** `frontend/src/components/copycat-warning-toast.tsx`

This is a new component that displays a warning toast about copycat sites. The component should be created with Heretek-appropriate messaging.

```tsx
"use client";

import { useEffect } from "react";
import { toast } from "sonner";

const STORAGE_KEY = "copycat-warning-dismissed";

export function CopycatWarningToast() {
  useEffect(() => {
    if (typeof window === "undefined")
      return;
    if (localStorage.getItem(STORAGE_KEY) === "true")
      return;

    toast.warning("Beware of copycat sites. Always verify the URL is correct before trusting or running scripts.", {
      position: "top-center",
      duration: Number.POSITIVE_INFINITY,
      closeButton: true,
      onDismiss: () => localStorage.setItem(STORAGE_KEY, "true"),
    });
  }, []);

  return null;
}
```

### 2. Update `layout.tsx`

**Changes needed:**
- Import `CopycatWarningToast` component
- Add `<CopycatWarningToast />` inside the layout

**Current imports to add:**
```tsx
import { CopycatWarningToast } from "@/components/copycat-warning-toast";
```

**Location in JSX:**
```tsx
<Toaster richColors />
<CopycatWarningToast />
```

### 3. Files to Review (No Changes Expected)

These files should be reviewed but likely don't need changes:

- `components/navbar.tsx` - Already has Heretek branding
- `components/footer.tsx` - Already has Heretek branding
- `config/site-config.tsx` - Already has Heretek URLs
- `styles/globals.css` - Preserve Heretek custom theme

### 4. Scripts Page Components to Check

The following components should be checked for any functional updates:

- `app/scripts/page.tsx`
- `app/scripts/_components/script-item.tsx`
- `app/scripts/_components/script-accordion.tsx`
- `app/scripts/_components/script-info-blocks.tsx`
- `app/scripts/_components/sidebar.tsx`
- `app/scripts/_components/resource-display.tsx`
- `app/scripts/_components/version-badge.tsx`

### 5. UI Components to Check

Check for any new UI components or updates:

- `components/ui/` directory
- `components/animate-ui/` directory
- `components/navigation/` directory

## Implementation Order

1. **Phase 1: Core Components**
   - [ ] Create `copycat-warning-toast.tsx`
   - [ ] Update `layout.tsx` to include the toast

2. **Phase 2: Review Scripts Components**
   - [ ] Compare and update script-related components if needed
   - [ ] Ensure Heretek branding is maintained in titles

3. **Phase 3: Review UI Components**
   - [ ] Check for new UI components
   - [ ] Update existing components if there are bug fixes

4. **Phase 4: Testing**
   - [ ] Build the frontend
   - [ ] Test all pages
   - [ ] Verify Heretek styling is preserved
   - [ ] Verify toast warning appears correctly

## Files to NOT Change

The following files contain Heretek-specific customizations and should NOT be updated from community-scripts:

- `styles/globals.css` - Custom Heretek theme
- `config/site-config.tsx` - Heretek URLs and branding
- `app/page.tsx` - Heretek hero content
- `app/manifest.ts` - Heretek app info
- `components/navbar.tsx` - Heretek logo and branding
- `components/footer.tsx` - Heretek links

## Summary

The main update required is adding the `CopycatWarningToast` component and integrating it into the layout. Most other files are either already up to date or contain Heretek-specific customizations that should be preserved.

The Heretek frontend has a unique "corrupted forge" / Warhammer 40K-inspired aesthetic with:
- Rust and corruption color palette
- Custom CSS animations (glitch, flicker, corrupted-pulse)
- Cinzel and JetBrains Mono fonts
- Custom scrollbar with gradient effects

These customizations must be preserved while bringing in any functional updates from the community-scripts repository.
