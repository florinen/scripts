#!/usr/bin/env python3
"""
Proxmox VE Snapshot Manager
Automates snapshot creation and cleanup with daily/weekly/monthly retention policies
"""

import subprocess
import json
import re
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import argparse
import logging
import sys


class ProxmoxSnapshotManager:
    """Manages Proxmox VM snapshots with retention policies"""

    SNAPSHOT_PREFIX = "auto-snapshot"

    def __init__(self, config: Dict, dry_run: bool = False):
        self.config = config
        self.dry_run = dry_run
        self.logger = self._setup_logging()

    def _setup_logging(self) -> logging.Logger:
        """Configure logging"""
        log_level = logging.DEBUG if self.config.get('debug', False) else logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.config.get('log_file', '/var/log/pve-snapshot-manager.log')),
                logging.StreamHandler(sys.stdout)
            ]
        )
        return logging.getLogger(__name__)

    def _run_pvesh(self, command: List[str]) -> Optional[Dict]:
        """Execute pvesh command and return JSON result"""
        try:
            cmd = ['pvesh', 'get'] + command + ['--output-format', 'json']
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return json.loads(result.stdout) if result.stdout else None
        except subprocess.CalledProcessError as e:
            self.logger.error(f"pvesh command failed: {e.stderr}")
            return None
        except json.JSONDecodeError as e:
            self.logger.error(f"Failed to parse JSON: {e}")
            return None

    def _run_pvesh_set(self, command: List[str]) -> bool:
        """Execute pvesh set/create/delete command"""
        if self.dry_run:
            self.logger.info(f"[DRY RUN] Would execute: pvesh {' '.join(command)}")
            return True

        try:
            cmd = ['pvesh'] + command
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return True
        except subprocess.CalledProcessError as e:
            self.logger.error(f"pvesh command failed: {e.stderr}")
            return False

    def get_vm_list(self, node: str) -> List[Dict]:
        """Get list of VMs on a node"""
        vms = self._run_pvesh([f'/nodes/{node}/qemu'])
        if not vms:
            return []

        # Filter VMs based on configuration
        filtered_vms = []
        include_vms = self.config.get('include_vms', [])
        exclude_vms = self.config.get('exclude_vms', [])
        include_tags = self.config.get('include_tags', [])

        # If both include lists are empty, process no VMs
        if not include_vms and not include_tags:
            self.logger.warning("No VMs specified in include_vms or include_tags. No VMs will be processed.")
            return []

        for vm in vms:
            vmid = vm['vmid']
            name = vm.get('name', '')
            tags = vm.get('tags', '').split(';') if vm.get('tags') else []

            # Check exclusions first
            if vmid in exclude_vms or name in exclude_vms:
                continue

            # Check if VM is in include list
            if vmid in include_vms or name in include_vms:
                filtered_vms.append(vm)
                continue

            # Check if VM has matching tags
            if include_tags and any(tag in include_tags for tag in tags):
                filtered_vms.append(vm)
                continue

        return filtered_vms

    def get_snapshots(self, node: str, vmid: int) -> List[Dict]:
        """Get list of snapshots for a VM"""
        snapshots = self._run_pvesh([f'/nodes/{node}/qemu/{vmid}/snapshot'])
        if not snapshots:
            return []

        # Filter only auto-snapshots
        auto_snapshots = []
        for snap in snapshots:
            name = snap.get('name', '')
            if name.startswith(self.SNAPSHOT_PREFIX):
                auto_snapshots.append(snap)

        return auto_snapshots

    def parse_snapshot_name(self, name: str) -> Optional[Dict]:
        """Parse snapshot name to extract type and timestamp"""
        # Format: auto-snapshot-daily-2025-12-29-143000
        # Format: auto-snapshot-weekly-2025-12-29-143000
        # Format: auto-snapshot-monthly-2025-12-29-143000
        pattern = rf'{self.SNAPSHOT_PREFIX}-(daily|weekly|monthly)-(\d{{4}})-(\d{{2}})-(\d{{2}})-(\d{{6}})'
        match = re.match(pattern, name)

        if not match:
            return None

        snap_type = match.group(1)
        year = int(match.group(2))
        month = int(match.group(3))
        day = int(match.group(4))
        time_str = match.group(5)
        hour = int(time_str[0:2])
        minute = int(time_str[2:4])
        second = int(time_str[4:6])

        try:
            timestamp = datetime(year, month, day, hour, minute, second)
            return {
                'name': name,
                'type': snap_type,
                'timestamp': timestamp
            }
        except ValueError:
            return None

    def create_snapshot(self, node: str, vmid: int, snap_type: str) -> bool:
        """Create a new snapshot"""
        timestamp = datetime.now().strftime('%Y-%m-%d-%H%M%S')
        snap_name = f"{self.SNAPSHOT_PREFIX}-{snap_type}-{timestamp}"
        description = f"Automatic {snap_type} snapshot created at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"

        self.logger.info(f"Creating {snap_type} snapshot for VM {vmid}: {snap_name}")

        command = [
            'create',
            f'/nodes/{node}/qemu/{vmid}/snapshot',
            '-snapname', snap_name,
            '-description', description
        ]

        # Include RAM if configured
        if self.config.get('include_ram', False):
            command.extend(['-vmstate', '1'])
        else:
            command.extend(['-vmstate', '0'])

        return self._run_pvesh_set(command)

    def delete_snapshot(self, node: str, vmid: int, snap_name: str) -> bool:
        """Delete a snapshot"""
        self.logger.info(f"Deleting snapshot for VM {vmid}: {snap_name}")

        command = [
            'delete',
            f'/nodes/{node}/qemu/{vmid}/snapshot/{snap_name}'
        ]

        return self._run_pvesh_set(command)

    def apply_retention_policy(self, node: str, vmid: int, snapshots: List[Dict]) -> None:
        """Apply retention policy to snapshots"""
        # Parse all snapshots
        parsed_snapshots = []
        for snap in snapshots:
            parsed = self.parse_snapshot_name(snap['name'])
            if parsed:
                parsed_snapshots.append(parsed)

        # Group by type
        snapshots_by_type = {
            'daily': [],
            'weekly': [],
            'monthly': []
        }

        for snap in parsed_snapshots:
            snap_type = snap['type']
            if snap_type in snapshots_by_type:
                snapshots_by_type[snap_type].append(snap)

        # Sort each type by timestamp (newest first)
        for snap_type in snapshots_by_type:
            snapshots_by_type[snap_type].sort(key=lambda x: x['timestamp'], reverse=True)

        # Apply retention policy
        retention = {
            'daily': self.config.get('retention_daily', 3),
            'weekly': self.config.get('retention_weekly', 2),
            'monthly': self.config.get('retention_monthly', 1)
        }

        for snap_type, snaps in snapshots_by_type.items():
            keep_count = retention[snap_type]
            to_delete = snaps[keep_count:]

            if to_delete:
                self.logger.info(f"VM {vmid}: Keeping {keep_count} {snap_type} snapshots, deleting {len(to_delete)}")
                for snap in to_delete:
                    self.delete_snapshot(node, vmid, snap['name'])
            else:
                self.logger.debug(f"VM {vmid}: {len(snaps)} {snap_type} snapshots within retention policy")

    def should_create_snapshot(self, snap_type: str, existing_snapshots: List[Dict]) -> bool:
        """Determine if a new snapshot of given type should be created"""
        # Parse existing snapshots of this type
        type_snapshots = []
        for snap in existing_snapshots:
            parsed = self.parse_snapshot_name(snap['name'])
            if parsed and parsed['type'] == snap_type:
                type_snapshots.append(parsed)

        if not type_snapshots:
            return True

        # Sort by timestamp (newest first)
        type_snapshots.sort(key=lambda x: x['timestamp'], reverse=True)
        latest = type_snapshots[0]['timestamp']
        now = datetime.now()

        # Check if we need a new snapshot based on type
        if snap_type == 'daily':
            # Create if latest is from a different day
            return latest.date() < now.date()
        elif snap_type == 'weekly':
            # Create if latest is from a different week (more than 7 days ago)
            return (now - latest).days >= 7
        elif snap_type == 'monthly':
            # Create if latest is from a different month
            return latest.month != now.month or latest.year != now.year

        return False

    def run(self, node: str, snap_type: str) -> None:
        """Main execution method"""
        self.logger.info(f"Starting snapshot management (type: {snap_type}, node: {node}, dry_run: {self.dry_run})")

        vms = self.get_vm_list(node)
        self.logger.info(f"Found {len(vms)} VMs to process")

        for vm in vms:
            vmid = vm['vmid']
            name = vm.get('name', 'unknown')

            self.logger.info(f"Processing VM {vmid} ({name})")

            # Get existing snapshots
            snapshots = self.get_snapshots(node, vmid)

            # Check if we need to create a new snapshot
            if self.should_create_snapshot(snap_type, snapshots):
                if self.create_snapshot(node, vmid, snap_type):
                    # Refresh snapshot list after creation
                    snapshots = self.get_snapshots(node, vmid)
                else:
                    self.logger.error(f"Failed to create snapshot for VM {vmid}")
            else:
                self.logger.info(f"VM {vmid}: Recent {snap_type} snapshot exists, skipping creation")

            # Apply retention policy
            self.apply_retention_policy(node, vmid, snapshots)

        self.logger.info("Snapshot management completed")


def load_config(config_file: str) -> Dict:
    """Load configuration from JSON file"""
    try:
        with open(config_file, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Configuration file not found: {config_file}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in configuration file: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='Proxmox VE Snapshot Manager')
    parser.add_argument('-c', '--config', required=True, help='Configuration file path')
    parser.add_argument('-n', '--node', required=True, help='Proxmox node name')
    parser.add_argument('-t', '--type', choices=['daily', 'weekly', 'monthly'],
                       required=True, help='Snapshot type to create/manage')
    parser.add_argument('-d', '--dry-run', action='store_true',
                       help='Dry run mode (no changes made)')

    args = parser.parse_args()

    config = load_config(args.config)
    manager = ProxmoxSnapshotManager(config, dry_run=args.dry_run)
    manager.run(args.node, args.type)


if __name__ == '__main__':
    main()
