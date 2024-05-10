<?php
#ddev-generated

/**
 * To use this, simply add the following to your main settings.php on your
 * project, following you added this project to your platform build
 * as per the main README.md.
 *
 * if (empty($_ENV['PLATFORMSH_RECIPES_INSTALLDIR'])) {
 *   $platformsh_recipes_settings = $_ENV['PLATFORMSH_RECIPES_INSTALLDIR'] . '/platformsh-recipes/assets/drupal/settings.platformsh-recipes.php';
 *   if (file_exists($platformsh_recipes_settings)) {
 *     include $platformsh_recipes_settings;
 *   }
 * }
 *
 */

// If the enviornment variable is set, we are sending a 503 right away
// but allow drush to still work. This is for heavy maintenance like a db
// migration or something like that.
// @TODO: Accompanyinig helper ahoy commands
if (PHP_SAPI !== 'cli' && !empty($_ENV['o'])) {
  header('HTTP/1.1 503 Service Unavailable');
  header('Retry-After: 300');
  header('Content-Type: text/html');
  echo '<html><body><h1>Service Unavailable</h1><p>Our site is currently down for maintenance. Please try again in a few minutes.</p></body></html>';
  die();
}
