from bs4 import BeautifulSoup
import os
import json

home = os.path.expanduser("~")
htmlPath = f"{home}-.mozilla/bookmarks.html"
jsonPath = f"{home}/.mozilla/bookmarks.json"
with open(htmlPath, "r", encoding="utf-8") as f:
    soup = BeautifulSoup(f, "html.parser")

bookmarks = []

for a in soup.find_all("a"):
    title = a.get_text()
    url = a.get("href")
    if url:
        bookmarks.append(
            {
                "title": title,
                "url": url,
            }
        )

with open(jsonPath, "w", encoding="utf-8") as f:
    json.dump(bookmarks, f, indent=2)
