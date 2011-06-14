<?php

// /usr/bin/php -q ~/twgit/inc/ws_redmine.inc.php 7573 subject
// http://localhost/TwGit/inc/ws_redmine.inc.php?issue=7573

// http://redmine.twenga.com/projects/api2/issues.xml
// http://twgit:7T8qyL@redmine.twenga.com/projects/api2/issues.xml?key=c0bb67bc6ae9b1693ac3f06a8e7fd8f5eefa425f

include_once(__DIR__ . '/../lib/phpactiveresource/ActiveResource.php');
define('USERNAME', 'twgit');
define('PASSWORD', '7T8qyL');
define('SITE_URL', 'http://' . USERNAME . ':' . PASSWORD . '@redmine.twenga.com/');

class Issue extends ActiveResource {
    var $site = SITE_URL;
    var $request_format = 'xml'; // REQUIRED!
    var $extra_params = '?key=c0bb67bc6ae9b1693ac3f06a8e7fd8f5eefa425f';
}

$argc--;
array_shift($argv);
if ($argc < 1) {
	throw new Exception('Issue ID missing!');
}
$issue_ids = explode(',', $argv[0]);
$needed_key = ($argc >= 2 ? $argv[1] : '');

$issue = new Issue (array ('subject' => 'XML REST API'));
$has_errors=false;
$results = array();
foreach ($issue_ids as $issue_id) {
	$issue->find($issue_id);
	if ($issue->error !== false) {
		file_put_contents('php://stderr', $issue->error . "\n" . $issue->response_headers, E_USER_ERROR);
		$has_errors=true;
	} else if (strcasecmp($issue_id, $issue->id) !== 0) {
		file_put_contents('php://stderr', "Requested ID: '$issue_id'. ID found: '" . $issue->id . "'", E_USER_ERROR);
		$has_errors=true;
	} else {
		$data = array(
			'id' => $issue->id,
			'parent' => $issue->parent,
			'project' => $issue->project,
			'subject' => $issue->subject,
			'description' => $issue->description,
			'assign_to' => $issue->assigned_to->attributes()->name,
		);

		if ( ! empty($needed_key)) {
			if (isset($data[$needed_key])) {
				$results[] = $data[$needed_key];
			} else {
				file_put_contents('php://stderr', "Key '$needed_key' not found!", E_USER_ERROR);
				$has_errors=true;
			}
		} else {
			$results[] = json_encode($data);
		}
	}
}

echo implode("\n", $results);
if ($has_errors) {
	exit(1);
}
