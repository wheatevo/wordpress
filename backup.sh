#!/bin/bash

# Simple wordpress backup script
# This should be set to run at least daily in cron

# To sync to B2, run the following in cron as well:
# /usr/local/bin/b2 sync --excludeRegex 'staging|.*\.log' --delete "/opt/web/wordpress/backup" "b2://bucket-name/node/wordpress" >> /opt/web/wordpress/backup/sync.log 2>&1

echo "Starting backup at $(date)"

backup_file="wheatevo-wp-$(date '+%Y-%m-%d').tar.gz"
days_to_keep="90"

# Create all necessary backup directories and clean any existing files
echo "Creating backup staging directories..."
mkdir -p backup/staging/wordpress
mkdir -p backup/staging/db
rm -f backup/staging/db/*
rm -rf backup/staging/wordpress/*

echo "Backing up Wordpress database..."
docker-compose exec -T db sh -c 'mysqldump -u root -p${MYSQL_ROOT_PASSWORD} --databases ${WORDPRESS_DB_NAME} > /var/backup/${WORDPRESS_DB_NAME}_backup.sql'

echo "Backing up Wordpress configuration and uploads..."
docker-compose exec -T wordpress sh -c 'cp /var/www/html/.htaccess /var/backup/; cp /var/www/html/wp-config.php /var/backup/; cp -r /var/www/html/wp-content /var/backup/'

echo "Creating backup archive at ${backup_file}..."
cd backup/staging
tar -zcvf "${backup_file}" * > /dev/null 2>&1
mv *.tar.gz ../
cd ../..

echo "Cleaning up staged backup data..."
rm -f backup/staging/db/*
rm -rf backup/staging/wordpress/*

echo "Deleting old backups..."
find backup -type f -name '*.tar.gz' -mtime +${days_to_keep} -exec rm {} \;

echo "Backup Complete"
echo ""
echo ""
