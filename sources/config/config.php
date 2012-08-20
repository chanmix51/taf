<?php // sources/config/config.php.dist

// This file should be copied as config.php in the config directory and filled
// with your configuration parameters.

// pomm database configuration
$app['config.pomm.dsn'] = array(
    'prod' => array(), 
    'cli' => array('my_db' => array('dsn' => 'pgsql://dumb_user@!/var/lib/lxc/java/rootfs/tmp!/dumb_db')),
    'dev' => array('my_db' => array('dsn' => 'pgsql://dumb_user@172.17.0.3:5432/dumb_db')),
);

// put your configuration here

