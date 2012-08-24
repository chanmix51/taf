<?php

namespace Taf\Taf;

use Taf\Taf\Base\ActiveTaskMap as BaseActiveTaskMap;
use Taf\Taf\ActiveTask;
use \Pomm\Exception\Exception;
use \Pomm\Query\Where;

class ActiveTaskMap extends BaseActiveTaskMap
{
  public function moveTask($task_id, $new_rank)
  {
    $sql = 'SELECT * FROM taf.update_rank_active_task(?, ?)';

    return $this->query($sql, array($task_id, $new_rank));
  }
}
