# Privacy Policy

Effective Date: May 14, 2026

## Introduction

This Privacy Policy explains how EyeHeaven handles information.
EyeHeaven is designed to run locally on your Mac and to minimize data collection.

## Data We Collect

EyeHeaven does not collect personal data such as name, email, contacts, photos, location, or message content.

If anonymous telemetry is enabled, EyeHeaven sends one lightweight daily heartbeat event through the open-source Heartbeat tracker.
The telemetry is used only to estimate active installs.

Telemetry includes:
- A non-reversible hashed device identifier (as implemented by the Heartbeat dependency)
- App identifier and app version
- A daily ping event timestamp

## Data We Do Not Collect

EyeHeaven does not collect:
- Name, email address, phone number, or contacts
- Photos, files, clipboard, or browsing history
- Keystrokes or user content
- Precise location data
- Advertising identifiers

EyeHeaven does not run third-party ad SDKs.

## App Permissions

EyeHeaven may use standard macOS capabilities required for app behavior:
- Network access: used for stereogram catalog and image downloads, and optional heartbeat telemetry
- Local storage: used to cache stereograms and save app settings

EyeHeaven does not request microphone, camera, or screen recording permissions for its current feature set.

## Data Storage and Retention

EyeHeaven stores data locally on your device, including:
- App settings in UserDefaults
- Stereogram cache in Application Support
- Stereogram usage metadata in local SwiftData storage

You can remove app data by uninstalling the app and deleting its local data.

## Third-Party Services

EyeHeaven uses:
- GitHub Releases for downloading stereogram catalog and image files
- Heartbeat tracker for optional anonymous daily telemetry

These services may process request metadata according to their own policies.

## Analytics and User Control

Anonymous heartbeat telemetry is enabled by default and can be disabled in app settings:
- Settings -> System -> Anonymous usage stats

When disabled, no new heartbeat events are sent after app restart.

## Children’s Privacy

EyeHeaven is not directed to children under 13 and does not knowingly collect personal data from children.

## International Users

Because EyeHeaven primarily processes data locally, international data transfer is limited to standard HTTPS requests needed for optional downloads and telemetry.

## Policy Changes

We may update this Privacy Policy from time to time.
The latest version will always be published in this repository.

## Contact

If you have questions about this Privacy Policy, contact:
- ninilich@tuta.io
