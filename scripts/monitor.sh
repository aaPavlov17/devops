#!/usr/bin/env bash

service_name="${1:-}"

if systemctl is-active --quiet "$service_name"; then
    echo "Служба $service_name работает"
else
    echo "Служба $service_name не активна или не найдена"
    journalctl -u "$service_name" -n 10 --no-pager
fi

log_file="/var/log/syslog"

if [[ ! -r "$log_file" ]]; then
    exit 1
fi

error_count=$(grep -i 'error' "$log_file" | awk '
BEGIN {
    split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", names, " ")
    for (i = 1; i <= 12; i++) month[names[i]] = i

    now = systime()
    year = strftime("%Y", now)
}
!($1 in month) { next }
{
    split($3, t, ":")
    fields = month[$1] " " $2 " " t[1] " " t[2] " " t[3]
    timestamp = mktime(year " " fields)

    if (timestamp > now)
        timestamp = mktime((year - 1) " " fields)

    if (timestamp >= now - 3600 && timestamp <= now)
        count++
}
END { print count + 0 }
')

echo "Строк с error за последний час: $error_count"