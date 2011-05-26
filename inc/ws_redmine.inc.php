<?php

// /usr/bin/php -q ~/twgit/inc/ws_redmine.inc.php 7573
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

if (isset($_GET['issue'])) {
	$issue_id = $_GET['issue'];
} else {
	$argc--;
	array_shift($argv);
	if ($argc < 1) {
		throw new Exception('Issue ID missing!');
	}
	$issue_id = $argv[0];
}

$issue = new Issue (array ('subject' => 'XML REST API'));
$issue->find($issue_id);
if ($issue->error !== false) {
	file_put_contents('php://stderr', $issue->error . "\n" . $issue->response_headers, E_USER_ERROR);
} else if (strcasecmp($issue_id, $issue->id) !== 0) {
	file_put_contents('php://stderr', "Requested ID: '$issue_id'. ID found: '" . $issue->id . "'", E_USER_ERROR);
} else {
	echo 'ID: ' . $issue->id . "\n";
	echo 'Parent: ' . $issue->parent . "\n";
	echo 'Project: ' . $issue->project . "\n";
	echo 'Subject: ' . $issue->subject . "\n";
	echo 'Description: ' . $issue->description . "\n";
	echo 'Assign to: ' . $issue->assigned_to->attributes()->name . "\n";
}
