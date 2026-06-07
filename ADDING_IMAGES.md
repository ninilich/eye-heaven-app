# Adding stereogram images to EyeHeaven

## Image requirements

- Format: JPEG (`.jpg`)
- Recommended size: 1600px on the longer side (good for Retina displays)
- Aspect ratio: any — the app scales images to fit the screen
- Content: must be a valid stereogram (SIRDS or painted hidden-image style)
- File size: aim for under 1 MB per image

## Step 1 — Add the image file

Copy the `.jpg` file to the `Stereograms/` folder in the repository.

Use a descriptive lowercase filename:
```
shark.jpg
deep-sea.jpg
mountain-lake.jpg
```

## Step 2 — Update `Stereograms/catalog.json`

Add a new entry to the `images` array:

```json
{
  "id": "shark",
  "filename": "shark.jpg",
  "url": "https://raw.githubusercontent.com/ninilich/eye-heaven-app/main/Stereograms/shark.jpg",
  "source": "https://example.com",
  "author": "Author Name"
}
```

Fields:
| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier, use filename without extension |
| `filename` | Yes | Exact filename including extension |
| `url` | Yes | `raw.githubusercontent.com` URL — change only the filename part |
| `source` | No | Website where the image is from. Shown in the break overlay. |
| `author` | No | Author name. Shown below source in the break overlay. |

Also bump the `version` integer:
```json
{
  "version": 2,
  "images": [ ... ]
}
```

## Step 3 — Commit and push to `main`

```bash
git add Stereograms/shark.jpg Stereograms/catalog.json
git commit -m "feat(stereograms): add shark"
git push origin main
```

Pushes that only change `Stereograms/` do **not** trigger a new app release — the CI workflow
ignores that path. The new images are immediately accessible on `raw.githubusercontent.com`,
but the updated `catalog.json` will only reach users when the next app release is published
(CI copies `Stereograms/catalog.json` → `dist/` and attaches it to the GitHub release).

To make new images available without a full app release, trigger the release workflow manually
(`workflow_dispatch`) or bump the app version.

## Step 4 — Verify in app

1. Open EyeHeaven → Settings → Stereograms
2. Click **Update Now**
3. The new image should download and appear in the progress
4. Trigger a long break to confirm the image shows with correct attribution

## Removing an image

1. Remove its entry from `catalog.json`
2. Bump `version`
3. Remove the image file from `Stereograms/`
4. Commit and push

The app stops showing the image on next catalog update. Cached files are cleaned up during pruning if a storage limit is configured.
