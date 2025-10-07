# Firebase Debug Logging Guide

This document describes all the debug logging added to Firebase operations throughout the app.

## 🔍 Debug Console Output

All Firebase operations now print detailed debug information to the console. The logs follow this format:

- `DEBUG:` - Informational messages about operations in progress
- `ERROR:` - Error messages when operations fail
- `WARNING:` - Warning messages for validation issues
- `STACK TRACE:` - Full stack traces for errors

---

## 📔 Journal Service Logging

### Journal Entry Operations

**getAllEntries()**
- ✅ Logs user ID check
- ✅ Logs fetching operation
- ✅ Logs number of entries retrieved
- ✅ Logs errors with stack trace

**getEntriesByType()**
- ✅ Logs entry type being fetched
- ✅ Logs count of entries retrieved
- ✅ Logs errors with stack trace

**getPassiveEntries() & getActiveEntries()**
- ✅ Logs fetching operation
- ✅ Logs count of entries retrieved
- ✅ Logs errors with stack trace

**createEntry()**
- ✅ Logs entry title being created
- ✅ Logs successful creation with document ID
- ✅ Logs errors and rethrows

**updateEntry()**
- ✅ Logs entry ID being updated
- ✅ Logs successful update
- ✅ Logs errors and rethrows

**deleteEntry()**
- ✅ Logs entry ID being deleted
- ✅ Logs successful deletion
- ✅ Logs errors and rethrows

### Mood Tracking Operations

**updateCurrentMood()**
- ✅ Logs mood and intensity being saved
- ✅ Logs successful mood update
- ✅ Logs errors with stack trace

**getCurrentMood()**
- ✅ Logs user ID check
- ✅ Logs current mood value
- ✅ Logs errors with stack trace

**getMoodHistory()**
- ✅ Logs number of days being fetched
- ✅ Logs count of mood entries retrieved
- ✅ Logs errors with stack trace

### Insights Operations

**generateWeeklyInsight()**
- ✅ Logs insight generation start
- ✅ Logs successful generation
- ✅ Logs mood percentages calculated
- ✅ Logs errors with fallback data

### Settings Operations

**getSettings()**
- ✅ Logs settings fetch
- ✅ Logs if settings exist or using defaults
- ✅ Logs errors with stack trace

**updateSettings()**
- ✅ Logs settings update operation
- ✅ Logs successful update
- ✅ Logs errors and rethrows

---

## 🩸 Period Tracking Service Logging

### Period Log Operations

**savePeriodLog()**
- ✅ Logs period start/end dates
- ✅ Logs successful save with document ID
- ✅ Logs errors and rethrows

**getAllPeriodLogs()**
- ✅ Logs user ID check
- ✅ Logs count of period logs retrieved
- ✅ Logs errors with stack trace

**getPeriodLogsInRange()**
- ✅ Logs date range being queried
- ✅ Logs count of logs in range
- ✅ Logs errors with stack trace

### Cycle Calculations

**getAverageCycleLength()**
- ✅ Logs calculation start
- ✅ Logs if using default or calculated value
- ✅ Logs final average cycle length
- ✅ Logs errors with stack trace

**getAveragePeriodDuration()**
- ✅ Logs calculation start
- ✅ Logs if using default or calculated value
- ✅ Logs final average duration
- ✅ Logs errors with stack trace

**predictNextPeriod()**
- ✅ Logs prediction start
- ✅ Logs average values being used
- ✅ Logs predicted start date and confidence
- ✅ Logs errors with fallback prediction

**getCurrentCyclePhase()**
- ✅ Logs phase determination
- ✅ Logs current cycle phase
- ✅ Logs errors with unknown phase

**getCalendarDays()**
- ✅ Logs month being loaded
- ✅ Logs counts for each category (period, predicted, ovulation, PMS)
- ✅ Logs errors with empty data

---

## 🔐 Authentication Logging

### Auth Provider Operations

**signInWithEmail()**
- ✅ Logs sign-in attempt with email
- ✅ Logs successful sign-in
- ✅ Logs Firebase auth errors with error code
- ✅ Logs stack traces

