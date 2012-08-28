<?php

namespace Taf\Taf;

use Taf\Taf\Base\SuspendedTaskMap as BaseSuspendedTaskMap;
use Taf\Taf\SuspendedTask;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class SuspendedTaskMap extends BaseSuspendedTaskMap
{
  protected $active_task_map;

  public function setActiveTaskMap(ActiveTaskMap $map = null)
  {
    $map = is_null($map) ? $this->connection->getMapFor('\Taf\Taf\ActiveTask') : $map;
    $this->active_task_map = $map;
  }

  public function getActiveTaskMap(ActiveTaskMap $map = null)
  {
    if (is_null($this->active_task_map))
    {
      $this->setActiveTaskMap($map);
    }

    return $this->active_task_map;
  }

  public function suspendTask($id)
  {
    $sql = <<<EOSQL
WITH
  no_more_active AS ( DELETE FROM %s at WHERE at.id = ? RETURNING %s)
  INSERT INTO %s SELECT %s FROM no_more_active nma RETURNING %s
EOSQL;

    $sql = sprintf($sql, 
      $this->getActiveTaskMap()->getTableName(),
      $this->getActiveTaskMap()->joinSelectFieldsWithAlias('at'),
      $this->getTableName(),
      $this->getActiveTaskMap()->joinSelectFieldsWithAlias('nma'),
      $this->joinSelectFieldsWithAlias()
    );

    return $this->query($sql, array($id))->current();
  }
}
