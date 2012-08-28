<?php // sources/application.php

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\Request;

$app = require "bootstrap.php";

// GET "/" index 
$app->get('/task/{slug}.{ext}', function($slug, $ext) use ($app) {
    if ( ! in_array($ext, array('html', 'json', 'xml')) )
    {
        return new Response(sprintf("No such format '%s' (valid formats are html, json, xml.", $ext), 404);
    }

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
        return $app['twig']->render(sprintf('task.%s.twig', $ext), array('task' => $task));
    }
})->bind('show');

$app->get('/', function() use ($app) {
})->bind('homepage');

$app->get('/tasks/list', function(Request $request) use ($app) {
    $data = array();

    if (!$request->query->has('status') || $request->query->get('status') == 'active')
    {
        $data = array_merge($data, $app['pomm.connection']
            ->getMapFor('\Taf\Taf\ActiveTask')
            ->findAll('ORDER BY rank DESC LIMIT 25')
            ->extract('active_tasks'));
    }

    if (!$request->query->has('status') || $request->query->get('status') == 'finished')
    {
         $data = array_merge($data, $app['pomm.connection']
            ->getMapFor('\Taf\Taf\FinishedTask')
            ->findAll('ORDER BY created_at DESC LIMIT 5')
            ->extract('finished_tasks'));
    }

    if (!$request->query->has('status') || $request->query->get('status') == 'suspended')
    {
        $data = array_merge($data, $app['pomm.connection']
            ->getMapFor('\Taf\Taf\SuspendedTask')
            ->findAll('ORDER BY created_at DESC LIMIT 5')
            ->extract('suspended_tasks'));
    }

    return $app->json($data);
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

$app->post('/task/{id}/suspend', function($id) use ($app) {
    $suspended_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\SuspendedTask')
        ->suspendTask($id);

    if ($suspended_task === false)
    {
        return new Response(sprintf("No such active task id = '%d'.", $id), 404);
    }

    return $app->json(array('suspended_task' => $suspended_task->extract()));

})->bind('suspend');

$app->post('/task/{id}/unsuspend', function($id) use ($app) {
    $active_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->unsuspendTask($id);

    if ($active_task === false)
    {
        return new Response(sprintf("No such suspended task id = '%d'.", $id), 404);
    }

    return $app->json(array('active_task' => $active_task->extract()));

})->bind('unsuspend');

$app->post('/task/{id}/finish', function($id) use ($app) {
    $finished_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\FinishedTask')
        ->finishTask($id);

    if ($finished_task === false)
    {
        return new Response(sprintf("No such active task id = '%d'.", $id), 404);
    }

    return $app->json(array('finished_task' => $finished_task->extract()));

})->bind('finish');

$app->post('/task/{id}/unfinish', function($id) use ($app) {
    $active_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->unFinishTask($id);

    if ($active_task === false)
    {
        return new Response(sprintf("No such finished task id = '%d'.", $id), 404);
    }

    return $app->json(array('active_task' => $active_task->extract()));

})->bind('unfinish');

return $app;
