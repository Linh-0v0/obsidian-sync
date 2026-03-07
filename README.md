# Obsidian Sync

Two-way sync for your Obsidian vault to Google Drive using [rclone](https://rclone.org/), running automatically every 15 minutes via a systemd timer.

## Features

- **Two-way sync** — changes on either device are synced
- **No deletes propagated** — deleted files are kept on the other side
- **Conflict handling** — conflicting edits keep both copies (newer file wins, older gets a `.conflict` suffix)
- **Auto-retry** — 3 retries with 60s backoff on failure
- **Runs on boot** — systemd timer starts automatically

## Prerequisites

- Linux with systemd
- [rclone](https://rclone.org/) installed

## Setup

### 1. Install rclone

```bash
sudo apt install rclone
# or
curl https://rclone.org/install.sh | sudo bash
```

### 2. Configure Google Drive remote

```bash
rclone config
```

Follow the prompts:
- Select **New remote**
- Name it `gdrive`
- Choose **Google Drive**
- Complete the OAuth flow in your browser

Verify it works:

```bash
rclone lsd gdrive:
```

### 3. Clone this repo

```bash
git clone https://github.com/YOUR_USERNAME/obsidian-sync.git
cd obsidian-sync
```

### 4. Configure your vault path

Edit `.env` and set your vault path:

```bash
VAULT_PATH="/home/you/your-obsidian-vault"
DRIVE_REMOTE="gdrive:ObsidianVault"
```

### 5. Run the initial sync

This is required once to establish the baseline for bisync:

```bash
rclone bisync /path/to/your/vault gdrive:ObsidianVault --resync
```
rclone bisync /home/linh/Obsidian gdrive:ObsidianVault --resync

### 6. Install the systemd timer

```bash
mkdir -p ~/.config/systemd/user
cp systemd/obsidian-sync.service ~/.config/systemd/user/
cp systemd/obsidian-sync.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now obsidian-sync.timer
```

### 7. Verify

```bash
# Check timer status
systemctl --user status obsidian-sync.timer

# Check last sync result
systemctl --user status obsidian-sync.service

# Watch logs
tail -f sync.log
```

## Manual sync

To trigger a sync manually at any time:

```bash
./sync.sh
```

## Logs

- `sync.log` — all sync activity
- `sync-errors.log` — only written when all retries fail

## How it works

Every 15 minutes, the systemd timer runs `sync.sh` which calls `rclone bisync` to compare your local vault with the Google Drive folder. New or modified files are synced in both directions. Conflicts are resolved by keeping the newer file and renaming the older one with a `.conflict` suffix so nothing is lost. Deletes are never propagated — both sides act as append-only.
