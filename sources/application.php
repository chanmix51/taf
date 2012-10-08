<?php // sources/application.php

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\Request;

$app = require "bootstrap.php";

// MIDDLEWARES
$must_be_logged = function() use ($app) {
    $worker_map = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\Worker');

    if ($app['session']->has('auth_token'))
    {
        $worker = $worker_map->findByPk(array('worker_id' => $app['session']->get('auth_token')));

        if ($worker)
        {
            $app['worker'] = $worker;

            return;
        }
    }

    $auth = new \Hybrid_Auth(array(
        "base_url" => "http://taf.perso.localhost/hybridauth/index.php",
        "providers" => array ("OpenID" => array("enabled" => true, "required" => array("email")))
    ));

    $auth_data = @$auth->authenticate( "OpenID", array( "openid_identifier" => "https://www.google.com/accounts/o8/id"));

    $worker = $worker_map->findWhere('email = ?', array($auth_data->getUserProfile()->email))->current();

    if (!$worker)
    {
        $worker = $worker_map->createAndSaveObject(array('email' => $auth_data->getUserProfile()->email, 'extra_data' => (Array) $auth_data->getUserProfile()));
    }
    else
    {
        $worker['extra_data'] = (array) $auth_data->getUserProfile();
        $worker_map->updateOne($worker, array('extra_data'));
    }

    $app['worker'] = $worker;
    $app['session']->set('token', $worker['worker_id']);


    return;
};

$must_be_ajax = function() use ($app) {
    if (ENV == 'prod' && !$app['request']->isXmlHttpRequest())
    {
        return new Response("Not found.", 404);
    }
};

// CONTROLLERS

/**
 * main homepage
 * @authenticated
 **/
$app->get('/', function() use ($app) {
    return $app['twig']->render('tasks.html.twig');
})->bind('homepage')->before($must_be_logged);

/**
 * Get a task static read only page per slug
 **/
$app->get('/tasks/{slug}', function($slug) use ($app) {

    $task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\Task')
        ->findBySlug($slug);

    if ($task === false)
    {
        return new Response(sprintf("Could not find task with slug '%s'.", $slug), 404);
    }
    else
    {
        return $app->json(array(sprintf('%s', get_class($task)) => $task->extract()));
    }
})->bind('show')->before($must_be_ajax);

/**
 * get all tasks
 * @ajax
 **/
$app->get('/tasks', function(Request $request) use ($app) {
    $data = array();

    if (!$request->query->has('status') || $request->query->get('status') == 'active')
    {
        $data = array_merge($data, $app['pomm.connection']
            ->getMapFor('\Taf\Taf\ActiveTask')
            ->findAll('ORDER BY rank DESC LIMIT 12')
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

/**
 * move a task
 * @ajax
 **/
$app->put('/tasks/{id}/move', function($id, Request $request) use ($app) {

    if (!($request->request->has('newRank')))
    {
        return new Response("Expected parameters 'newRank'.", 400);
    }

    $task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->moveTask($id, $request->request->get('newRank'))
        ;
    if (!$task)
    {
        return new Response(sprintf("Unknown task id = '%d'.", $id), 404);
    }

    return new Response($app->json($task->extract()));
})->bind('task_move')->before($must_be_ajax);

/**
 * suspend a task
 * @ajax
 **/
$app->post('/tasks/{id}/suspend', function($id) use ($app) {
    $suspended_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\SuspendedTask')
        ->suspendTask($id);

    if ($suspended_task === false)
    {
        return new Response(sprintf("No such active task id = '%d'.", $id), 404);
    }

    return $app->json(array('suspended_task' => $suspended_task->extract()));

})->bind('suspend')->before($must_be_ajax);

/**
 * unsuspend a task
 * @ajax
 **/
$app->post('/tasks/{id}/unsuspend', function($id) use ($app) {
    $active_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->unsuspendTask($id, $app['request']->query->get('rank'));

    if ($active_task === false)
    {
        return new Response(sprintf("No such suspended task id = '%d'.", $id), 404);
    }

    return $app->json(array('active_task' => $active_task->extract()));

})->bind('unsuspend')->before($must_be_ajax);

/**
 * finish a task
 * @ajax
 **/
$app->post('/tasks/{id}/finish', function($id) use ($app) {
    $finished_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\FinishedTask')
        ->finishTask($id);

    if ($finished_task === false)
    {
        return new Response(sprintf("No such active task id = '%d'.", $id), 404);
    }

    return $app->json(array('finished_task' => $finished_task->extract()));

})->bind('finish')->before($must_be_ajax);

/**
 * unfinish a task
 * @ajax
 **/
$app->post('/tasks/{id}/unfinish', function($id) use ($app) {
    $active_task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->unFinishTask($id, $app['request']->query->get('rank'));

    if ($active_task === false)
    {
        return new Response(sprintf("No such finished task id = '%d'.", $id), 404);
    }

    return $app->json(array('active_task' => $active_task->extract()));

})->bind('unfinish')->before($must_be_ajax);

/**
 * Create a task
 * @ajax
 **/
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

/**
 * Add time spent on a task
 * @ajax
 **/
$app->put('/task/{id}/add_time', function(Request $request, $id) use ($app) {
    if (!$request->request->has('work_time'))
    {
        return new Response(sprintf("No 'work_time' parameter."), 400);
    }

    $task = $app['pomm.connection']
        ->getMapFor('\Taf\Taf\ActiveTask')
        ->updateByPk(
            array('task_id' => $id),
            array('work_time' => $request->request->get('work_time'))
        );

    if ($task === false)
    {
        return new Response(sprintf("Bad task id = '%d'.", $id), 404);
    }

    return $app->json(array('active_task' => $task->extract()));
})->bind('set_work_time')->before($must_be_ajax);

/**
 * logout
 **/
$app->get('/logout', function() use ($app) {
    $app['session']->remove('token');
    $auth = new \Hybrid_Auth(array(
        "base_url" => "http://taf.perso.localhost/hybridauth/index.php",
        "providers" => array ("OpenID" => array("enabled" => true, "required" => array("email")))
    ));

    $auth->logoutAllProviders();

    return $app->redirect($app['url_generator']->generate('homepage'));
})->bind('logout');

return $app;
