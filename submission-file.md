<!---

---
title: "CASA0017: Web Architecture Final Assessment"
author: "Steven Gray"
date: "10 Dec 2021"
---

-->

# Submission Guide

You will need to edit this file, create a PDF using the instructions below, from this file.   Sign it digitally and upload to Moodle

## How to create a PDF from Markdown
When finished you should export to PDF using VSCode and MarkdownPDF Extension. Make sure you select no headers and no footers in the
extension preferences before exporting to PDF.   

Upload this PDF into Moodle for submission including a copy of your presentation slides.

# Link to GitHub Repository

Flutter Application Name - **Runify** GitHub Repository - https://github.com/Qing137/casa0015-mobile-assessment.git

# Introduction to Application

**Runify** is a mobile application designed to help urban runners make smarter decisions about when, where, and how to run. The app was developed in Flutter and addresses a common but fragmented experience: runners often switch between three or four different apps to check air quality, weather, find suitable running locations, and track their activity. Runify brings these together into a single, focused tool.

The application provides three core capabilities. Before a run, it shows real-time air quality and weather data based on the user's location, suggests running advice tailored to current conditions, and helps users discover nearby parks and green spaces. During a run, it uses the phone's accelerometer to track steps, distance, pace, and duration in real time without relying on continuous GPS tracking. After a run, it saves a record of the activity, including the air quality at the time and an estimate of calories burned based on the user's weight.

To make the app practically useful, Runify integrates four external APIs: OpenWeatherMap for air quality and current weather, Open-Meteo for hourly forecasts, Google Places for nearby running spots, and Google Maps for map rendering. All user data — including run history and personal information such as weight — is stored locally using `shared_preferences`. No accounts, no cloud sync, and no data leaves the device unless required for an API call.

Overall, Runify combines environmental awareness, activity tracking, and personal logging into one connected mobile experience tailored to urban running.

# Bibliography

1. Flutter (n.d.) Flutter documentation. Available at: https://docs.flutter.dev/ (Accessed: 29 April 2026).

2. OpenWeatherMap (n.d.) Air Pollution API. Available at: https://openweathermap.org/api/air-pollution (Accessed: 29 April 2026).

3. OpenWeatherMap (n.d.) Current Weather Data API. Available at: https://openweathermap.org/current (Accessed: 29 April 2026).

4. OpenWeatherMap (n.d.) Geocoding API. Available at: https://openweathermap.org/api/geocoding-api (Accessed: 29 April 2026).

5. Open-Meteo (n.d.) Free Weather API documentation. Available at: https://open-meteo.com/en/docs (Accessed: 29 April 2026).

6. Google (n.d.) Google Maps Platform — Places API. Available at: https://developers.google.com/maps/documentation/places/web-service (Accessed: 29 April 2026).

7. Google (n.d.) Google Maps Platform — Maps SDK for Flutter. Available at: https://developers.google.com/maps/documentation/flutter-sdk (Accessed: 29 April 2026).

8. pub.dev (n.d.) geolocator | Flutter package. Available at: https://pub.dev/packages/geolocator (Accessed: 29 April 2026).

9. pub.dev (n.d.) http | Dart package. Available at: https://pub.dev/packages/http (Accessed: 29 April 2026).

10. pub.dev (n.d.) shared_preferences | Flutter package. Available at: https://pub.dev/packages/shared_preferences (Accessed: 29 April 2026).

11. pub.dev (n.d.) google_maps_flutter | Flutter package. Available at: https://pub.dev/packages/google_maps_flutter (Accessed: 29 April 2026).

12. pub.dev (n.d.) sensors_plus | Flutter package. Available at: https://pub.dev/packages/sensors_plus (Accessed: 29 April 2026).

# Declaration of Authorship

I, QING XIN, confirm that the work presented in this assessment is my own. Where information has been derived from other sources, I confirm that this has been indicated in the work.

Qing Xin

29/04/2026