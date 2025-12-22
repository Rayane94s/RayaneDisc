# Rayane Tracker

A personal discipline and habit tracking web application designed to help me stay consistent with my daily goals.

![Dashboard Screenshot](path/to/screenshot.png) <!-- TODO: Add screenshot -->

## Overview

Rayane Tracker is a single-page application that visualizes my daily activities and calculates a discipline score based on my performance. It uses a grid system to log activities hour-by-hour and includes gamification elements like multipliers and momentum to encourage consistency.

## Features

### 📅 Daily Tracking
- **Interactive Grid:** Each day is divided into hourly slots starting from 5:00 AM.
- **Activity Types:** Pre-defined activities include:
  - Sleep, Code, Work, Read, Workout, Stretch, Looksmax, Pray, Netflix.
- **Status Logging:** Click slots to cycle through statuses:
  - **Neutral:** Activity logged.
  - **Done (Green):** Successfully completed.
  - **Failed (Red):** Missed or failed.
- **Time Indicator:** A live indicator shows the current time on the grid for the current day.

### 💯 Scoring & Multipliers
The application calculates a daily completion percentage based on "Done" tasks vs. total hours. This score is boosted by several multipliers:

1.  **Momentum (1.5x 🔥):**
    - Activates if the average score of the last 7 days is greater than 50%.
    - Encourages maintaining a streak of good days.
2.  **Apple Watch (1.2x):**
    - Checkbox to indicate if Apple Watch rings were closed.
3.  **Weight Target (1.3x):**
    - Checkbox to indicate if the daily weight target was met.

### 📊 Progress Visualization
- **Moving Average Graph:** A chart displaying the moving average of discipline scores since December 21, 2025.
- **Color Coded Scores:**
  - **Green:** ≥ 80%
  - **White:** ≥ 50%
  - **Red:** < 50%

### 💾 Data Persistence
- All data is stored locally in the browser's `localStorage`. No server or account is required.

## Usage

### Running Locally
1.  Simply open the `index.html` file in any modern web browser (Chrome, Safari, Firefox).
2.  The app will load with today's date.
3.  Start clicking on time slots to log your day.

### Hosting (Optional)
To access the tracker from multiple devices (like a phone), it can be hosted on GitHub Pages:
1.  Push this repository to GitHub.
2.  Go to **Settings** > **Pages**.
3.  Select the `main` branch and `/` root folder.
4.  Save and access the site via the provided URL.
    - *Note: Since data is stored in LocalStorage, data will not sync between devices automatically unless you use a syncing solution or stick to one device.*

## Future Plans
- [ ] Add data export/import functionality.
- [ ] Customizable activity lists via UI.
- [ ] Dark/Light mode toggle (currently Dark mode only).

## Credits
Built by Rayane for personal use.

## License
MIT License. Free to use and modify.
