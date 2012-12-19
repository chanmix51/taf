<?php

namespace Taf;

abstract class BaseMap extends \Pomm\Object\BaseObjectMap
{
    public function createCollectionFromStatement(\PDOStatement $stmt)
    {
        return new \Pomm\Object\SimpleCollection($stmt, $this);
    }
}
