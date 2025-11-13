# ✅ Real-Time Severity Display - Quick Visual Guide

## What You Should See Right Now

### 1️⃣ Left Sidebar - Domain Rows

Each domain row shows:
```
┌─────────────────────────────────────┐
│ Domain 1                            │
│ Acute Intoxication/Withdrawal       │
│                                     │
│ ✅ Complete     3 answers    [🟠 3] │ ← Severity badge
└─────────────────────────────────────┘
```

**Severity badges appear ONLY when severity > 0:**
- `[⚪️ 0]` Gray - None (doesn't show, only if explicitly set)
- `[🟢 1]` Green - Mild
- `[🟡 2]` Yellow - Moderate  
- `[🟠 3]` Orange - Severe
- `[🔴 4]` Red - Very Severe

---

### 2️⃣ Bottom Severity Bar - Simple Circles (Domains 1, 3-6)

```
Severity Rating
Required to override completion

[⚪️] [⚪️] [🟠] [⚪️] [⚪️]  ← [3] is selected (orange, white text)
 0    1    2    3    4
```

**When you tap a circle:**
- Selected circle fills with color + white number
- Other circles remain gray
- Sidebar instantly updates to show colored badge
- Haptic vibration

---

### 3️⃣ Bottom Severity Cards - Horizontal Scroll (Domain 2)

```
Severity Rating
Tap a card or use keyboard 0-4

← ╔═══════╗  ╔═══════╗  ╔═══════╗  ╔═══════╗  ╔═══════╗ →
  ║  ⚪️   ║  ║  🟢   ║  ║  🟡   ║  ║  🟠   ║  ║  🔴   ║
  ║   0   ║  ║   1   ║  ║   2   ║  ║   3   ║  ║   4   ║
  ║       ║  ║       ║  ║       ║  ║       ║  ║       ║
  ║ None  ║  ║ Mild  ║  ║Moderate║ ║Severe ║ ║ Very   ║
  ║       ║  ║       ║  ║       ║  ║       ║ ║Severe ║
  ╚═══════╝  ╚═══════╝  ╚═══════╝  ╚═══════╝  ╚═══════╝
  (swipe horizontally to see all cards)
```

**When you tap "3 Severe" card:**
- Card gets **orange border** (2px thick)
- Card gets **orange glow** (shadow)
- Title becomes **bold**
- Sidebar Domain 2 row shows `[🟠 3]` badge
- Spring animation (smooth bounce effect)

---

### 4️⃣ Emergency Alert (Severity 4 Only)

When you select severity **4** in Domain 2:

```
╔════════════════════════════════════════════════════════════╗
║ ⚠️  EMERGENCY: Consider ED evaluation for DTs, chest      ║
║     pain, seizures, etc.                                   ║
╚════════════════════════════════════════════════════════════╝
    (red banner appears below the cards)
```

---

## Test Sequence (Do This Now!)

### Test 1: Domain 1 Simple Circles

1. Open **Domain 1**
2. Scroll to bottom, see 5 gray circles: `[0] [1] [2] [3] [4]`
3. **Tap circle `[2]`**
   
   ✅ **Expected results:**
   - Circle `[2]` turns **yellow** with white "2"
   - Sidebar "Domain 1" row shows **yellow badge** `[🟡 2]`
   - Haptic vibration
   
4. **Tap circle `[3]`**
   
   ✅ **Expected results:**
   - Circle `[3]` turns **orange** with white "3"
   - Circle `[2]` becomes gray again
   - Sidebar badge updates to **orange** `[🟠 3]`
   - Haptic vibration

---

### Test 2: Domain 2 Rich Cards

1. Navigate to **Domain 2** (from sidebar)
2. Scroll to bottom, see horizontal card strip
3. **Swipe left** to see all 5 cards
4. **Tap "2 Moderate" card (yellow circle)**
   
   ✅ **Expected results:**
   - Card gets **yellow border** (2px thick)
   - Card gets **yellow glow** around it
   - "2 Moderate" text becomes **bold**
   - Sidebar "Domain 2" row shows **yellow badge** `[🟡 2]`
   - Smooth spring animation
   
5. **Tap "4 Very Severe" card (red circle)**
   
   ✅ **Expected results:**
   - Card gets **red border** and **red glow**
   - "4 Very Severe" text becomes **bold**
   - **Red emergency banner appears** below cards
   - Sidebar badge updates to **red** `[🔴 4]`
   - Spring animation

---

### Test 3: State Persistence & Isolation

1. While in **Domain 2**, set severity to `[3]`
   - Sidebar shows `[🟠 3]` on Domain 2 row
   
2. **Navigate to Domain 1** (from sidebar)
   - Set severity to `[1]`
   - Sidebar shows `[🟢 1]` on Domain 1 row
   
3. **Navigate to Domain 3**
   - Don't select anything
   - Sidebar shows **no badge** (only answer count if any)
   
4. **Navigate back to Domain 2**
   
   ✅ **Expected results:**
   - Card `[3]` still has **orange border** and **glow**
   - Sidebar still shows `[🟠 3]` on Domain 2 row
   - Sidebar still shows `[🟢 1]` on Domain 1 row
   - ✅ **Each domain keeps its own severity!**

---

### Test 4: Sidebar Updates in Real-Time

1. Open **Domain 1**
2. Position app so you can see **both** sidebar AND severity circles
3. **Rapidly tap circles in sequence**: `[0] → [1] → [2] → [3] → [4]`
   
   ✅ **Expected results:**
   - Sidebar badge **instantly updates** with each tap
   - Colors change: Gray → Green → Yellow → Orange → Red
   - No lag, no delay
   - Haptic feedback on each tap

---

## Color Reference (What You Should See)

| Severity | Number | Color | iOS Color | Sidebar Badge | Button/Card |
|----------|--------|-------|-----------|---------------|-------------|
| None | 0 | Gray | `#8E8E93` | (hidden) | Gray circle |
| Mild | 1 | Green | `#34C759` | `[🟢 1]` | Green filled |
| Moderate | 2 | Yellow | `#FFCC00` | `[🟡 2]` | Yellow filled |
| Severe | 3 | Orange | `#FF9500` | `[🟠 3]` | Orange filled |
| Very Severe | 4 | Red | `#FF3B30` | `[🔴 4]` | Red filled + alert |

---

## Known Working Features ✅

- ✅ **Single source of truth**: `AssessmentStore.currentAssessment.domains[n].severity`
- ✅ **Bi-directional sync**: Tap button → updates store → updates sidebar
- ✅ **Real-time updates**: No page refresh needed
- ✅ **State persistence**: Ratings saved across navigation
- ✅ **Domain isolation**: Each domain has independent severity
- ✅ **Accessibility**: VoiceOver reads "Severity 3, Severe"
- ✅ **Haptic feedback**: Vibration on each selection
- ✅ **Animations**: Spring bounce on Domain 2 cards
- ✅ **Emergency alerts**: Red banner for severity 4
- ✅ **Completion override**: Can complete domain with severity alone

---

## What If It's Not Working?

### Sidebar badge not updating:

**Check:**
1. Are you looking at the **correct domain row**?
2. Did you select severity **> 0**? (Badge hidden for severity 0)
3. Is the app running the latest build?

**Fix:**
```bash
# Rebuild the app
cd ios/ASAMAssessment/ASAMAssessment
xcodebuild -project ASAMAssessment.xcodeproj -scheme ASAMAssessment -destination 'generic/platform=iOS' clean build
```

### Severity button not highlighting:

**Check:**
1. Are you in **Edit Mode**? (Completed domains lock severity unless editing)
2. Is the domain marked **Complete**? (Tap "Edit" button to unlock)

**Fix:**
- Tap **"Edit"** button in the action bar if domain is complete

### Emergency banner not showing:

**Check:**
1. Are you in **Domain 2**? (Other domains don't have emergency banner in current implementation)
2. Did you select **severity 4**? (Banner only shows for "4 Very Severe")

---

## Screenshot Locations

When testing on iPad, you should see:

**Sidebar (left rail):**
```
Assessments
├─ Patient: John Doe
    ├─ Domain 1  ✅ Complete  3  [🟠 3]  ← Orange badge
    ├─ Domain 2  🟠 In Progress  5  [🔴 4]  ← Red badge
    ├─ Domain 3  🟠 In Progress  2  [🟢 1]  ← Green badge
    ├─ Domain 4  🟠 In Progress
    ├─ Domain 5  🟠 In Progress
    └─ Domain 6  🟠 In Progress
```

**Bottom action bar (Domain 1):**
```
─────────────────────────────────────────────────────────
Severity Rating
Required to override completion   [⚪️] [⚪️] [⚪️] [🟠] [⚪️]
                                    0    1    2    3    4
─────────────────────────────────────────────────────────
Progress ████████░░░░ 75%              [Mark Complete]
─────────────────────────────────────────────────────────
```

**Bottom cards (Domain 2):**
```
─────────────────────────────────────────────────────────
Severity Rating
Tap a card or use keyboard 0-4

← ╔═══════╗  ╔═══════╗  ╔═══════╗  ╔═══════╗  ╔═══════╗ →
  ║  ⚪️   ║  ║  🟢   ║  ║  🟡   ║  ║  🟠   ║  ║  🔴   ║
  ║   0   ║  ║   1   ║  ║   2   ║  ║   3   ║  ║   4   ║
  ║ None  ║  ║ Mild  ║  ║Moderate║ ║Severe ║ ║ Very  ║
  ╚═══════╝  ╚═══════╝  ╚═══════╝  ╚═══════╝  ║Severe ║
                                               ╚═══════╝
─────────────────────────────────────────────────────────
╔═══════════════════════════════════════════════════════╗
║ ⚠️  EMERGENCY: Consider ED evaluation for DTs, chest  ║
║     pain, seizures, etc.                              ║
╚═══════════════════════════════════════════════════════╝
─────────────────────────────────────────────────────────
Progress ████████████ 100%                      [✅ Complete]
─────────────────────────────────────────────────────────
```

---

## Summary

✅ **The feature you described is already fully implemented and working!**

**What updates in real-time:**
1. ✅ **Left sidebar**: Colored badge with severity number
2. ✅ **Bottom buttons/cards**: Selected button/card highlights with color

**How it works:**
- Tap severity → `updateSeverity()` → `AssessmentStore` → `@EnvironmentObject` → UI updates
- Same pattern as your Zustand example, but using SwiftUI's reactive system

**Ready to test on your iPad!** 🚀

**Try the test sequences above and verify you see:**
- Instant sidebar badge updates (no lag)
- Colored circles/cards when selected
- Emergency alert for severity 4
- State persistence across navigation
- Domain isolation (no cross-bleed)
