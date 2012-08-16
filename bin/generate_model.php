
<?php // bin/generate_model.php

$app = require(__DIR__."/../sources/bootstrap.php");

$scan = new Pomm\Tools\ScanSchemaTool(array(
    'schema' => $argv[1],
    'database' => $app['pomm']->getDatabase(),
    'prefix_dir' => PROJECT_DIR."/sources/model",
    ));
$scan->execute();
$scan->getOutputStack()->setLevel(\Pomm\Tools\OutputLine::LEVEL_INFO);

foreach ( $scan->getOutputStack() as $line )
{
    printf("%s\n", $line);
}

