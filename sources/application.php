<?php // sources/application.php

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\Request;

$app = require "bootstrap.php";

// GET "/" index 
$app->get('/task/{slug}.{ext}', function($slug, $ext) use ($app) {
    $task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->findWhere("slug = ?", array($slug))
        ->current();

    if (!$task)
    {
        return new Response(sprintf("Could not find task with slug '%s'.", $slug), 404);
    }
    else
    {
        return $app['twig']->render('task.html.twig', array('task' => $task));
    }
})->bind('show');

$app->get('/tasks/list', function() use ($app) {
    $data = array();
    $data['active_tasks'] = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->findWhere('true', array(), 'ORDER BY rank DESC LIMIT 25');

    $data['finished_tasks'] = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\FinishedTask')
        ->findWhere('true', array(), 'ORDER BY created_at DESC LIMIT 5');

    $data['suspended_tasks'] = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\SuspendedTask')
        ->findWhere('true', array(), 'ORDER BY created_at DESC LIMIT 5');

    return $app['twig']->render('tasks.html.twig', $data);
})->bind('list');

$app->post('/tasks/move', function(Request $request) use ($app) {
    $tasks = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->moveTask($request->request->get('taskId'), $request->request->get('newRank'))
        ;
    if ($tasks->count() == 0)
    {
        return new Response('Error while updating rows.', 500);
    }

    return new Response('ok', 201);
})->bind('task_move');

return $app;
