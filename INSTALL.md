# Installation

There are two ways to use these blocklists: the automated CLI (recommended,
handles duplicates and Gravity updates for you) or adding the Raw GitHub
URLs manually in the Pi-hole admin interface.

---

## Option 1 — Automated CLI (recommended)

### Prerequisites

- A working [Pi-hole](https://pi-hole.net/) installation (v5 or v6).
- `curl` and `sqlite3` available on the system (both are normally already
  present on a Pi-hole host).

### Quick install

Run directly, no cloning required:

```bash
curl -fsSL https://raw.githubusercontent.com/diogorafael20/PiHole/main/install.sh | bash
```

The script will fetch category and list metadata from this repository as
needed while it runs.

### Or clone the repository first

Useful if you want to review or customize the lists before running
anything:

```bash
git clone https://github.com/diogorafael20/PiHole.git
cd PiHole
chmod +x install.sh update.sh uninstall.sh
./install.sh
```

When run from a local clone, the scripts read the `.txt` list files from
the repo root instead of downloading them — handy for testing changes
before pushing them.

### Usage

**Install blocklists**

```bash
./install.sh
```

Toggle categories by typing their number, then press ENTER to confirm and
install. Type `a` to select every category, or `0` to exit without
changes.

**Update**

```bash
./update.sh
```

Refreshes Pi-hole Gravity and checks already-installed categories for any
URLs added to the `.txt` files since you last ran the installer. It never
removes anything.

**Uninstall**

```bash
./uninstall.sh
```

Shows only the categories that were installed by the CLI (identified by
the `pihole-tools:<category>` tag) and lets you remove one, several, or
all of them. Anything added manually through the Pi-hole admin panel is
left untouched.

### Backups

`install.sh`, `update.sh`, and `uninstall.sh` all back up `gravity.db`
before making changes, to:

```
~/pihole-tools-backups/gravity-<timestamp>.db
```

To restore a backup manually:

```bash
sudo systemctl stop pihole-FTL
sudo cp ~/pihole-tools-backups/gravity-<timestamp>.db /etc/pihole/gravity.db
sudo systemctl start pihole-FTL
```

### Troubleshooting

- **"Pi-hole does not appear to be installed"** — the script offers to run
  the official Pi-hole installer for you, or install Pi-hole manually
  first and re-run.
- **"Gravity update failed"** — check `/tmp/pihole-tools-gravity.log` for
  details; this is the raw output of `pihole -g`.
- **Permission errors on `gravity.db`** — run the scripts with a user that
  has access to `/etc/pihole/` (typically via `sudo`).

---

## Option 2 — Manual installation

The manual way is to add the Raw GitHub URLs directly to Pi-hole. This
allows Pi-hole to automatically download the latest version of each list
whenever Gravity is updated.

### Add a Blocklist

1. Open the Pi-hole Admin Interface.
2. Navigate to **Group Management → Adlists**.
3. Click **Add a new adlist**.
4. Paste the Raw GitHub URL of the desired list.
5. Click **Add**.
6. Repeat the process for any additional lists.

### Update Gravity

Once all lists have been added, update Gravity from:

**Tools → Update Gravity**

or via SSH:

```bash
pihole -g
```

Pi-hole will download the latest version of each list and apply the
changes automatically.

### Updating

No manual updates are required.
Whenever you update Gravity (either from the web interface or by running
`pihole -g`), Pi-hole will automatically fetch the latest version of all
lists from this repository.

---

## Verify

To verify that everything is working correctly:

```bash
pihole status
```

You can also monitor the Pi-hole logs:

```bash
pihole -t
```
