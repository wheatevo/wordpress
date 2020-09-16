#!/usr/bin/env bash
set -e

WP_USER="www-data"

# Set default configuration
WORDPRESS_SITE_THEME=${WORDPRESS_SITE_THEME:-twentytwenty-wheatevo}
WORDPRESS_SITE_TAGLINE=${WORDPRESS_SITE_TAGLINE:-variable thoughts}
WORDPRESS_SITE_ICON=${WORDPRESS_SITE_ICON:-/var/www/html/wp-content/themes/twentytwenty-wheatevo/assets/images/icon.png}

# Basic wrapper to run all wp-cli commands as the wordpress user
# Takes one argument containing the comment to execute in wp as the WP_USER (www-data)
function run_wp {
  su -s /bin/bash -c "wp $1" ${WP_USER}
}

# Update Akismet API key
echo "define('WPCOM_API_KEY','${AKISMET_API_KEY}');" >> /var/www/html/wp-settings.php

# Perform initial wordpress install and config
site_flags="--url=${WORDPRESS_SITE_URL} --title=${WORDPRESS_SITE_TITLE}"
admin_flags="--admin_user=${WORDPRESS_ADMIN_USER} --admin_password=${WORDPRESS_ADMIN_PASSWORD} --admin_email=${WORDPRESS_ADMIN_EMAIL}"

run_wp "core install ${site_flags} ${admin_flags} --skip-email"

# Update plugins
run_wp 'plugin delete hello'
run_wp 'plugin activate akismet'
run_wp 'plugin install code-syntax-block'
run_wp 'plugin activate code-syntax-block'

# Manage themes
run_wp "theme activate ${WORDPRESS_SITE_THEME}"

# Delete unused themes
unused_themes=$(run_wp 'theme list --field=name --status=inactive')
for theme in ${unused_themes}
do
  run_wp "theme delete ${theme}"
done

# Remove default widgets
sidebars=$(run_wp "sidebar list --format=ids")
for sidebar in ${sidebars}
do
  widgets=$(run_wp "widget list --format=ids ${sidebar}")
  for widget in ${widgets}
  do
    run_wp "widget delete ${widget}"
  done
done

# Remove default posts and pages
default_post_ids=$(run_wp "post list --format=ids")
for post_id in ${default_post_ids}
do
  run_wp "post delete ${post_id} --force"
done

default_page_ids=$(run_wp "post list --post_type=page --format=ids")
for post_id in ${default_page_ids}
do
  run_wp "post delete ${post_id} --force"
done 

# Update theme with tagline and default color scheme
run_wp "option update blogdescription '${WORDPRESS_SITE_TAGLINE}'"
run_wp "theme mod set background_color ffffff"
run_wp "theme mod set header_footer_background_color 1e73be"
run_wp "theme mod set accent_hue_active custom"
run_wp "theme mod set accent_hue 208"
content_color_json='{"text":"#000000","accent":"#0577da","background":"#ffffff","borders":"#dbdbdb","secondary":"#6d6d6d"}'
header_footer_color_json='{"text":"#ffffff","accent":"#f2f6fc","background":"#1e73be","borders":"#2a8adf","secondary":"#ffffff"}'
accessible_color_json="{\"content\":${content_color_json},\"header-footer\":${header_footer_color_json}}"
run_wp "option patch insert theme_mods_twentytwenty-wheatevo accent_accessible_colors '${accessible_color_json}' --format=json"

# Update favicon
run_wp "media import ${WORDPRESS_SITE_ICON} --title=favicon"
run_wp "option update site_icon $(run_wp "post list --post_type=attachment --post_title=favicon --format=ids")"

# Update menu with GitHub link
run_wp "menu create 'Social Menu'"
run_wp "menu item add-custom social-menu GitHub 'https://github.com/wheatevo'"
run_wp "menu item add-custom social-menu LinkedIn 'https://www.linkedin.com/in/matthew-n-2253171a2'"
run_wp "menu location assign social-menu social"

# Other settings
run_wp "option update permalink_structure /%postname%/"
