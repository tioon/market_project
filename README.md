# Claude Project

This folder is the source of truth for the `market_project` GitHub Pages site.

## Layout

- The repo root is the landing page.
- Each immediate subfolder with an `index.html` becomes its own Pages URL path.
- Example: `seoul-cheongyak-monitor/` is available at `https://tioon.github.io/market_project/seoul-cheongyak-monitor/`.

## Current projects

- `seoul-cheongyak-monitor`

## Deploy

Run the helper script from this folder:

```bash
./deploy-pages.sh
```

The script will:

- regenerate the root landing page from the current subfolders
- commit the result to `market_project`
- push to `main`

## Adding more projects

Create a new subdirectory with its own `index.html`, then run the deploy script again.
