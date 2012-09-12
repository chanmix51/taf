<?php

namespace Taf\Taf;

use Taf\Taf\Base\SuspendedTaskMap as BaseSuspendedTaskMap;
use Taf\Taf\SuspendedTask;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class SuspendedTaskMap extends BaseSuspendedTaskMap
{
  public function suspendTask($id)
  {
    $sql = <<<EOSQL
WITH
  no_more_active AS ( DELETE FROM %s at WHERE at.task_id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_active nma RETURNING %s
EOSQL;

    $sql = sprintf($sql, 
      $this->getActiveTaskMap()->getTableName(),
      $this->getActiveTaskMap()->joinSelectFieldsWithAlias('at'),
      $this->getTableName(),
      join(', ', $this->getTaskMap()->getSelectFields()),
      $this->getTaskMap()->joinSelectFieldsWithAlias('nma'),
      $this->joinSelectFieldsWithAlias()
    );

    return $this->query($sql, array($id))->current();
  }
}
