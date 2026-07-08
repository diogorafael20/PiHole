# Pi-hole Blocklists Collection

A curated collection of Pi-hole blocklists focused on privacy, security and compatibility.

The lists are organised by category, allowing you to enable only the protection levels that fit your environment.

---

## Included Lists

| List | Description | Recommended |
|------|-------------|:-----------:|
| recommended.txt | General-purpose blocklist for daily use. Includes ads, trackers and common unwanted domains. | Yes |
| privacy.txt | Additional tracking and privacy protection. | Yes |
| malware.txt | Malware, phishing and malicious domains. | Yes |
| youtube.txt | Experimental YouTube ad blocking. Due to YouTube's infrastructure, results may vary. | Optional |
| social-media.txt | Blocks access to popular social media platforms. Intended for productivity or parental control. | Optional |
| 18+.txt | Blocks adult content. Intended for parental control or restricted environments. | Optional |
| allowlist.txt | Domains that should remain accessible to avoid false positives. | Yes |

---

## Recommended Setup

For most users, the following combination provides the best balance between protection, compatibility and performance:

- recommended.txt
- privacy.txt
- malware.txt
- allowlist.txt

---

## Optional Lists

### social-media.txt

Blocks access to major social media platforms including Facebook, Instagram, X, TikTok, Snapchat, Reddit and others.

Recommended for:

- Schools
- Businesses
- Parental control
- Productivity-focused environments

### 18+.txt

Blocks adult websites.

Recommended for:

- Families
- Schools
- Child protection

### youtube.txt

Attempts to reduce YouTube advertisements.

Because YouTube serves advertisements from the same infrastructure as video content, DNS-based blocking cannot guarantee complete ad blocking.

---

## Installation

See the installation guide in `INSTALL.md`.

---

## Credits

This repository is a curated collection of publicly available blocklists.

All credit belongs to the original maintainers of each list.
