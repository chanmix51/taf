<?php

namespace Taf\Taf\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class TaskLnkMap extends \Taf\BaseMap
{
    public function initialize()
    {

        $this->object_class =  'Taf\Taf\TaskLnk';
        $this->object_name  =  'taf.task_lnk';

        $this->addField('task_id', 'int4');
        $this->addField('worker_id', 'int4');
        $this->addField('slug', 'varchar');
        $this->addField('relname', 'name');

        $this->pk_fields = array('');
    }
}