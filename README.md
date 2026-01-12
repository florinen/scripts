# Common Scripts

A collection of automation scripts for infrastructure management, backups, and monitoring.

## 📁 Repository Structure

### `nc_backup/` - Nextcloud Management
Scripts for Nextcloud backup, upgrade, and performance monitoring:
- **nc_performance_monitor.sh** - Monitor Nextcloud performance metrics (response time, load, PHP-FPM, Redis, database)
- **backup_cloud.sh** - Automated Nextcloud backup script
- **upgrade_nc.sh** - Nextcloud upgrade automation
- **cloud_upgrade.sh** - Cloud instance upgrade utilities
- **db_missing_objects.sh** - Database integrity checker

### `pfSense/` - pfSense Firewall Management
Scripts for managing pfSense firewall and network monitoring:
- **ping-check.sh** - Network connectivity monitoring
- **int_check.sh** - Interface status checker
- **install_pfsense_package.py** - Automated package installation

### `proxmox-snapshots/` - Proxmox VE Management
- **pve_snapshot_manager.py** - Automated snapshot management for Proxmox VE

### `UniFi-controller/` - UniFi Network Management
- **unifi-update.sh** - UniFi Controller update automation

### `aws/` - AWS Utilities
- **rotate.sh** - Credential rotation scripts
- **aws_iam_get_user.sh** - IAM user management utilities

### `terraform/` - Terraform Helpers
- **vsphere-set-env.sh** - vSphere environment configuration

### `vSphere/` - VMware vSphere Scripts
VMware vSphere automation and management scripts

### `utile/` - General Utilities
Miscellaneous utility scripts:
- **get-kubectl.sh** - Kubernetes kubectl installer
- **get-helm.sh** - Helm chart manager installer
- **get-kops.sh** - Kubernetes kops installer
- **get-terraform.sh** - Terraform installer
- **get_docker_version.sh** - Docker version checker
- **workflow_del.sh** - Workflow deletion utilities
- **millenia.py** - Date/time utilities

## 🔧 Configuration

Many scripts require configuration files to avoid committing sensitive data:

### Nextcloud Performance Monitor
Create `~/.config/nc_performance.conf`:
```bash
PROD_HOST="your.production.host"
PROD_URL="https://your.production.url"
PROD_DB="production_db_name"
TEST_HOST="your.test.host"
TEST_URL="https://your.test.url"
TEST_DB="test_db_name"
SSH_USER="ansible"
```

See individual script directories for specific configuration requirements.

## 🔒 Security

- Configuration files with sensitive data are git-ignored
- SSH keys should be properly secured
- Credentials should never be hardcoded
- Use environment variables or config files for secrets

## 📝 Usage

Each directory contains scripts with specific purposes. Refer to individual README files in subdirectories for detailed usage instructions.

## 🤝 Contributing

When adding new scripts:
1. Follow existing naming conventions
2. Add documentation/comments
3. Never commit sensitive data
4. Update this README with new script descriptions
5. Use configuration files for environment-specific settings