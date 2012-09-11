<?php

namespace Taf\Taf\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class FinishedTaskMap extends \Taf\Taf\TaskMap
{
    public function initialize()
    {
        parent::initialize();

        $this->object_class =  'Taf\Taf\FinishedTask';
        $this->object_name  =  'taf.finished_task';

        $this->addField('block_stack', 'json');

        $this->pk_fields = array('task_id');
    }
}