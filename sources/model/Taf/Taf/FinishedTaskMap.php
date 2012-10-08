<?php

namespace Taf\Taf;

use Taf\Taf\Base\FinishedTaskMap as BaseFinishedTaskMap;
use Taf\Taf\FinishedTask;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class FinishedTaskMap extends BaseFinishedTaskMap
{
  public function finishTask($id)
  {
      $active_task_map = $this->connection->getMapFor('\Taf\Taf\ActiveTask');
      $task_map = $this->connection->getMapFor('\Taf\Taf\Task');

    $sql = <<<OESQL
WITH
  no_more_active AS (DELETE FROM %s at WHERE at.task_id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_active nma RETURNING %s
OESQL;

    $sql = sprintf($sql,
      $active_task_map->getTableName(),
      $active_task_map->formatFieldsWithAlias('getSelectFields'),
      $this->getTableName(), 
      $task_map->formatFields('getFields'),
      $task_map->formatFieldsWithAlias('getFields', 'nma'),
      $this->formatFieldsWithAlias('getSelectFields')
    );

    return $this->query($sql, array($id))->current();
  }
}
