#!/bin/bash
# Exits 1 (build FAILED) if a check fails, 0 (build SUCCESS) if all pass.
URL=${1:-http://localhost:8080/login}

echo "===== Health Check v3 ====="
echo "Host: $(hostname)"
echo "Date: $(date)"

# Check 1: disk usage below 90%
DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
echo "Disk used: ${DISK}%"
[ "$DISK" -lt 90 ] || { echo "Status: UNHEALTHY (disk above 90%)"; exit 1; }

# Check 2: service answers with HTTP 200
CODE=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
echo "HTTP $URL -> $CODE"
[ "$CODE" = 200 ] || { echo "Status: UNHEALTHY (service not responding)"; exit 1; }

echo "Status: HEALTHY"
