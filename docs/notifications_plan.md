# Notifications Plan

## Notification Types

1. Host Notifications
   - Trigger: A user successfully joins a game.
   - Recipient: Game host (game.hostId).
   - Purpose: Let host know participation is increasing.

2. Waitlist Spot Opened
   - Trigger: A participant leaves or host reduces capacity, and someone on waitlist can be promoted.
   - Recipient: First user in waitlist.
   - Purpose: Give them a chance to join before others.

3. Game Cancellation
   - Trigger: Host cancels a game.
   - Recipients: All current participants + waitlist users + host (confirmation).
   - Purpose: Inform everyone not to show up.

4. Game Rescheduled
   - Trigger: Host updates game date/time.
   - Recipients: All current participants + waitlist users.
   - Purpose: Prevent confusion on start time.

5. Game Start Reminder
   - Trigger: 1 hour before game start time (local notification on device).
   - Recipient: Each participant (on their own device).
   - Purpose: Help attendance.

6. Chat Message Alerts (optional)
   - Trigger: New message in game chat.
   - Recipients: All participants except sender.
   - Purpose: Keep users engaged with conversation.

## Data Needed per Notification

Each notification document should store:

- `id`: Document ID
- `type`: Enum/string ("host_join", "waitlist_spot", "cancelled", "rescheduled", "start_reminder", "chat_message")
- `title`: Short title to display in UI
- `body`: Description / message text
- `userId`: The user this notification belongs to
- `gameId`: Related game (if applicable)
- `createdAt`: Timestamp
- `read`: Boolean indicating if the user has opened/read it
- `triggeredByUserId`: (Optional) Who caused the event (e.g. the user who joined or sent a message)

## Firestore Structure (Proposal)

Collection layout:

- `users/{userId}/notifications/{notificationId}`

Advantages:
- Easy to query only the current user's notifications
- Security rules can enforce `request.auth.uid == userId`
- Keeps notifications scoped per user

## Integration Notes

- Wait for Ahmed & Sharier to finalize:
  - Game model fields (hostId, time, capacity, etc.)
  - Waitlist model & auto-promotion
  - Chat message structures

- Once those are stable:
  - Trigger notifications via Cloud Functions or app logic
  - Add links in notifications UI to navigate to Game Details or Chat
