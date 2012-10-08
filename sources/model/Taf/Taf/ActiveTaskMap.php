<?php

namespace Taf\Taf;

use Taf\Taf\Base\ActiveTaskMap as BaseActiveTaskMap;
use Taf\Taf\ActiveTask;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class ActiveTaskMap extends BaseActiveTaskMap
{
    public function initialize()
    {
        parent::initialize();

        $this->addVirtualField('active_since', 'interval');
    }

    public function getSelectFields($alias = null)
    {
        $fields = parent::getSelectFields($alias);
        $alias = is_null($alias) ? '' : $alias.".";

        unset($fields['rank']);
        $fields['active_since']  = sprintf('age(%sactive_at)', $alias);

        return $fields;
    }

    public function moveTask($task_id, $new_rank)
    {
        $sql = sprintf('SELECT %s FROM taf.update_rank_active_task(?, ?)', $this->formatFieldsWithAlias('getSelectFields'));

        return $this->query($sql, array($task_id, $new_rank))->current();
    }

    public function unsuspendTask($id, $rank = null)
    {
        $suspended_task_map = $this->connection->getMapFor('\Taf\Taf\SuspendedTask');
        $task_map = $this->connection->getMapFor('\Taf\Taf\Task');

        $sql = <<<OESQL
WITH
  no_more_suspended AS (DELETE FROM %s st WHERE st.task_id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_suspended nms RETURNING %s
OESQL;

        $sql = sprintf($sql,
            $suspended_task_map->getTableName(),
            $suspended_task_map->formatFieldsWithAlias('getSelectFields', 'st'),
            $this->getTableName(), 
            join(', ', array_merge(array_keys($task_map->getFieldDefinitions()), array('rank'))),
            join(', ', $task_map->getFields('nms')).", ? AS rank",
            $this->formatFieldsWithAlias('getSelectFields')
        );

        return $this->query($sql, array($id, $rank))->current();
    }

    public function unfinishTask($id, $rank = null)
    {
        $finished_task_map = $this->connection->getMapFor('\Taf\Taf\FinishedTask');
        $task_map = $this->connection->getMapFor('\Taf\Taf\Task');

        $sql = <<<OESQL
WITH
  no_more_finished AS (DELETE FROM %s st WHERE st.task_id = ? RETURNING %s)
  INSERT INTO %s (%s) SELECT %s FROM no_more_finished nmf RETURNING %s
OESQL;

        $sql = sprintf($sql,
            $finished_task_map->getTableName(),
            $finished_task_map->formatFieldsWithAlias('getSelectFields'),
            $this->getTableName(), 
            join(', ', array_merge(array_keys($task_map->getFieldDefinitions()), array('rank'))),
            join(', ', $task_map->getFields('nmf')).", ? AS rank",
            $this->formatFieldsWithAlias('getSelectFields')
        );

        return $this->query($sql, array($id, $rank))->current();
    }
}
