<?php

namespace Taf\Taf\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class SuspendedTaskMap extends BaseObjectMap
{
    public function initialize()
    {

        $this->object_class =  'Taf\Taf\SuspendedTask';
        $this->object_name  =  'taf.suspended_task';

        $this->addField('id', 'int4');
        $this->addField('title', 'varchar');
        $this->addField('slug', 'varchar');
        $this->addField('work_time', 'int4');
        $this->addField('created_at', 'timestamp');

        $this->pk_fields = array('id');
    }
}