#!/bin/bash
# Uses db connection crednetials in .dpd_env

source /home/dbuijs/dpd_tools/.dpd_env

# grab latest status that 's int eh past from remote
remote_last_update=$( psql -d dpd -t -c "select to_char(max(history_date), 'YYYYMMDD') from remote.wqry_status where history_date <= now()")

current_last_refresh=$( psql -d dpd -t -c"select to_char(max(history_date), 'YYYYMMDD') from dpd_current.status where history_date <= now()")

echo "Max history_date on remote is"  $remote_last_update
echo "Max history_date on current is"  $current_last_refresh

if [[ "$remote_last_update" -gt  "$current_last_refresh" ]]; then
        echo "Remote is more recent than current. Refresh required!"
        psql -f /home/dbuijs/dpd/dpd_refresh.sql
else
        echo "Remote and current are up to date!"
fi
