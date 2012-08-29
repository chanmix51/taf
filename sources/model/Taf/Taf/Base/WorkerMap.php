<?php

namespace Taf\Taf\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class WorkerMap extends BaseObjectMap
{
    public function initialize()
    {

        $this->object_class =  'Taf\Taf\Worker';
        $this->object_name  =  'taf.worker';

        $this->addField('worker_id', 'int4');
        $this->addField('email', 'taf.email_address');
        $this->addField('first_name', 'varchar');
        $this->addField('last_name', 'varchar');

        $this->pk_fields = array('worker_id');
    }
}