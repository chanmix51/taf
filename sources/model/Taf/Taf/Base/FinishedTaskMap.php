<?php

namespace Taf\Taf\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class FinishedTaskMap extends BaseObjectMap
{
    public function initialize()
    {

        $this->object_class =  'Taf\Taf\FinishedTask';
        $this->object_name  =  'taf.finished_task';

        $this->addField('id', 'int4');
        $this->addField('title', 'varchar');
        $this->addField('slug', 'varchar');
        $this->addField('work_time', 'int4');
        $this->addField('created_at', 'timestamp');
        $this->addField('block_stack', 'json');
        $this->addField('changed_at', 'timestamp');
        $this->addField('worker_id', 'int4');

        $this->pk_fields = array('id');
    }
}