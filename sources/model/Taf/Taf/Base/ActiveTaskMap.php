<?php

namespace Taf\Taf\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class ActiveTaskMap extends \Taf\Taf\TaskMap
{
    public function initialize()
    {
        parent::initialize();

        $this->object_class =  'Taf\Taf\ActiveTask';
        $this->object_name  =  'taf.active_task';

        $this->addField('active_since', 'timestamp');
        $this->addField('block_stack', 'json');

        $this->pk_fields = array('task_id');
    }
}