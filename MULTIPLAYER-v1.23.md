# Multiplayer Foundation v1.23

## Scope

v1.23 establishes Firebase Realtime Database rooms, an anonymous persistent
player identity, lobby membership, host ownership, public game snapshots,
reconnection, and a minimal action queue. It does not turn the existing full
gameplay loop into online multiplayer yet.

Local mode remains the default. Firebase is loaded only when the user creates
or joins a room; a missing configuration leaves local gameplay available.

## Room model

All records use the new path `blackwoodManor/v1_23/rooms/{roomId}`:

```text
room
├─ schemaVersion / gameVersion
├─ meta: hostPlayerId, maxPlayers, createdAt, hostHeartbeat
├─ lobby
│  └─ players/{playerId}: seatId, displayName, ready, connected, timestamps
├─ game
│  └─ stateSchemaVersion, stateVersion, authoritativeHostId, publicState
└─ actions/{actionId}: actorId, type, payload, status, timestamps
```

Room creation uses a transaction against an unused six-character room ID.
Joining also uses a transaction, checks schema/version and room capacity, and
allocates the lowest available seat. Existing version paths are never removed.

## Authority and action flow

The browser that created the room is the host for v1.23. Only it publishes
`game.publicState`; online non-host clients are intentionally read-only during
the existing gameplay loop. This prevents the prior model where every render
could overwrite shared state.

```text
client intent → actions/{actionId} → host validates → host applies → room update
host game mutation → serialized public snapshot → clients rehydrate → render
```

`LOBBY_SET_READY` is the implemented reference intent. It proves the dispatch,
host validation, applied/rejected status and listener lifecycle without moving
gameplay actions prematurely. Future versions should migrate gameplay actions
such as movement, card draws, combat and end turn into this path. Clients must
send intent only; the host must roll RNG and validate actor, turn, phase,
permission and targets.

## Serialization and rehydration

`serializeGameState()` is explicit. It excludes UI-local `viewFloor` and
`zoom`, the temporary `_special` closure, callbacks and static definitions.
It stores `stairConns` as an array, player `baseId`, card runtime data and the
Haunt `hauntId` plus runtime fields.

`rehydrateGameState()` reconstructs the `Set`, character base, item/omen/event
behavior and Haunt definition from the local static registries. Snapshots with
missing required structure or incompatible schema are rejected rather than
crashing the renderer.

## Reconnect and connection state

`playerId`, display name and the last room ID live in browser `localStorage`.
On reload, a configured client re-joins its saved room, refreshes presence and
subscribes once to the room. Firebase `.info/connected` updates the visible
connection state. Presence uses `onDisconnect` to mark a member offline.

The host writes a heartbeat when publishing a game state. Host migration is
not implemented; the stored host identity and heartbeat are deliberate hooks
for a later migration policy.

## Privacy and security limitations

`publicState` deliberately provides a boundary for future filtered snapshots,
but v1.23 does not yet implement traitor/private-book filtering. The current
game ships Haunt definitions in the browser, so this release cannot claim
secret-role protection. Firebase Realtime Database rules must be configured
before production: require authentication, limit membership changes, allow
only the host to write `game`, and constrain `actions` to their actor.

Do not add service-account keys, private credentials or `firebase-config.js`
to source control.
