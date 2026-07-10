# FEATURE-048 - Premium Photo Galleries

## Owner Gallery Flow

Venue owners manage gallery photos from the venue dashboard Gallery page. The page uses the existing Vexda dark dashboard language: glass panels, gradient accents, rounded cards, hover previews, upload progress, and premium empty states.

Supported owner actions:

- Upload one or more images with preview, category selection, optional caption, validation, Firebase Storage upload, and Firestore metadata save.
- Categorise images as Cover / Hero, Interior, Drinks, Food, Events, Atmosphere, or Other.
- Set one active gallery image as the cover image.
- Replace a selected image while keeping the same media record.
- Reorder gallery images with a drag-and-drop dialog.
- Delete images by soft-deleting metadata with `status: deleted` and `visible: false`.
- Adjust image positioning for the public cover frame.

Future placeholders are visible for 360-degree images and video gallery support, but video upload is not implemented.

## Public Gallery Display

Public venue profiles read active gallery metadata from the venue document and render:

- A hero image from the selected gallery cover, falling back to the existing venue banner.
- A premium gallery section with category chips.
- Featured image and responsive grid previews.
- Full-screen lightbox navigation.
- Broken-image fallback UI.
- Empty state when no gallery images exist.

Legacy `galleryImageUrls` still work. New gallery writes also sync richer `galleryImages` entries so public profiles can show category and caption data.

## Firestore Structure

The project uses the existing media collection convention:

```text
venues/{venueId}/media/{mediaId}
```

Gallery media documents include:

- `mediaId`
- `venueId`
- `mediaType: "gallery"`
- `imageUrl`
- `thumbnailUrl`
- `storagePath`
- `category`
- `caption`
- `featured`
- `sortOrder`
- `status`
- `visible`
- `uploadedByUid`
- `uploadedAt`
- `updatedAt`

Allowed statuses:

- `active`
- `hidden`
- `deleted`

For public profile performance and legacy compatibility, active gallery media is synced onto the venue document as:

- `galleryImageUrls`
- `galleryImages`

## Storage Paths

Images are stored under the existing venue media path:

```text
venues/{venueId}/media/gallery/{mediaId}.{ext}
```

The upload service validates supported image types and a 10 MB file-size limit before writing to Firebase Storage.

## Permissions

Firestore media rules allow:

- Public reads only for active, visible media metadata.
- Venue owners, venue managers, assigned venue users, and admins to create/update media metadata.
- Founder-only hard deletes.

Storage rules allow:

- Public reads for published Storage URLs referenced by Firestore.
- Venue owners, venue managers, assigned venue users, and admins to upload/update/delete venue media objects.
- Image uploads only, with a 10 MB size cap.

## Subscription Placeholder

`SubscriptionService.canUseGallery(...)` is a temporary wrapper around existing media centre plan limits. It is ready to be replaced by the real subscription entitlement service later.

This feature does not implement Stripe or final subscription enforcement.

## Admin Support

The backend/data rules now allow admins to read and manage venue media metadata and Storage objects. Existing admin venue CRM surfaces gallery counts. A richer admin gallery tab/moderation UI can be added later on top of the same `venues/{venueId}/media/{mediaId}` data.

TODO(admin-gallery): add an admin venue detail gallery section with hide/remove controls for inappropriate images if a dedicated venue detail tab is introduced.

## Future Video / 360 Support

The current implementation is image-only. The dashboard exposes future-ready placeholders for 360-degree imagery and video gallery support. When video support is added, use a separate media type/status path and update validation, Storage rules, and public rendering rather than overloading image uploads.
