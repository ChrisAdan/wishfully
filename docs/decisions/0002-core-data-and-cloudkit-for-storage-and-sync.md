# 0002. Core Data and CloudKit for storage and sync

- **Date:** 2026-11-06
- **Status:** Superseded by 0017

## Maintainer input

> **Maintainer:** Give me a dossier of the proposed plan, including system architecture like what db we want to use or how the back end works

> **Maintainer:** If we can resolve my cybersecurity concerns then the rest of the plan is accepted and we can proceed once I do the tasks on my end

## Context

Two phones share one list. Candidates were SwiftData, Core Data with CloudKit, and a hosted backend (Firebase, Supabase or a custom server).

## Decision

Core Data on the device, synced and shared through `NSPersistentCloudKitContainer` with a private and a shared store. Apple's iCloud is the backend.

## Consequences

The project runs zero servers and holds zero user data. SwiftData stays out until it supports sharing between iCloud users. A hosted backend remains available later behind the `WishRepository` protocol.
