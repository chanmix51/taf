<?php

namespace Taf\Taf\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class TaskMap extends \Taf\BaseMap
{
    public function initialize()
    {

        $this->object_class =  'Taf\Taf\Task';
        $this->object_name  =  'taf.task';

        $this->addField('task_id', 'int4');
        $this->addField('title', 'varchar');
        $this->addField('slug', 'varchar');
        $this->addField('work_time', 'int4');
        $this->addField('created_at', 'timestamp');
        $this->addField('worker_id', 'int4');
        $this->addField('block_stack', 'json');

        $this->pk_fields = array('task_id');
    }
}