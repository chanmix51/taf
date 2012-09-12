<?php

namespace Taf\Taf;

use Taf\Taf\Base\ActiveTaskMap as BaseActiveTaskMap;
use Taf\Taf\ActiveTask;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class ActiveTaskMap extends BaseActiveTaskMap
{
  public function getSelectFields($alias = null)
  {
    $fields = parent::getSelectFields($alias);

    unset($fields['rank']);

    return $fields;
  }

  public function moveTask($task_id, $new_rank)
  {
    $sql = 'SELECT %s FROM taf.update_rank_active_task(?, ?)';

    return $this->query(sprintf($sql, $this->joinSelectFieldsWithAlias()), array($task_id, $new_rank));
  }

  public function unsuspendTask($id, $rank = null)
  {
    $sql = <<<OESQL
WITH
  no_more_suspended AS (DELETE FROM %s st WHERE st.task_id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_suspended nms RETURNING %s
OESQL;

    $sql = sprintf($sql,
      $this->getSuspendedTaskMap()->getTableName(),
      $this->getSuspendedTaskMap()->joinSelectFieldsWithAlias(),
      $this->getTableName(), 
      join(', ', array_merge($this->getTaskMap()->getSelectFields(), array('rank'))),
      $this->getTaskMap()->joinSelectFieldsWithAlias('nms').', ?',
      $this->joinSelectFieldsWithAlias()
    );

    return $this->query($sql, array($id, $rank))->current();
  }

  public function unfinishTask($id, $rank = null)
  {
    $sql = <<<OESQL
WITH
  no_more_finished AS (DELETE FROM %s ft WHERE ft.task_id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_finished nmf RETURNING %s
OESQL;

    $sql = sprintf($sql,
      $this->getFinishedTaskMap()->getTableName(),
      $this->getFinishedTaskMap()->joinSelectFieldsWithAlias(),
      $this->getTableName(), 
      join(', ', array_merge($this->getTaskMap()->getSelectFields(), array('rank'))),
      $this->getTaskMap()->joinSelectFieldsWithAlias('nmf').', ?',
      $this->joinSelectFieldsWithAlias()
    );

    return $this->query($sql, array($id, $rank))->current();
  }

  public function findByPkAndUpdateTime($id, $time)
  {
    $sql = "UPDATE %s SET work_time = work_time + %d WHERE id = ? RETURNING %s";
    $sql = sprintf($sql,
      $this->getTableName(),
      $time,
      $this->joinSelectFieldsWithAlias()
    );

    return $this->query($sql, array($id))->current();
  }
}
