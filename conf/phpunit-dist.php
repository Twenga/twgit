<?php

/**
 * Config file for unit tests only.
 * @author Geoffroy Aubry <geoffroy.aubry@free.fr>
 */

// Paths
define('TWGIT_ROOT_DIR', realpath(__DIR__ . '/..'));
define('TWGIT_TMP_DIR', '/tmp');
define('TWGIT_TESTS_DIR', TWGIT_ROOT_DIR . '/tests');
define('TWGIT_TESTS_LIB_DIR', TWGIT_TESTS_DIR . '/lib');
define('TWGIT_TESTS_INC_DIR', TWGIT_TESTS_DIR . '/inc');

// Error handler
define('TWGIT_DISPLAY_ERRORS', true);
define('TWGIT_ERROR_LOG_PATH', '');
define('TWGIT_ERROR_LEVEL', -1);
define('TWGIT_AUTH_ERROR_SUPPR_OP', true);

// Exec
define('TWGIT_BASH_EXEC', '/bin/bash');
define('TWGIT_EXEC', TWGIT_BASH_EXEC . ' ' . TWGIT_ROOT_DIR . '/twgit');

// Other
define('TWGIT_REPOSITORY_ORIGIN_DIR', TWGIT_TMP_DIR . '/origin');
define('TWGIT_REPOSITORY_LOCAL_DIR', TWGIT_TMP_DIR . '/local');
define('TWGIT_REPOSITORY_SECOND_LOCAL_DIR', TWGIT_TMP_DIR . '/local2');
define('TWGIT_REPOSITORY_SECOND_REMOTE_DIR', TWGIT_TMP_DIR . '/second');
define('TWGIT_REPOSITORY_THIRD_REMOTE_DIR', TWGIT_TMP_DIR . '/third');