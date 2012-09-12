<?php

namespace Taf\Taf;

use \Pomm\Object\BaseObject;
use \Pomm\Exception\Exception;
use \Pomm\External\sfInflector;

class TaskLnk extends BaseObject
{
    public function getRelname()
    {
        return sfInflector::camelize($this->get('relname'));
    }
}
