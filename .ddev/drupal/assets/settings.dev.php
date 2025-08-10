<?php

use Composer\Semver\Comparator;

/**
 * #ddev-generated
 * Documentation for these can be found on default.settings.php
 * and example.settings.local.php
 */

// This include is only to add php code that would alter the behavior of this
// settings file.
// i.e. $settings_dev_prod = TRUE;
$ddev_local_settings = '/var/www/html/.ddev/drupal/assets/settings.local.php';
if (is_readable($ddev_local_settings)) {
  require $ddev_local_settings;
}

if (!isset($ddev_drupal_production)) {
  $ddev_drupal_production = !empty($_ENV['DDEV_DRUPAL_PRODUCTION']);
}

if (!isset($ddev_drupal_cache_production)) {
  $ddev_drupal_cache_production = !empty($_ENV['DDEV_DRUPAL_CACHE_PRODUCTION']);
}

/**
 * Assertions.
 *
 * The Drupal project primarily uses runtime assertions to enforce the
 * expectations of the API by failing when incorrect calls are made by code
 * under development.
 *
 * @see http://php.net/assert
 * @see https://www.drupal.org/node/2492225
 *
 * It is strongly recommended that you set zend.assertions=1 in the PHP.ini file
 * (It cannot be changed from .htaccess or runtime) on development machines and
 * to 0 or -1 in production.
 */
if (PHP_VERSION_ID < 80300) {
  assert_options(ASSERT_ACTIVE, TRUE);
  assert_options(ASSERT_EXCEPTION, TRUE);
}

// Allow every url
$settings['trusted_host_patterns'] = array(
  '^.*$',
);

$settings['skip_permissions_hardening'] = TRUE;

if (!$ddev_drupal_production) {
  $config['system.performance']['css']['preprocess'] = FALSE;
  $config['system.performance']['js']['preprocess'] = FALSE;
}
// In general this is not used as most devs rely on drush cr and other handy
// ways of rebuilding cache. If needed you can still add it to your
// settings.local.php
// $settings['rebuild_access'] = TRUE;
$settings['extension_discovery_scan_tests'] = TRUE;

// A local dev services.yml file than can be edited as necessary
if (!$ddev_drupal_production && !$ddev_drupal_cache_production) {
  $settings['container_yamls'][] =  '/var/www/html/.ddev/drupal/assets/dev.services.yml';

  // Disabling caches
  $settings['cache']['bins']['render'] = 'cache.backend.null';
  $settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
  $settings['cache']['bins']['page'] = 'cache.backend.null';
}

$config['system.logging']['error_level'] = 'verbose';

// Local hash_salt not to use the same as remote ones.
$settings['hash_salt'] = 'development';

// Allowing insecure derivatives as hash_salt locally is different and content
// in wysiwyg get (like from the insert module) from production would not work
// otherwise.
$config['image.settings']['allow_insecure_derivatives'] = TRUE;

// Set temporary directory within the local filesystem.
// https://www.drupal.org/node/3039255
if (Comparator::lessThan(\Drupal::VERSION, '8.8.0')) {
  $config['system.file']['path']['temporary'] = '/tmp';
}
else {
  $settings['file_temp_path'] = '/tmp';
}

// Easilly accessible local private file system
// We store any potentially public and private path setting stored above this file
// in case we need to reference them next in other settings file inclussions
// (i.e. ddev dev -> project dev -> local)
// While the following sensible default will mostly work, in complex projects
// of with multisite setup we will probably need an extre dev settings file for
// the project.
if (!empty($settings['file_public_path'])) {
  $ddev_drupal_settings_original['file_public_path'] = $settings['file_public_path'];
}
if (!empty($settings['file_private_path'])) {
  $ddev_drupal_settings_original['file_private_path'] = $settings['file_private_path'];
}
$settings['file_public_path'] = 'sites/default/files';
$settings['file_private_path'] = 'sites/default/files/private';

// assumes a config split entity with an id of 'development'
if (!$ddev_drupal_production) {
  $config['config_split.config_split.development']['status'] = TRUE;

  $config['stage_file_proxy.settings']['hotlink'] = TRUE;
  $config['stage_file_proxy.settings']['use_imagecache_root'] = false;
}

// This needs to be set manually on some of your project' settings file.
// $config['stage_file_proxy.settings']['origin'] = 'https://www.example.com';
