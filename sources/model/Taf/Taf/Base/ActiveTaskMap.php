<?php

namespace Taf\Taf\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class ActiveTaskMap extends BaseObjectMap
{
    public function initialize()
    {

        $this->object_class =  'Taf\Taf\ActiveTask';
        $this->object_name  =  'taf.active_task';

        $this->addField('id', 'int4');
        $this->addField('rank', 'int4');
        $this->addField('title', 'varchar');
        $this->addField('slug', 'varchar');
        $this->addField('work_time', 'int4');

        $this->pk_fields = array('id');
    }
}