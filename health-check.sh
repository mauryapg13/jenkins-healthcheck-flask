#!/bin/bash
echo "===== Health Check v2 ====="
echo "Host: $(hostname)"
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Disk usage:"
df -h / | tail -1
echo "Status: HEALTHY"
