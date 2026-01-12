#!/bin/bash
# Nextcloud Performance Monitor
# Usage: ./nc_performance_monitor.sh [prod|test]
#
# Configuration: Set these variables in a separate config file or environment
# Required variables:
#   - PROD_HOST: Production Nextcloud hostname
#   - PROD_URL: Production Nextcloud URL
#   - PROD_DB: Production database name
#   - TEST_HOST: Test Nextcloud hostname
#   - TEST_URL: Test Nextcloud URL
#   - TEST_DB: Test database name
#   - SSH_USER: SSH username (default: ansible)

# Load configuration from environment or config file
CONFIG_FILE="${NC_PERF_CONFIG:-$HOME/.config/nc_performance.conf}"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Defaults
SSH_USER="${SSH_USER:-ansible}"
TARGET=${1:-prod}

if [ "$TARGET" = "prod" ]; then
    HOST="${PROD_HOST:?Error: PROD_HOST not set}"
    URL="${PROD_URL:?Error: PROD_URL not set}"
    DB="${PROD_DB:?Error: PROD_DB not set}"
elif [ "$TARGET" = "test" ]; then
    HOST="${TEST_HOST:?Error: TEST_HOST not set}"
    URL="${TEST_URL:?Error: TEST_URL not set}"
    DB="${TEST_DB:?Error: TEST_DB not set}"
else
    echo "Usage: $0 [prod|test]"
    echo ""
    echo "Configuration required in $CONFIG_FILE:"
    echo "  PROD_HOST=your.production.host"
    echo "  PROD_URL=https://your.production.url"
    echo "  PROD_DB=production_db_name"
    echo "  TEST_HOST=your.test.host"
    echo "  TEST_URL=https://your.test.url"
    echo "  TEST_DB=test_db_name"
    echo "  SSH_USER=ansible"
    exit 1
fi

echo "=== Nextcloud Performance Monitor: $TARGET ==="
echo "Time: $(date)"
echo ""

# 1. Response time
echo "1. Response Time Test:"
curl -w "   Status: %{http_code}\n   Total time: %{time_total}s\n   TTFB: %{time_starttransfer}s\n" \
     -o /dev/null -s "$URL/status.php"

# 2. System load
echo ""
echo "2. Server Load:"
ssh ${SSH_USER}@${HOST} 'echo "   Load: $(uptime | awk -F"load average:" "{print \$2}")"'
ssh ${SSH_USER}@${HOST} 'echo "   Memory: $(free -h | grep Mem | awk "{print \$3 \"/\" \$2 \" used\"}")"'

# 3. PHP-FPM
echo ""
echo "3. PHP-FPM Status:"
ssh ${SSH_USER}@${HOST} 'systemctl status php8.2-fpm --no-pager -l | grep -E "Active|Status|Memory|CPU" | sed "s/^/   /"'

# 4. Redis
echo ""
echo "4. Redis Performance:"
ssh ${SSH_USER}@${HOST} 'redis-cli INFO stats | grep -E "instantaneous_ops" | sed "s/^/   /"'

# 5. Database
echo ""
echo "5. Database Stats:"
ssh ${SSH_USER}@${HOST} "sudo -u postgres psql -d ${DB} -t -c \"SELECT 'Files: ' || count(*) FROM oc_filecache;\" | sed 's/^/   /'"
ssh ${SSH_USER}@${HOST} "sudo -u postgres psql -d ${DB} -t -c \"SELECT 'Active connections: ' || count(*) FROM pg_stat_activity WHERE state = 'active';\" | sed 's/^/   /'"

# 6. OCC status
echo ""
echo "6. Nextcloud Status:"
ssh ${SSH_USER}@${HOST} 'sudo -u www-data php /var/www/nextcloud/occ status --no-warnings | grep -E "installed|version|maintenance" | sed "s/^/   /"'

echo ""
echo "=== Performance Test Complete ==="
