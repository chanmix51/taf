<?php

namespace Taf\Taf;

use Taf\Taf\Base\FinishedTaskMap as BaseFinishedTaskMap;
use Taf\Taf\FinishedTask;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class FinishedTaskMap extends BaseFinishedTaskMap
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

  public function finishTask($id)
  {
    $sql = <<<OESQL
WITH
  no_more_active AS (DELETE FROM %s at WHERE at.id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_active nma RETURNING %s
OESQL;

    $sql = sprintf($sql,
      $this->getActiveTaskMap()->getTableName(),
      $this->getActiveTaskMap()->joinSelectFieldsWithAlias(),
      $this->getTableName(), 
      join(', ', array_filter($this->getSelectFields(), function($val) { return $val !== 'created_at' ? $val : null; })),
      $this->getActiveTaskMap()->joinSelectFieldsWithAlias('nma'),
      $this->joinSelectFieldsWithAlias()
    );

    return $this->query($sql, array($id))->current();
  }
}
