<?php

$app = require(__DIR__."/../sources/bootstrap.php");

function help()
{
    printf("Get the stored procedures source code.\n");
    printf("Usage:\n");
    printf("show_sp_source schema name\n");
    printf("\nname is the stored procedure's name.\n");
    printf("schema is the database schema.\n");
    printf("environment set the database connection that will be used (default: dev).\n");
    exit(1);
}

if (PHP_SAPI !== 'cli') {
    throw new \Exception("This is a CLI tool that therefor needs to be launched in a terminal.");
}

if (count($argv) < 3 or ! preg_match("/^[a-z0-9_]+$/", $argv[1])) {
    help();
}

$inspector = new Pomm\Tools\Inspector($app['pomm.connection']);

foreach($inspector->getStoredProcedureSource($argv[1], $argv[2]) as $source)
{
    printf("==========\n%s\n============\n", $source);
}
