<?php // sources/application.php

$app = require "bootstrap.php";

// GET "/" index 
$app->get('/', function() use ($app) {
    $app['pomm.connection']
        ->executeAnonymousQuery('SELECT true');

    return $app['twig']->render('index.html.twig');
})->bind('index');

return $app;
