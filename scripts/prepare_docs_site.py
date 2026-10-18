"""Stage only public documentation for Jekyll; never copy the repository wholesale."""
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "_site_source"
PAGES = {
    "README.md": ("index.md", "/", "ReManga API — документация API Реманга и генератор", "Неофициальный справочник ReManga API: HTTP-методы и маршруты, примеры запросов, JSON и CSV, portable-генератор для Windows."),
    "API_REFERENCE.md": ("api-reference.md", "/api-reference/", "Справочник ReManga API — методы и маршруты", "Полный справочник HTTP-маршрутов API Реманга, извлечённых из публичного JavaScript-клиента. Методы GET, POST, PUT, PATCH и DELETE."),
    "GUIDE_RU.md": ("guide.md", "/guide/", "ReManga API: примеры запросов и руководство", "Практическое руководство по ReManga API: каталог карточек, публичный профиль, инвентарь пользователя и ограничения справочника."),
}
LINKS = {source: permalink for source, (_, permalink, _, _) in PAGES.items()}


def main():
    DEST.mkdir(exist_ok=True)
    shutil.copytree(ROOT / "site", DEST, dirs_exist_ok=True)
    (DEST / "assets").mkdir(exist_ok=True)
    shutil.copy2(ROOT / "docs/assets/remanga-logo.png", DEST / "assets/remanga-logo.png")
    for source, (target, permalink, title, description) in PAGES.items():
        body = (ROOT / source).read_text(encoding="utf-8-sig")
        # Resolve repository files on GitHub and documentation pages on this site.
        def replace_link(match):
            url = match.group(1)
            path, separator, fragment = url.partition("#")
            if path in LINKS:
                return "]({{ '" + LINKS[path] + "' | relative_url }}" + (separator + fragment if separator else "") + ")"
            if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", url) or url.startswith(("#", "/")):
                return match.group(0)
            return "](https://github.com/TheDivineLabs/remanga-api/blob/main/" + url + ")"
        body = re.sub(r"\]\(([^)]+)\)", replace_link, body)
        body = body.replace('src="docs/assets/', 'src="{{ \'/assets/\' | relative_url }}')
        stamp = subprocess.check_output(
            ["git", "log", "-1", "--format=%cI", "--", source],
            cwd=ROOT, text=True
        ).strip()
        metadata = {
            "title": title, "description": description, "permalink": permalink,
            "source_file": source, "last_modified_at": stamp,
        }
        front = "---\n" + "\n".join(f"{key}: {json.dumps(value, ensure_ascii=False)}" for key, value in metadata.items()) + "\n---\n\n"
        (DEST / target).write_text(front + body, encoding="utf-8")
    # Google also supports UTF-8 plain-text sitemaps, one absolute URL per line.
    # Keep this independent of Jekyll's XML plugin but derived from the same pages.
    urls = ["https://thedivinelabs.github.io/remanga-api" + page[1] for page in PAGES.values()]
    (DEST / "sitemap.txt").write_text("\n".join(urls) + "\n", encoding="utf-8")
    # Structured snapshots stay downloads, not thousands of low-value index pages.
    for name in ("endpoints.json", "endpoints.csv", "snapshot-summary.json"):
        shutil.copy2(ROOT / name, DEST / name)
    print(f"Prepared {len(PAGES)} public documentation pages in {DEST}")


if __name__ == "__main__":
    main()
