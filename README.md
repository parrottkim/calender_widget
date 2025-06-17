# Flutter Custom Calendar Widget
## 🗓️ Introduction

This repository offers a flexible and user-friendly custom calendar widget for Flutter applications. It supports single date selection and date range selection, and includes advanced navigation features to switch between day, month, and year views.

## ✨ Key Features
* **Two Selection Modes**:
    * **Single Date Selection (`Calendar.day`)**: Allows selecting a single, specific date.
    * **Date Range Selection (`Calendar.range`)**: Allows selecting a date range by specifying a start and end date.
* **Three View Modes**:
    * **Day View**: Displays a grid of dates for a specific month, similar to a typical calendar.
    * **Month View**: Shows all 12 months of a specific year at a glance, enabling quick navigation by month.
    * **Year View**: Displays years in 10-year increments, making it easy to navigate to dates far in the past or future.
* **Intuitive Navigation**:
    * **View Mode Switching**: Tap the header (e.g., "June 2024") to switch between the current view modes (Day ➡️ Month ➡️ Year).
    * **Page Navigation**: Use the left/right arrow buttons to move to the previous/next month, year, or 10-year period, depending on the current view mode.
    * **Swipe Navigation**: Swipe left or right within each view to navigate between pages.
* **Visual Feedback**:
    * **Highlight Today's Date/Month/Year**: The current date, current month, and current year are visually highlighted for easy identification.
    * **Date Range Visualization**: When a date range is selected, the start date, end date, and all dates in between are clearly marked.
* **Callback Support**: Provides callback functions to execute external logic when a date or date range is selected.