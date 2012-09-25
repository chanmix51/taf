<?php

namespace Taf\Taf;

use Taf\Taf\Base\TaskMap as BaseTaskMap;
use Taf\Taf\Task;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class TaskMap extends BaseTaskMap
{
    protected $active_task_map;
    protected $suspended_task_map;
    protected $finished_task_map;
    protected $task_lnk_map;
    protected $task_map;

    public function getSelectFields($alias)
    {
        $fields = parent::getSelectFields($alias);
        $alias = is_null($alias) ? '' : $alias.".";

        $fields['created_since'] = sprintf('age(%screated_at)', $alias);

        return $fields;
    }

    public function getActiveTaskMap(ActiveTaskMap $map = null)
    {
        if (is_null($this->active_task_map))
        {
            $this->setActiveTaskMap($map);
        }

        return $this->active_task_map;
    }

    public function getSuspendedTaskMap(SuspendedTaskMap $map = null)
    {
        if (is_null($this->suspended_task_map))
        {
            $this->setSuspendedTaskMap($map);
        }

        return $this->suspended_task_map;
    }

    public function getFinishedTaskMap(FinishedTaskMap $map = null)
    {
        if (is_null($this->finished_task_map))
        {
            $this->setFinishedTaskMap($map);
        }

        return $this->finished_task_map;
    }

    public function getTaskLnkMap(TaskLnkMap $map = null)
    {
        if (is_null($this->task_lnk_map))
        {
            $this->setTaskLnkMap($map);
        }

        return $this->task_lnk_map;
    }

  public function getTaskMap(TaskMap $map = null)
  {
      if (is_null($this->task_map))
      {
          $this->setTaskMap($map);
      }

      return $this->task_map;
  }

  public function setTaskMap(TaskMap $map = null)
  {
      $this->task_map = is_null($map) ? $this->connection->getMapFor('\Taf\Taf\Task') : $map;
  }

    public function setActiveTaskMap(ActiveTaskMap $map = null)
    {
        $this->active_task_map = is_null($map) ? $this->connection->getMapFor('\Taf\Taf\ActiveTask') : $map;
    }

    public function setSuspendedTaskMap(SuspendedTaskMap $map = null)
    {
        $this->suspended_task_map = is_null($map) ? $this->connection->getMapFor('\Taf\Taf\SuspendedTask') : $map;
    }

    public function setFinishedTaskMap(FinishedTaskMap $map = null)
    {
        $this->finished_task_map = is_null($map) ? $this->connection->getMapFor('\Taf\Taf\FinishedTask') : $map;
    }

    public function setTaskLnkMap(TaskLnkMap $map = null)
    {
        $this->task_lnk_map = is_null($map) ? $this->connection->getMapFor('\Taf\Taf\TaskLnk') : $map;
    }

    public function getMapFor($task_class)
    {
        $method_name = sprintf("get%sMap", $task_class);

        return call_user_func(array('\Taf\Taf\TaskMap', $method_name));
    }

    public function findBySlug($slug)
    {
        $task_lnk = $this->getTaskLnkMap()->findWhere("slug = ?", array($slug))->current();

        if ($task_lnk === false) return false;

        return $this->getMapFor($task_lnk['relname'])->findWhere("slug = ?", array($slug))->current();
    }
}
