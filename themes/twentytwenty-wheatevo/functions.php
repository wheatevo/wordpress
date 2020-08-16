<?php

add_action( 'wp_enqueue_scripts', 'twentytwenty_wheatevo_enqueue_parent_styles' );

function twentytwenty_wheatevo_enqueue_parent_styles() {
  wp_enqueue_style( 'parent-style', get_template_directory_uri().'/style.css' );
}

add_action( 'enqueue_block_editor_assets', 'twentytwenty_wheatevo_block_editor_styles' );

function twentytwenty_wheatevo_block_editor_styles() {
  wp_enqueue_style( 'twentytwenty_wheatevo_block_editor_styles', get_theme_file_uri( 'assets/css/editor-style-block.css' ), false, wp_get_theme()->get( 'Version' ), 'all' );
}

