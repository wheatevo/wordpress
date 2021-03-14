#!/bin/bash

backup_file="wheatevo-wp-$(date '+%Y-%m-%d').tar.gz"

# Create all necessary backup directories and clean any existing files
echo "Creating backup staging directories..."
mkdir -p backup/staging/wordpress
mkdir -p backup/staging/db
rm -f backup/staging/db/*
rm -rf backup/staging/wordpress/*

echo "Backing up Wordpress database..."
docker-compose exec db sh -c 'mysqldump -u root -p${MYSQL_ROOT_PASSWORD} --databases ${WORDPRESS_DB_NAME} > /var/backup/${WORDPRESS_DB_NAME}_backup.sql'

echo "Backing up Wordpress configuration and uploads..."
docker-compose exec wordpress sh -c 'cp /var/www/html/.htaccess /var/backup/; cp /var/www/html/wp-config.php /var/backup/; cp -r /var/www/html/wp-content /var/backup/'

echo "Creating backup archive at ${backup_file}..."
cd backup/staging
tar -zcvf "${backup_file}" *
mv *.tar.gz ../
cd ../..

echo "Cleaning up staged backup data..."
rm -f backup/staging/db/*
rm -rf backup/staging/wordpress/*
