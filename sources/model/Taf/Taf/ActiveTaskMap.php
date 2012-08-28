<?php

namespace Taf\Taf;

use Taf\Taf\Base\ActiveTaskMap as BaseActiveTaskMap;
use Taf\Taf\ActiveTask;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class ActiveTaskMap extends BaseActiveTaskMap
{
  protected $suspended_task_map;
  protected $finished_task_map;

  public function setSuspendedTaskMap(SuspendedTaskMap $map = null)
  {
    $this->suspended_task_map = is_null($map) ? $this->connection->getMapFor('\Taf\Taf\SuspendedTask') : $map;
  }

  public function getSuspendedTaskMap(SuspendedTaskMap $map = null)
  {
    if (is_null($this->suspended_task_map))
    {
      $this->setSuspendedTaskMap($map);
    }

    return $this->suspended_task_map;
  }

  public function setFinishedTaskMap(FinishedTaskMap $map = null)
  {
    $this->finished_task_map = is_null($map) ? $this->connection->getMapFor('\Taf\Taf\FinishedTask') : $map;
  }

  public function getFinishedTaskMap(FinishedTaskMap $map = null)
  {
    if (is_null($this->finished_task_map))
    {
      $this->setFinishedTaskMap($map);
    }

    return $this->finished_task_map;
  }

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

  public function unsuspendTask($id)
  {
    $sql = <<<OESQL
WITH
  no_more_suspended AS (DELETE FROM %s st WHERE st.id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_suspended nms RETURNING %s
OESQL;

    $sql = sprintf($sql,
      $this->getSuspendedTaskMap()->getTableName(),
      $this->getSuspendedTaskMap()->joinSelectFieldsWithAlias(),
      $this->getTableName(), 
      join(', ', $this->getSelectFields()),
      $this->joinSelectFieldsWithAlias('nms'),
      $this->joinSelectFieldsWithAlias()
    );

    return $this->query($sql, array($id))->current();
  }

  public function unfinishTask($id)
  {
    $sql = <<<OESQL
WITH
  no_more_finished AS (DELETE FROM %s ft WHERE ft.id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_finished nmf RETURNING %s
OESQL;

    $sql = sprintf($sql,
      $this->getFinishedTaskMap()->getTableName(),
      $this->getFinishedTaskMap()->joinSelectFieldsWithAlias(),
      $this->getTableName(), 
      join(', ', $this->getSelectFields()),
      $this->joinSelectFieldsWithAlias('nmf'),
      $this->joinSelectFieldsWithAlias()
    );

    return $this->query($sql, array($id))->current();
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
