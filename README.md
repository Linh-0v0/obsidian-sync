# Obsidian Sync

Two-way sync for your Obsidian vault to Google Drive using [rclone](https://rclone.org/), running automatically every 15 minutes via a systemd timer (Linux) or launchd agent (macOS).

## Features

- **Two-way sync** — changes on either device are synced
- **No deletes propagated** — deleted files are kept on the other side
- **Conflict handling** — conflicting edits keep both copies (newer file wins, older gets a `.conflict` suffix)
- **Auto-retry** — 3 retries with 60s backoff on failure
- **Runs on boot** — systemd timer / launchd agent starts automatically

## Prerequisites

- Linux with systemd, **or** macOS (uses launchd)
- [rclone](https://rclone.org/) installed

## Setup

### 1. Install rclone

Linux:

```bash
sudo apt install rclone
# or
curl https://rclone.org/install.sh | sudo bash
```

macOS:

```bash
brew install rclone
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
VAULT_PATH="/home/you/your-obsidian-vault"   # or /Users/you/Obsidian on macOS
DRIVE_REMOTE="gdrive:ObsidianVault"
```

### 5. Run the initial sync

This is required once **per machine** to establish the local baseline for bisync:

```bash
rclone bisync /path/to/your/vault gdrive:ObsidianVault --resync
```

### 6. Install the scheduler

**Linux (systemd):**

```bash
mkdir -p ~/.config/systemd/user
cp systemd/obsidian-sync.service ~/.config/systemd/user/
cp systemd/obsidian-sync.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now obsidian-sync.timer
```

**macOS (launchd):**

First edit `launchd/com.user.obsidian-sync.plist` and replace `/Users/linhvu/Projects/obsidian-sync` with the absolute path to your clone (launchd does not expand `~`). Then:

```bash
cp launchd/com.user.obsidian-sync.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/com.user.obsidian-sync.plist
```

To stop/unload later: `launchctl unload -w ~/Library/LaunchAgents/com.user.obsidian-sync.plist`

### 7. Verify

**Linux:**

```bash
# Check timer status
systemctl --user status obsidian-sync.timer

# Check last sync result
systemctl --user status obsidian-sync.service

# Watch logs
tail -f sync.log
```

**macOS:**

```bash
# Confirm the agent is loaded
launchctl list | grep obsidian-sync

# Trigger a run immediately (don't wait 15 min)
launchctl kickstart -k gui/$(id -u)/com.user.obsidian-sync

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

Every 15 minutes, the scheduler (systemd timer on Linux, launchd agent on macOS) runs `sync.sh`, which calls `rclone bisync` to compare your local vault with the Google Drive folder. New or modified files are synced in both directions. Conflicts are resolved by keeping the newer file and renaming the older one with a `.conflict` suffix so nothing is lost. Deletes are never propagated — both sides act as append-only.
