<?php #sources/bootstrap.php

// This script sets up the application DI with services.

define('PROJECT_DIR', dirname(__DIR__));

require PROJECT_DIR.'/sources/config/environment.php';

// autoloader
$loader = require PROJECT_DIR.'/vendor/autoload.php';
$loader->add('Taf', PROJECT_DIR.'/sources/model');

$app = new Silex\Application();

// configuration parameters
if (!file_exists(PROJECT_DIR.'/sources/config/config.php')) {
    throw new \RunTimeException("No config.php found in config.");
}

require PROJECT_DIR.'/sources/config/config.php';

// extensions registration

use Silex\Provider;

$app->register(new Provider\UrlGeneratorServiceProvider());
$app->register(new Provider\SessionServiceProvider());
$app->register(new Provider\TwigServiceProvider(), array(
    'twig.path' => array(PROJECT_DIR.'/sources/twig'),
));
$app->register(new Pomm\Silex\PommServiceProvider(), array(
    'pomm.databases' => $app['config.pomm.dsn'][ENV]
));

// Service container customization. 
$app['loader'] = $loader;
$app['pomm.connection'] = $app['pomm']
    ->getDatabase()
    ->registerTypeForConverter('taf.email_address', 'String')
    ->createConnection();

// set DEBUG mode or not
if (preg_match('/^dev/', ENV))
{
    $app['debug'] = true;
    $app['pomm.logger'] = $app->share(function() { return new Pomm\Tools\Logger(); });
    $app['pomm.connection']
        ->registerFilter(new Pomm\FilterChain\LoggerFilter($app['pomm.logger']));
}

return $app;
