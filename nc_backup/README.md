# Nextcloud Performance Monitor

A script to monitor and test Nextcloud instance performance.

## Features

- Response time testing
- System load monitoring
- PHP-FPM status
- Redis performance metrics
- Database statistics
- Nextcloud version and status

## Configuration

Create a configuration file at `~/.config/nc_performance.conf`:

```bash
# Production Nextcloud
PROD_HOST="your.production.host"
PROD_URL="https://your.production.url"
PROD_DB="production_db_name"

# Test Nextcloud
TEST_HOST="your.test.host"
TEST_URL="https://your.test.url"
TEST_DB="test_db_name"

# SSH Configuration
SSH_USER="ansible"
```

**Important:** This configuration file contains sensitive information and should NOT be committed to version control. It's already excluded via `.gitignore`.

## Usage

Test production instance:
```bash
./nc_performance_monitor.sh production
```

Test development/staging instance:
```bash
./nc_performance_monitor.sh test
```

## Requirements

- SSH access to Nextcloud server
- `curl` for HTTP testing
- `ssh` with key-based authentication
- PostgreSQL (or adjust for MySQL/MariaDB)
- Redis (optional, comment out if not used)

## Security

- Configuration file uses restrictive permissions (600)
- No sensitive data is hardcoded in the script
- Configuration file is git-ignored
- All connections use SSH with key authentication

## Output

The script provides comprehensive performance metrics including:
- HTTP response times (total, TTFB)
- Server load averages
- Memory usage
- PHP-FPM process status
- Redis operations per second
- Database file count and active connections
- Nextcloud installation status
