# Proxmox VE Snapshot Manager

Automated snapshot management for Proxmox VE with intelligent retention policies supporting daily, weekly, and monthly snapshots.

## Features

- Create automated snapshots with daily/weekly/monthly schedules
- Intelligent retention policy: Keep 3 daily, 2 weekly, 1 monthly snapshot
- Flexible VM selection by ID, name, or tags
- Dry-run mode for testing
- Comprehensive logging
- No external dependencies (uses native `pvesh` command)

## Installation

### 1. Copy Files to Proxmox Host

Copy the script files to your Proxmox host:

```bash
scp -r ~/projects/scripts/proxmox-snapshots root@your-proxmox-host:/root/
```

Or clone directly on the Proxmox host:

```bash
cd /root
git clone <your-repo> scripts
cd scripts/proxmox-snapshots
```

### 2. Make Script Executable

```bash
chmod +x /root/scripts/proxmox-snapshots/pve_snapshot_manager.py
```

### 3. Configure VM Selection

Edit the configuration file:

```bash
nano /root/scripts/proxmox-snapshots/config.json
```

## Configuration

The `config.json` file supports the following options:

```json
{
  "include_vms": [],
  "exclude_vms": [],
  "include_tags": [],
  "retention_daily": 3,
  "retention_weekly": 2,
  "retention_monthly": 1,
  "include_ram": false,
  "log_file": "/var/log/pve-snapshot-manager.log",
  "debug": false
}
```

### Configuration Options

- **include_vms**: Array of VM IDs or names to include (required - must specify VMs)
  - Example: `[100, 101, "webserver", "database"]`
  - IMPORTANT: If both `include_vms` and `include_tags` are empty, no VMs will be processed

- **exclude_vms**: Array of VM IDs or names to exclude
  - Example: `[999, "test-vm"]`
  - Exclusions are applied after inclusions

- **include_tags**: Array of tags to include (VMs must have at least one matching tag)
  - Example: `["backup", "production"]`
  - Note: Tags are set in Proxmox UI under VM > Options > Tags
  - IMPORTANT: If both `include_vms` and `include_tags` are empty, no VMs will be processed

- **retention_daily**: Number of daily snapshots to keep (default: 3)

- **retention_weekly**: Number of weekly snapshots to keep (default: 2)

- **retention_monthly**: Number of monthly snapshots to keep (default: 1)

- **include_ram**: Include VM RAM state in snapshots (default: false)
  - `true`: Snapshots include RAM (larger size, preserves exact VM state)
  - `false`: Snapshots without RAM (smaller, requires clean shutdown for consistency)

- **log_file**: Path to log file (default: `/var/log/pve-snapshot-manager.log`)

- **debug**: Enable debug logging (default: false)

### Selection Logic

The script applies filters in this order:

1. **Check if any VMs are specified**: If both `include_vms` and `include_tags` are empty, no VMs will be processed (script will exit with a warning)

2. **Check exclusions**: If a VM is in `exclude_vms` (by ID or name), skip it

3. **Check inclusions**: Include the VM if:
   - The VM ID or name is in `include_vms`, OR
   - The VM has at least one tag matching those in `include_tags`

4. **If not included**: Skip the VM (only explicitly included VMs are processed)

## Usage

### Manual Execution

Run the script manually to create/cleanup snapshots:

```bash
# Daily snapshots (run this daily)
/root/scripts/proxmox-snapshots/pve_snapshot_manager.py \
  -c /root/scripts/proxmox-snapshots/config.json \
  -n pve \
  -t daily

# Weekly snapshots (run this weekly)
/root/scripts/proxmox-snapshots/pve_snapshot_manager.py \
  -c /root/scripts/proxmox-snapshots/config.json \
  -n pve \
  -t weekly

# Monthly snapshots (run this monthly)
/root/scripts/proxmox-snapshots/pve_snapshot_manager.py \
  -c /root/scripts/proxmox-snapshots/config.json \
  -n pve \
  -t monthly
```

Replace `pve` with your actual Proxmox node name. To find your node name, run: `pvesh get /nodes`

### Dry Run Mode

Test the script without making any changes:

```bash
/root/scripts/proxmox-snapshots/pve_snapshot_manager.py \
  -c /root/scripts/proxmox-snapshots/config.json \
  -n pve \
  -t daily \
  --dry-run
```

### Command Line Options

- `-c, --config`: Path to configuration file (required)
- `-n, --node`: Proxmox node name (required)
- `-t, --type`: Snapshot type: `daily`, `weekly`, or `monthly` (required)
- `-d, --dry-run`: Preview actions without making changes

## Automated Scheduling with Cron

Set up cron jobs to automate snapshot creation. Edit the root crontab:

