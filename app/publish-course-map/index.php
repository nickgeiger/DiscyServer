<?php

# Limit POST size we will process
$LIMIT = 500 * 1000; // 500K
$size = (int) $_SERVER['CONTENT_LENGTH'];
if ($size > $LIMIT) { # Just send temp ID & exit
  header('Content-Type: application/json; charset=utf-8');
  echo('{"courseId": "_tmp_'.uniqid().'_z"}');
  exit(0);
}

require('course-ids.php');

function courseIdExists(Array $sortedIds, $id) {
  if (count($sortedIds) === 0) { return false; }
  $low = 0;
  $high = count($sortedIds) - 1;
  while ($low <= $high) {
    $mid = floor(($low + $high) / 2);
    if ($sortedIds[$mid] == $id) { return true; }
    if ($id < $sortedIds[$mid]) {
      $high = $mid - 1;
    } else {
      $low = $mid + 1;
    }
  }
  return false;
}

$dir = "_unknown";
$course_id = "_tmp_".uniqid();

$json = file_get_contents('php://input');
#$json = '{"course": {"courseId": "jordan-creek", "name": "Woot"}}';
$course_map = json_decode($json, true);
if (JSON_ERROR_NONE === json_last_error()) {
  $course = $course_map['course'];
  if ($course !== null) {
    $id = $course['courseId'];
    if (!empty($id)) {
      $course_id = $id;
      #OLD: if ($id !== null && substr($id, 0, 5) !== '_tmp_') {
      if (courseIdExists($sortedCourseIds, $id)) {
        $dir = $course_id;
      }
    }
  }
  $course_dir = "published-maps/".$dir;
  if (!file_exists($course_dir)) {
    mkdir($course_dir, 0772, true);
  }
  $course_map_file = $course_dir."/".hash('sha256', $json).".json";
  if (!file_exists($course_map_file)) {
    $temp_file = $course_map_file.".".uniqid(microtime(true));
    file_put_contents($temp_file, $json);
    if (file_exists($course_map_file)) {
      unlink($temp_file);
    } else {
      rename($temp_file, $course_map_file);
    }
  }
}

header('Content-Type: application/json; charset=utf-8');
echo('{"courseId": "'.$course_id.'"}');

