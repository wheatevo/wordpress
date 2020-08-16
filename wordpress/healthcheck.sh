#!/usr/bin/env bash
set -e

INIT_STATUS_FILE='/root/.initial_build_complete'

# Health check (ensure port 9000 is listening locally and port 3306 is listening on mysql)
cat < /dev/null > /dev/tcp/localhost/9000 || exit 1
cat < /dev/null > /dev/tcp/db/3306 || exit 1

# Exit with success if the status file exists
if [[ -f ${INIT_STATUS_FILE} ]];then
  exit 0
fi

# Update status file to prevent healthchecks from retrying initialization
touch ${INIT_STATUS_FILE}

# Perform initialization
/root/first_run.sh > /root/first_run.log 2>&1
