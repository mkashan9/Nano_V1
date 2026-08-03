# COM-05 decisions

## Separate bucket

Chat blobs live in private `community-media`, not `generated-assets`.

## Prepare then send

`prepare_community_media_upload` mints a pending attachment row and path.
Client uploads bytes, then `send_community_message` links attachment ids and
marks them `ready`. Caption may be empty when attachments are present.

## SAFE coupling

Send still uses SAFE-03 rate/text gates. Attachment ids/paths are evidence-ready
for SAFE-02 reports. No media review UI in this module.

## Fake-first attach

Composer attach menu creates fixture uploads without device pickers; live path
uses the same prepare → uploadBinary → send flow.
