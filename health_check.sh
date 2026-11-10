#!/usr/bin/env bash
# System health check + log scanner. Run manually or from cron.
# Usage: ./health_check.sh [service_name] [log_file]

SERVICE="${1:-ssh}"                  # service/process to check
LOGFILE="${2:-/var/log/syslog}"      # log file to scan
REPORT="$HOME/health_report.log"     # where results are saved
DISK_LIMIT=80                        # alert if disk use % is above this
ERROR_LIMIT=10                       # alert if ERROR lines exceed this

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "$(ts) $1" | tee -a "$REPORT"; }

# 1. CPU load (1-minute average)
log "INFO  load average: $(cut -d' ' -f1 /proc/loadavg)"

# 2. Memory usage
mem=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
log "INFO  memory used: ${mem}%"

# 3. Disk usage on /
disk=$(df / | awk 'NR==2 {gsub("%",""); print $5}')
if [ "$disk" -gt "$DISK_LIMIT" ]; then
  log "ALERT disk usage ${disk}% exceeds ${DISK_LIMIT}%"
else
  log "INFO  disk used: ${disk}%"
fi

# 4. Service / process check
if pgrep -x "$SERVICE" > /dev/null; then
  log "INFO  $SERVICE is running"
else
  log "ALERT $SERVICE is NOT running"
fi

# 5. Log scan: count ERROR lines
if [ -r "$LOGFILE" ]; then
  errors=$(grep -ci "error" "$LOGFILE")
  if [ "$errors" -gt "$ERROR_LIMIT" ]; then
    log "ALERT $errors error lines in $LOGFILE (limit $ERROR_LIMIT)"
  else
    log "INFO  $errors error lines in $LOGFILE"
  fi
else
  log "WARN  cannot read $LOGFILE"
fi

# 6. Network checks: IP, connectivity, DNS, HTTP
ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}')
log "INFO  IP address: ${ip_addr:-none}"

if ping -c1 -W2 8.8.8.8 > /dev/null 2>&1; then
  log "INFO  internet reachable (ping 8.8.8.8)"
else
  log "ALERT cannot reach 8.8.8.8 (IP connectivity)"
fi

if getent hosts example.com > /dev/null 2>&1; then
  log "INFO  DNS resolves example.com"
else
  log "ALERT DNS lookup failed for example.com"
fi

code=$(curl -s -o /dev/null -m 5 -w '%{http_code}' https://example.com 2>/dev/null)
if [ "$code" = "200" ]; then
  log "INFO  HTTPS check OK (status 200)"
else
  log "ALERT HTTPS check failed (status ${code:-none})"
fi
