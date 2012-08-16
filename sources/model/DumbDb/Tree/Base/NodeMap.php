<?php

namespace \DumbDb\Tree\Base;

use \Pomm\Object\BaseObjectMap;
use \Pomm\Exception\Exception;

abstract class NodeMap extends BaseObjectMap
{
    public function initialize()
    {

        $this->object_class =  '\DumbDb\Tree\Node';
        $this->object_name  =  'tree.node';

        $this->addField('id', 'int4');
        $this->addField('parent_id', 'int4');
        $this->addField('depth', 'int4');
        $this->addField('some_data', 'int4');

        $this->pk_fields = array('id');
    }
}