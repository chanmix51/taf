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
    $sql = <<<OESQL
WITH
  no_more_active AS (DELETE FROM %s at WHERE at.task_id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_active nma RETURNING %s
OESQL;

    $sql = sprintf($sql,
      $this->getActiveTaskMap()->getTableName(),
      $this->getActiveTaskMap()->joinSelectFieldsWithAlias(),
      $this->getTableName(), 
      join(', ', $this->getTaskMap()->getSelectFields()),
      $this->getTaskMap()->joinSelectFieldsWithAlias('nma'),
      $this->joinSelectFieldsWithAlias()
    );

    return $this->query($sql, array($id))->current();
  }
}
