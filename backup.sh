#!/bin/bash

# Simple wordpress backup script
# This should be set to run at least daily in cron

# To sync to B2, run the following in cron as well:
# /usr/local/bin/b2 sync --excludeRegex 'staging|.*\.log' --delete "/opt/web/wordpress/backup" "b2://bucket-name/node/wordpress" >> /opt/web/wordpress/backup/sync.log 2>&1

echo "Starting backup at $(date)"

encrypt=0
backup_file="wheatevo-wp-$(date '+%Y-%m-%d').tar.gz"
days_to_keep="90"

if [[ -f .wp_enc_key ]];then
  echo "Encryption key found, going to encrypt the backup..."
  encrypt=1
else
  echo "Encryption key not found, skipping backup encryption..."
fi

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

# If a key file exists, use it

if [[ $encrypt -eq 1 ]];then
  # decrypt and restore with:
  # openssl enc -d -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -pass file:.wp_enc_key -in ${backup_file} | tar -zxvf - -C restore_dir
  tar -zcvf - * | openssl enc -e -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -pass file:../../.wp_enc_key -out "${backup_file}"
else
  tar -zcvf "${backup_file}" *
fi

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
