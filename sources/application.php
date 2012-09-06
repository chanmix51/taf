<?php // sources/application.php

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\Request;

$app = require "bootstrap.php";

// MIDDLEWARES
$must_be_logged = function() use ($app) {
    if (!$app['request']->request->has('session_token'))
    {
        return $app->redirect($app['url_generator']->generate('homepage'));
    }

    $worker = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\Worker')
        ->findWhere("session_token = ? AND session_start + interval '1800 seconds' > now()", array($app['request']->request->get('session_token')))
        ->current();

    if ($worker === false)
    {
        return $app->redirect($app['url_generator']->generate('homepage'));
    }
};

$must_be_ajax = function() use ($app) {
    if (ENV == 'prod' && !$app['request']->isXmlHttpRequest())
    {
        return new Response("Not found.", 404);
    }
};

// CONTROLLERS

$app->get('/task/{status}/{slug}', function($status, $slug) use ($app) {

    switch($status)
    {
    case "active":
        $model_class = '\Taf\Taf\ActiveTask';
        break;
    case "suspended":
        $model_class = '\Taf\Taf\SuspendedTask';
        break;
    case "finished":
        $model_class = '\Taf\Taf\FinishedTask';
        break;
    default:
        return new Response(sprintf("Unknown status'%s'. Status may be one of 'active', 'suspended' or 'finished'.", $status), 404);
    }

    $task = $app['pomm.connection']
        ->getMapFor($model_class)
        ->findWhere("slug = ?", array($slug))
        ->current();

    if ($task === false)
    {
        return new Response(sprintf("Could not find task with status '%s' and slug '%s'.", $status, $slug), 404);
    }
    else
    {
        return $app->json(array(sprintf('%s_task', $status) => $task->extract()));
    }
})->bind('show')->before($must_be_ajax);

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
})->bind('list')->before($must_be_ajax);

$app->post('/tasks/move', function(Request $request) use ($app) {

    if (!($request->request->has('newRank') and $request->request->has('taskId')))
    {
        return new Response("Expected parameters 'taskId' and 'newRank'.", 400);
    }

    $tasks = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->moveTask($request->request->get('taskId'), $request->request->get('newRank'))
        ;
    if ($tasks->count() == 0)
    {
        return new Response('Error while updating rows.', 500);
    }

    return new Response('ok', 201);
})->bind('task_move')->before($must_be_ajax);

$app->post('/task/{id}/suspend', function($id) use ($app) {
    $suspended_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\SuspendedTask')
        ->suspendTask($id);

    if ($suspended_task === false)
    {
        return new Response(sprintf("No such active task id = '%d'.", $id), 404);
    }

    return $app->json(array('suspended_task' => $suspended_task->extract()));

})->bind('suspend')->before($must_be_ajax);

$app->post('/task/{id}/unsuspend', function($id) use ($app) {
    $active_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->unsuspendTask($id);

    if ($active_task === false)
    {
        return new Response(sprintf("No such suspended task id = '%d'.", $id), 404);
    }

    return $app->json(array('active_task' => $active_task->extract()));

})->bind('unsuspend')->before($must_be_ajax);

$app->post('/task/{id}/finish', function($id) use ($app) {
    $finished_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\FinishedTask')
        ->finishTask($id);

    if ($finished_task === false)
    {
        return new Response(sprintf("No such active task id = '%d'.", $id), 404);
    }

    return $app->json(array('finished_task' => $finished_task->extract()));

})->bind('finish')->before($must_be_ajax);

$app->post('/task/{id}/unfinish', function($id) use ($app) {
    $active_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->unFinishTask($id);

    if ($active_task === false)
    {
        return new Response(sprintf("No such finished task id = '%d'.", $id), 404);
    }

    return $app->json(array('active_task' => $active_task->extract()));

})->bind('unfinish')->before($must_be_ajax);

$app->post('/task/new', function(Request $request) use ($app) {
    try
    {
    $active_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->createAndSaveObject($request->request->get('task'));
    } 
    catch (\Pomm\Exception\Exception $e)
    {
        return new Response('Unable to save new task.', 400);
    }

    return $app->json(array('active_task' => $active_task->extract()));
})->bind('create')->before($must_be_ajax);

$app->put('/task/{id}/add_time', function(Request $request, $id) use ($app) {
    if (!$request->request->has('work_time'))
    {
        return new Response(sprintf("No 'work_time' parameter."), 400);
    }

    $task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->findByPkAndUpdateTime($id, $request->request->get('work_time'));

    if ($task === false)
    {
        return new Response(sprintf("Bad task id = '%d'.", $id), 404);
    }

    return $app->json(array('active_task' => $task->extract()));
})->bind('set_work_time')->before($must_be_ajax);

return $app;