```bash
crontab -e
```

Add the following lines (adjust paths and node name as needed):

```cron
# Daily snapshots at 2:00 AM
0 2 * * * /root/scripts/proxmox-snapshots/pve_snapshot_manager.py -c /root/scripts/proxmox-snapshots/config.json -n pve -t daily >> /var/log/pve-snapshot-cron.log 2>&1

# Weekly snapshots on Sunday at 3:00 AM
0 3 * * 0 /root/scripts/proxmox-snapshots/pve_snapshot_manager.py -c /root/scripts/proxmox-snapshots/config.json -n pve -t weekly >> /var/log/pve-snapshot-cron.log 2>&1

# Monthly snapshots on the 1st at 4:00 AM
0 4 1 * * /root/scripts/proxmox-snapshots/pve_snapshot_manager.py -c /root/scripts/proxmox-snapshots/config.json -n pve -t monthly >> /var/log/pve-snapshot-cron.log 2>&1
```

Verify cron jobs are scheduled:

```bash
crontab -l
```

## How It Works

### Snapshot Naming Convention

Snapshots are created with the following naming pattern:

```
auto-snapshot-{type}-{YYYY}-{MM}-{DD}-{HHMMSS}
```

Examples:
- `auto-snapshot-daily-2025-12-29-020000`
- `auto-snapshot-weekly-2025-12-29-030000`
- `auto-snapshot-monthly-2025-12-01-040000`

### Retention Logic

For each VM and snapshot type:

1. **Daily**: Creates a new snapshot if no snapshot exists from today. Keeps the 3 most recent daily snapshots.

2. **Weekly**: Creates a new snapshot if the latest weekly snapshot is 7+ days old. Keeps the 2 most recent weekly snapshots.

3. **Monthly**: Creates a new snapshot if no snapshot exists from the current month. Keeps only the most recent monthly snapshot.

Old snapshots beyond the retention limits are automatically deleted.

### Example Timeline

With default settings (3 daily, 2 weekly, 1 monthly):

**Day 1-3**: Create daily snapshots → 3 daily snapshots exist
**Day 4**: Create daily snapshot → Delete oldest daily → Still 3 daily snapshots
**Day 7**: Create weekly snapshot → 3 daily + 1 weekly snapshot
**Day 14**: Create weekly snapshot → 3 daily + 2 weekly snapshots
**Day 21**: Create weekly snapshot → Delete oldest weekly → 3 daily + 2 weekly snapshots
**Month 2, Day 1**: Create monthly snapshot → 3 daily + 2 weekly + 1 monthly snapshot

## Logging

Logs are written to `/var/log/pve-snapshot-manager.log` by default.

View recent log entries:

```bash
tail -f /var/log/pve-snapshot-manager.log
```

Cron execution logs (if configured):

```bash
tail -f /var/log/pve-snapshot-cron.log
```

## Troubleshooting

### Permission Denied

The script must run as root on the Proxmox host to access `pvesh` commands.

### Finding Your Node Name

```bash
pvesh get /nodes
```

### Testing VM Selection

Use dry-run mode to verify which VMs will be processed:

```bash
/root/scripts/proxmox-snapshots/pve_snapshot_manager.py \
  -c /root/scripts/proxmox-snapshots/config.json \
  -n pve \
  -t daily \
  --dry-run
```

### Checking Existing Snapshots

View snapshots for a specific VM:

```bash
pvesh get /nodes/pve/qemu/100/snapshot
```

Replace `pve` with your node name and `100` with your VM ID.

## Best Practices

1. **Test First**: Always use `--dry-run` when testing configuration changes

2. **Monitor Disk Space**: Snapshots consume storage. Monitor disk usage regularly:
   ```bash
   pvesm status
   ```

3. **Install QEMU Guest Agent**: For better snapshot consistency, install `qemu-guest-agent` in your VMs:
   ```bash
   # Debian/Ubuntu
   apt-get install qemu-guest-agent

   # CentOS/RHEL
   yum install qemu-guest-agent
   ```
   Then enable it in Proxmox VM options.

4. **Exclude Database VMs**: Consider excluding VMs running databases or using application-specific backup tools for them instead

5. **Regular Backups**: Snapshots are not backups. Continue using Proxmox Backup Server or vzdump for full backups

6. **Review Logs**: Periodically check logs to ensure snapshots are being created and cleaned up properly

## Limitations

- Snapshots are stored on the same storage as the VM (not a separate backup)
- Large VMs with frequent changes will use significant disk space for snapshots
- Snapshots can impact VM performance during creation
- This script only manages snapshots it creates (those with `auto-snapshot-` prefix)

## License

MIT License - Feel free to modify and use as needed.
