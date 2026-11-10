# System Health Monitor (Bash)

Checks CPU load, memory, disk usage, one service, network (IP, ping, DNS, HTTPS), and scans a log file for errors.
Writes timestamped results to `~/health_report.log`.

## Run
    ./health_check.sh                 # defaults: service "ssh", log /var/log/syslog
    ./health_check.sh nginx /var/log/nginx/error.log

## Schedule (every 15 minutes)
    crontab -e
    */15 * * * * /full/path/health_check.sh >/dev/null 2>&1

## Thresholds
Edit `DISK_LIMIT` and `ERROR_LIMIT` at the top of the script.

## Tested on
Linux (Ubuntu / WSL)
