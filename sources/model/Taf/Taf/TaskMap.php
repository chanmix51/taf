<?php

namespace Taf\Taf;

use Taf\Taf\Base\TaskMap as BaseTaskMap;
use Taf\Taf\Task;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class TaskMap extends BaseTaskMap
{
    public function initialize()
    {
        parent::initialize();

        $this->addVirtualField('created_since', 'interval');
    }

    public function getSelectFields($alias = null)
    {
        $fields = parent::getSelectFields($alias);
        $alias = is_null($alias) ? '' : $alias.".";

        $fields['created_since'] = sprintf('age(%screated_at)', $alias);

        return $fields;
    }

    public function findBySlug($slug)
    {
        $task_lnk = $this
            ->connection
            ->getMapFor('\Taf\Taf\TaskLnk')
            ->findWhere("slug = ?", array($slug))->current();

        if ($task_lnk === false) return false;

        return $this
            ->connection
            ->getMapFor(sprintf("\\Taf\\Taf\\%s", \Pomm\External\sfInflector::camelize($task_lnk['relname'])))
            ->findWithWorkerWhere(new Where("slug = ?", array($slug)))
            ->current();
    }

    public function findWithWorkerWhere(Where $where)
    {
        $worker_map = $this->connection->getMapFor('\Taf\Taf\Worker');
        $sql = <<<EOSQL
SELECT
  %s,
  %s
FROM
  %s task
    NATURAL JOIN %s worker
WHERE
  %s
EOSQL;
        $sql = sprintf($sql,
            $this->formatFieldsWithAlias('getSelectFields', 'task'),
            $worker_map->formatFieldsWithAlias('getRemoteSelectFields', 'worker'),
            $this->getTableName(),
            $worker_map->getTableName(),
            (string) $where
        );

        return  $this->query($sql, $where->getValues())
            ->registerFilter(array($worker_map, 'createFromForeign'));
    }

}
