<?php

namespace Taf\Taf\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class WorkerMap extends \Taf\BaseMap
{
    public function initialize()
    {

        $this->object_class =  'Taf\Taf\Worker';
        $this->object_name  =  'taf.worker';

        $this->addField('worker_id', 'int4');
        $this->addField('email', 'taf.email_address');
        $this->addField('extra_data', 'public.hstore');

        $this->pk_fields = array('worker_id');
    }
}