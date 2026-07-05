#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

OWNER="${OWNER:-tioon}"
REPO="${REPO:-market_project}"
ROOT="$(cd "$(dirname "$0")" && pwd)"

generate_index() {
  local links=""
  while IFS= read -r -d '' dir; do
    local rel="${dir#"$ROOT"/}"
    [ "$rel" = "." ] && continue
    [ -f "$dir/index.html" ] || continue
    links+="    <a class=\"card\" href=\"./${rel}/\"><strong>${rel}</strong><small>${rel}</small></a>\n"
  done < <(find "$ROOT" -mindepth 1 -maxdepth 1 -type d ! -name '.git' ! -name '.cache' ! -name '.Trash' -print0 | sort -z)

  cat > "$ROOT/index.html" <<EOF
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Claude Project</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f6f3ee;
      --card: #ffffff;
      --text: #171717;
      --muted: #666;
      --line: #e5ddd1;
      --accent: #1d4ed8;
      --accent-soft: #dbeafe;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Malgun Gothic", sans-serif;
      background: radial-gradient(circle at top left, #fff 0, var(--bg) 44%, #efe8de 100%);
      color: var(--text);
      line-height: 1.5;
    }
    .wrap {
      max-width: 920px;
      margin: 0 auto;
      padding: 40px 18px 64px;
    }
    .hero {
      display: grid;
      grid-template-columns: 1.6fr 1fr;
      gap: 20px;
      align-items: end;
      margin-bottom: 28px;
    }
    h1 {
      margin: 0 0 8px;
      font-size: clamp(2rem, 4vw, 3.4rem);
      line-height: 1.05;
      letter-spacing: -0.04em;
    }
    .sub {
      margin: 0;
      color: var(--muted);
      font-size: 1rem;
      max-width: 56ch;
    }
    .meta {
      justify-self: end;
      padding: 18px;
      border: 1px solid var(--line);
      border-radius: 18px;
      background: rgba(255,255,255,.8);
      backdrop-filter: blur(6px);
      min-width: 220px;
    }
    .meta span { display:block; color: var(--muted); font-size: .85rem; }
    .meta strong { display:block; margin-top: 4px; font-size: 1.1rem; }
    .section {
      margin-top: 18px;
      padding: 20px;
      border: 1px solid var(--line);
      border-radius: 20px;
      background: rgba(255,255,255,.88);
    }
    .section h2 {
      margin: 0 0 10px;
      font-size: 1.05rem;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 12px;
    }
    a.card {
      display: block;
      padding: 16px;
      border: 1px solid var(--line);
      border-radius: 16px;
      background: var(--card);
      text-decoration: none;
      color: inherit;
      transition: transform .12s ease, border-color .12s ease, box-shadow .12s ease;
    }
    a.card:hover {
      transform: translateY(-1px);
      border-color: #c8d6f8;
      box-shadow: 0 8px 24px rgba(29, 78, 216, .08);
    }
    .card strong {
      display: block;
      font-size: 1rem;
      margin-bottom: 6px;
    }
    .card small {
      color: var(--muted);
    }
    .pill {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 999px;
      background: var(--accent-soft);
      color: var(--accent);
      font-size: .8rem;
      font-weight: 700;
      margin-bottom: 10px;
    }
    .empty {
      color: var(--muted);
      font-size: .95rem;
    }
    code {
      background: #f4efe7;
      border: 1px solid #e5ddd1;
      padding: 2px 6px;
      border-radius: 6px;
    }
    footer {
      margin-top: 18px;
      color: var(--muted);
      font-size: .85rem;
    }
    @media (max-width: 720px) {
      .hero { grid-template-columns: 1fr; }
      .meta { justify-self: start; min-width: 0; width: 100%; }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="hero">
      <div>
        <div class="pill">GitHub Pages</div>
        <h1>Claude Project</h1>
        <p class="sub">각 하위 디렉토리가 별도 프로젝트입니다. 새 폴더를 추가한 뒤 다시 배포하면 같은 저장소 안에서 개별 URL 경로로 노출됩니다.</p>
      </div>
      <div class="meta">
        <span>Base URL</span>
        <strong>https://tioon.github.io/${REPO}/</strong>
      </div>
    </div>

    <section class="section">
      <h2>Projects</h2>
      <div class="grid">
$(printf "%b" "$links")
      </div>
    </section>

    <footer>
      Paths are stable per folder, for example <code>/seoul-cheongyak-monitor/</code>.
    </footer>
  </div>
</body>
</html>
EOF
}

generate_index

mkdir -p "$ROOT/docs"
cp "$ROOT/index.html" "$ROOT/docs/index.html"
cp "$ROOT/.nojekyll" "$ROOT/docs/.nojekyll"

find "$ROOT" -mindepth 1 -maxdepth 1 -type d ! -name '.git' ! -name 'docs' ! -name '.cache' ! -name '.Trash' | while read -r dir; do
  rel="$(basename "$dir")"
  [ -f "$dir/index.html" ] || continue
  mkdir -p "$ROOT/docs/$rel"
  cp "$dir/index.html" "$ROOT/docs/$rel/index.html"
  [ -f "$dir/.nojekyll" ] && cp "$dir/.nojekyll" "$ROOT/docs/$rel/.nojekyll"
done

if [ ! -f "$ROOT/.nojekyll" ]; then
  : > "$ROOT/.nojekyll"
fi

if [ ! -d "$ROOT/.git" ]; then
  git -C "$ROOT" init -b main >/dev/null
fi

if git -C "$ROOT" remote get-url origin >/dev/null 2>&1; then
  git -C "$ROOT" remote set-url origin "https://github.com/$OWNER/$REPO.git"
else
  git -C "$ROOT" remote add origin "https://github.com/$OWNER/$REPO.git"
fi

git -C "$ROOT" add -A
if ! git -C "$ROOT" diff --cached --quiet; then
  git -C "$ROOT" commit -m "chore: initialize market project pages" >/dev/null
fi

git -C "$ROOT" push -u origin main

if ! gh api "repos/$OWNER/$REPO/pages" >/dev/null 2>&1; then
  gh api -X POST "repos/$OWNER/$REPO/pages" -f 'source[branch]=main' -f 'source[path]=/' >/dev/null
fi

echo "https://$OWNER.github.io/$REPO/"
