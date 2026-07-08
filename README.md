# Pi-hole Blocklists Collection

A curated collection of Pi-hole blocklists focused on privacy, security and
compatibility, plus a small interactive CLI to install, update, and remove
them — no manual copy-pasting of URLs into the admin panel required.

The lists are organised by category, allowing you to enable only the
protection levels that fit your environment.

---

## Included Lists

| List | Description | Recommended |
|------|-------------|:-----------:|
| recommended.txt | General-purpose blocklist for daily use. Includes ads, trackers and common unwanted domains. | Yes |
| privacy.txt | Additional tracking and privacy protection. | Yes |
| malware.txt | Malware, phishing and malicious domains. | Yes |
| youtube.txt | Experimental YouTube ad blocking. Due to YouTube's infrastructure, results may vary. | Optional |
| socialmedia.txt | Blocks access to popular social media platforms. Intended for productivity or parental control. | Optional |
| +18.txt | Blocks adult content. Intended for parental control or restricted environments. | Optional |
| allowlist.txt | Domains that should remain accessible to avoid false positives. | Yes |

---

## Recommended Setup

For most users, the following combination provides the best balance
between protection, compatibility and performance:

- recommended.txt
- privacy.txt
- malware.txt
- allowlist.txt

---

## Optional Lists

### socialmedia.txt
Blocks access to major social media platforms including Facebook,
Instagram, X, TikTok, Snapchat, Reddit and others.

### +18.txt
Blocks adult websites.

### youtube.txt
Attempts to reduce YouTube advertisements.
Because YouTube serves advertisements from the same infrastructure as
video content, DNS-based blocking cannot guarantee complete ad blocking.

---

## Installation

There are two ways to use these lists — pick whichever fits you:

- **Automated CLI (recommended)** — an interactive script that installs,
  updates, and removes categories for you, avoiding duplicates and
  refreshing Gravity automatically:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/diogorafael20/PiHole/main/install.sh | bash
  ```
- **Manual** — add the Raw GitHub URLs directly in the Pi-hole admin
  interface.

See [`INSTALL.md`](INSTALL.md) for the full guide, including update and
uninstall instructions for the CLI, and step-by-step instructions for the
manual method.

```
==========================================
PiHole Blocklists Installer
==========================================

Select the categories you want to install.
Type a number to toggle it, 'a' to select all,
ENTER to confirm, or 0 to exit.

  [x]  1. Recommended
  [x]  2. Privacy
  [ ]  3. Malware & Security
  [ ]  4. Social Media
  [ ]  5. YouTube Ads
  [ ]  6. Adult Content
  [ ]  7. Allowlist (safe domains)

Choice:
```

---

## Repository structure

```
PiHole/
│
├── install.sh              # Interactive installer
├── update.sh                # Refreshes Gravity + syncs new URLs
├── uninstall.sh              # Removes lists installed by the CLI
│
├── categories.txt            # Category metadata (menu is generated from this)
├── recommended.txt
├── privacy.txt
├── malware.txt
├── socialmedia.txt
├── youtube.txt
├── +18.txt
├── allowlist.txt
│
├── README.md
├── INSTALL.md
└── LICENSE
```

## Adding or editing a category

You don't need to touch any script. Just:

1. Create (or edit) a `.txt` file in the repo root — one URL per line (or
   one domain per line for `allowlist.txt`).
2. Add or edit a line in `categories.txt`:
   ```
   key|Display Name|filename|type
   ```
   `type` is `block` for blocklist URLs or `allow` for allowlist domains.

The installer reads this file at runtime, so the menu updates
automatically — no need to edit `install.sh`.

## How entries are tracked

Every list added by the CLI is tagged in Pi-hole with a comment in the
form `pihole-tools:<category>` (visible in the Pi-hole admin panel, under
**Adlists** / **Allow List**). This is how `uninstall.sh` and `update.sh`
know which entries belong to the tool, without touching anything added
manually.

## Requirements (for the CLI)

- Pi-hole (v5 or v6, gravity.db-based)
- `curl`
- `sqlite3`

---

## Credits

This repository is a curated collection of publicly available blocklists.
All credit belongs to the original maintainers of each list.
