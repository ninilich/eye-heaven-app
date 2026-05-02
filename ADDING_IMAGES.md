# Adding stereogram images to EyeHeaven

## Image requirements

- Format: JPEG (`.jpg`) or PNG (`.png`)
- Recommended size: 800–1600px on the longer side
- Aspect ratio: any — the app displays images at original size or scales down to fit the screen with a border
- Content: must be a valid stereogram (SIRDS or painted hidden-image style)

## Step 1 — Prepare files

1. Name the file with a short, lowercase, hyphen-separated ID:
   ```
   shark.jpg
   deep-sea.png
   mountain-lake.jpg
   ```

2. Keep the file size reasonable — images are downloaded to the user's device. Aim for under 500 KB per image.

## Step 2 — Update `catalog.json`

Add a new entry to the `images` array:

```json
{
  "id": "shark",
  "filename": "shark.jpg",
  "url": "https://github.com/ninilich/EyeHeaven/releases/latest/download/shark.jpg",
  "source": "vk.com/stereograms",
  "author": "Ivan Petrov"
}
```

Fields:
| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier. Use the filename without extension. |
| `filename` | Yes | Exact filename including extension (`shark.jpg`). |
| `url` | Yes | Direct download URL — always points to `releases/latest/download/<filename>`. |
| `source` | No | Website or community where the image is from. Shown in the break HUD. |
| `author` | No | Author name. Shown in the break HUD below the source. |

Also bump the `version` integer at the top of `catalog.json`:
```json
{
  "version": 4,
  "images": [ ... ]
}
```

## Step 3 — Create a GitHub Release

1. Go to **github.com/ninilich/EyeHeaven → Releases → Draft a new release**
2. Create a new tag (e.g. `catalog-v4`) **or** update the `latest` release
3. Attach the following files:
   - `catalog.json` (updated)
   - All new image files (e.g. `shark.jpg`)
   - All previously released images (re-attach them — `latest` release must contain the full catalog)
4. Publish the release

> The app always fetches from `.../releases/latest/download/...`, so the `latest` release must contain every image listed in `catalog.json`.

## Step 4 — Verify

1. Open EyeHeaven → Settings → Stereograms
2. Click **Update Now**
3. Watch the progress bar — the new image should download
4. Trigger a long break (or shorten the long break interval in settings for testing)
5. The new stereogram should appear with the correct attribution in the bottom bar

## Removing an image

1. Remove its entry from `catalog.json`
2. Bump the `version`
3. Publish a new `latest` release without the removed image file
4. The app will stop showing it on the next catalog update (existing cached files are cleaned up during pruning if `Keep most recent` is set)
