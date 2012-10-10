<?php

namespace Taf\Taf;

use Taf\Taf\Base\WorkerMap as BaseWorkerMap;
use Taf\Taf\Worker;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class WorkerMap extends BaseWorkerMap
{
    public function getSelectFields($alias = null)
    {
        $fields = parent::getSelectFields($alias);
        $fields['gravatar'] = sprintf('md5(%s)', is_null($alias) ? 'email' : $alias.'.email');

        return $fields;
    }
}
