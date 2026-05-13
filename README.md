# GreekHub

A full-stack iOS app for Greek chapter management built with SwiftUI and Firebase. Features real-time data, push notifications, QR check-in, officer dashboards, dues tracking, rush management, and a gamification system — across 4 development phases.

## Overview

GreekHub replaces fragmented group chats and spreadsheets with a native iOS platform built specifically for Greek chapter operations. Members get a social feed, events calendar, real-time chat, and engagement tracking. Officers get a full management suite with analytics, points control, rush pipeline, dues collection, and automated push notifications.

## Features by Phase

### Phase 1 — MVP
- Email/password auth with role-based access (Executive Chair, VP, Treasurer, Secretary, Member, Pledge)
- Chapter feed with posts, likes, comments, and officer badges
- Events calendar with RSVP and detail views
- Real-time chat with channel list and message bubbles
- Member roster with search and role filtering
- Profile with stats grid and leaderboard

### Phase 2 — Points, QR Check-In, Officer Dashboard
- QR code generation (CoreImage) and AVFoundation camera scanner for event check-in
- Points system with officer award/deduction tools and full points history
- Officer dashboard with analytics — attendance, engagement, chapter overview

### Phase 3 — Rush, Notifications, Media Wall
- Rush pipeline — PNM list, voting system, bid status tracking
- Push notifications via Firebase Cloud Messaging + APNs
- Media wall with photo grid, uploads to Firebase Storage, and detail view
- In-app notification center with permission banner

### Phase 4 — Dues, Alumni, Badges
- Dues dashboard with semester tracking, collection progress, and per-member payment recording
- Payment methods: Cash App, Zelle, Venmo, Cash (Stripe-ready)
- Alumni directory with mentor filter and LinkedIn/email deep links
- 10-badge gamification system with officer award tool and auto-award via Cloud Functions

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift |
| UI Framework | SwiftUI (iOS 16+) |
| Architecture | MVVM |
| Auth | Firebase Authentication |
| Database | Firebase Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging + APNs |
| Backend | Firebase Cloud Functions (Node.js 20) |
| QR Scanning | AVFoundation + CoreImage |

## Cloud Functions (8 total)

| Function | Trigger | Description |
|---|---|---|
| `onNewOfficerPost` | Firestore write | Notifies all members when an officer posts |
| `onCheckIn` | Firestore write | Sends +N pts push on event check-in |
| `onPointsAwarded` | Firestore write | Notifies member of manual point award |
| `eventReminders` | Scheduled (60 min) | Sends reminders for events starting in ~1 hour |
| `onNewMessage` | Firestore write | Badges members on new channel messages |
| `onBidOffered` | Firestore update | Notifies officers when bid status changes |
| `duesOverdueReminder` | Scheduled (daily 9am ET) | Marks overdue dues + sends reminders |
| `onPointsUpdated` | Firestore update | Auto-awards Century Club badge at 100+ points |

## Role System

| Role | Access |
|---|---|
| Executive Chair | All officer tools + Rush + Dues + Badges + Dashboard |
| VP / Treasurer / Secretary | Same as Executive Chair |
| Member | Feed, Events, Chat, Media, Roster, Profile, Badges |
| Pledge | Same as Member |

## Project Structure

```
GreekHub/
├── App/GreekHubApp.swift
├── Models/
│   ├── Models.swift
│   ├── Phase2Models.swift
│   ├── Phase3Models.swift
│   ├── Phase4Models.swift
│   └── CheckInModels.swift
├── Services/
│   ├── AuthService.swift
│   ├── FirestoreService.swift
│   ├── FirestoreExtensions.swift
│   ├── FirestorePhase2.swift
│   ├── FirestorePhase3.swift
│   └── FirestorePhase4.swift
├── ViewModels/
│   ├── ViewModels.swift
│   ├── Phase2ViewModels.swift
│   ├── Phase3ViewModels.swift
│   └── Phase4ViewModels.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Auth/LoginView.swift
│   ├── Feed/FeedView.swift
│   ├── Events/EventsView.swift
│   ├── Chat/ChatView.swift
│   ├── Roster/RosterView.swift
│   ├── Profile/ProfileView.swift
│   ├── Officer/OfficerDashboardView.swift
│   ├── Officer/OfficerPointsView.swift
│   ├── CheckIn/QRCheckInView.swift
│   ├── Rush/RushView.swift
│   ├── Media/MediaWallView.swift
│   ├── Notifications/NotificationsView.swift
│   ├── Dues/DuesView.swift
│   ├── Alumni/AlumniView.swift
│   └── Badges/BadgesView.swift
└── Resources/Theme.swift
```

## Setup

See [SETUP.md](SETUP.md) for the full setup guide including Firebase configuration, APNs setup, Cloud Functions deployment, Firestore security rules, and indexes.

**Quick start checklist:**
1. Create Xcode project (iOS App, SwiftUI, iOS 16, Bundle ID: `com.greekhub.app`)
2. Delete `ContentView.swift`, drag in source files
3. Add Firebase SDK via SPM — Auth, Firestore, Storage, Messaging
4. Add Push Notifications + Background Modes capabilities
5. Create Firebase project, download `GoogleService-Info.plist`
6. Enable Email/Password Auth and Firestore (production mode, us-east1)
7. Deploy `firestore.rules`, `storage.rules`, and Cloud Functions
8. Upload APNs `.p8` key to Firebase Cloud Messaging settings
9. Build and run — set first account's role to `Executive Chair` in Firestore

## Author

Farrakhan Muhammad — [github.com/Farrakhanbm](https://github.com/Farrakhanbm)
