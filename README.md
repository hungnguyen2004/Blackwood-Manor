# Blackwood-Manor
My personal Boardgame 

## Firebase Realtime Database foundation

Online play is optional. Local play remains unchanged when no room is created
or joined.

1. Create a Firebase project and enable **Realtime Database**.
2. Copy `firebase-config.example.js` to `firebase-config.js`, then add the
   Firebase Web App configuration. The real configuration file is ignored by git.
3. Serve the project over HTTP(S) and use **Tạo phòng** / **Tham gia** on the
   setup screen. The host shares the six-character room code. Identity and
   the last room are retained in browser storage for reconnecting.

Room data is stored only under `blackwoodManor/v1_23/rooms/{roomCode}`. The
client creates a new code and never deletes or writes to pre-existing paths.
The host is the only client that publishes authoritative game snapshots;
other clients receive snapshots and can currently submit only lobby intents.
Read [MULTIPLAYER-v1.23.md](MULTIPLAYER-v1.23.md) before deploying. For
production, require Firebase Authentication and restrict Realtime Database
rules to authenticated room members before exposing the database.