**registerWithEmail()**
- ✅ Logs registration attempt with email
- ✅ Logs successful registration
- ✅ Logs Firebase auth errors with error code
- ✅ Logs stack traces

**signOut()**
- ✅ Logs sign-out operation
- ✅ Logs successful sign-out
- ✅ Logs any errors

**_onAuthStateChanged()**
- ✅ Logs user authentication with UID
- ✅ Logs user sign-out

---

## 💬 Chat Provider Logging

### Gemini API Operations

**chatWithGemini()**
- ✅ Logs message being sent to Gemini
- ✅ Logs API request initiation
- ✅ Logs successful response received
- ✅ Logs message added to chat history
- ✅ Logs API error status codes
- ✅ Logs response body on error
- ✅ Logs errors with stack trace

---

## 🎨 Page-Level Logging

### Journaling Page

**_loadData()**
- ✅ Logs data loading start
- ✅ Logs successful load of all data
- ✅ Logs errors with stack trace

**_updateMood()**
- ✅ Logs mood update with value
- ✅ Logs UI update
- ✅ Logs errors with stack trace

**_toggleSetting()**
- ✅ Logs setting toggle with key and value
- ✅ Logs successful update
- ✅ Logs errors with stack trace

**_saveEntry()**
- ✅ Logs entry save with title
- ✅ Logs data reload
- ✅ Logs errors with stack trace

**_deleteEntry()**
- ✅ Logs entry deletion with ID
- ✅ Logs data reload
- ✅ Logs errors with stack trace

### Calendar View

**_loadCalendarData()**
- ✅ Logs calendar month being loaded
- ✅ Logs successful data load
- ✅ Logs errors with stack trace

### Cycle Log Form

**_savePeriodLog()**
- ✅ Logs validation warnings
- ✅ Logs period log creation
- ✅ Logs successful save to Firestore
- ✅ Logs form reset
- ✅ Logs errors with stack trace

---

## 📊 Example Console Output

```
DEBUG: AuthProvider - User authenticated: abc123xyz
DEBUG: JournalingPage - Loading all journal data
DEBUG: Fetching all journal entries for user: abc123xyz
DEBUG: Retrieved 5 journal entries
DEBUG: Fetching passive journal entries
DEBUG: Retrieved 2 passive entries
DEBUG: Fetching active journal entries
DEBUG: Retrieved 3 active entries
DEBUG: Fetching journaling settings
DEBUG: Settings loaded successfully
DEBUG: Generating weekly insight
DEBUG: Weekly insight generated successfully
DEBUG: Fetching current mood for user: abc123xyz
DEBUG: Current mood: Happy
DEBUG: JournalingPage - All data loaded successfully
```

### Error Example

```
ERROR: createEntry failed - [cloud_firestore/permission-denied] Missing or insufficient permissions
STACK TRACE: #0      JournalingService.createEntry (package:chatbot_app_1/pages/journaling/journaling_page.dart:296)
#1      _JournalingPageState._saveEntry (package:chatbot_app_1/pages/journaling/journaling_page.dart:822)
```

---

## 🛠️ How to Use Debug Logs

1. **Run the app in debug mode**
2. **Open the debug console** in your IDE (VS Code, Android Studio, etc.)
3. **Filter by keywords**:
   - Search for `ERROR:` to find failures
   - Search for `DEBUG:` to trace operations
   - Search for specific operations like `savePeriodLog`, `createEntry`, etc.

4. **Common scenarios**:
   - User not logged in: Search for "User ID is empty"
   - Permission errors: Search for "permission-denied"
   - Network errors: Search for "STACK TRACE"

---

## ✅ All Firebase Operations Covered

- [x] Journal entry CRUD (Create, Read, Update, Delete)
- [x] Mood tracking and history
- [x] Weekly insights generation
- [x] Journaling settings
- [x] Period log saving
- [x] Period log retrieval
- [x] Cycle predictions
- [x] Calendar data generation
- [x] User authentication (sign in, register, sign out)
- [x] Chat with Gemini API

Every Firebase operation now includes comprehensive debug logging for easy troubleshooting!

