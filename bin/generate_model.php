<?php // bin/generate_model.php

use \Pomm\Tools\OutputLine;

$app = require(__DIR__."/../sources/bootstrap.php");

$scan = new Pomm\Tools\ScanSchemaTool(array(
    'schema' => $argv[1],
    'database' => $app['pomm']->getDatabase(),
    'prefix_dir' => PROJECT_DIR."/sources/model",
    'exclude' => array('deploys', 'view_functions'),
    'extends' => '\Taf\BaseMap',
    ));
$scan->execute();
$scan->getOutputStack()->setLevel(255);

foreach ( $scan->getOutputStack() as $line )
{
    printf("%s\n", $line);
}

