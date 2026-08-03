# COM-05 — Voice Messages, Photos, Videos, and Files

Active members can attach voice, photo, video, and file media to community
messages. Delivery uses private `community-media` + signed URLs (MED-02 pattern).

## Owns

- `community_message_attachments` + `community-media` bucket
- `prepare_community_media_upload` and attachment-aware `send_community_message`
- Chat attach UI (fake-first fixtures)

## Does not own

- Pins / search / gallery → COM-06
- Malware scan worker
- Full media moderation UI (SAFE-02 / MED-05)
