<?php

/**
 * Bootstrap for unit tests only.
 *
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@free.fr>
 */

include_once(__DIR__ . '/../../conf/phpunit-dist.php');
include_once(TWGIT_TESTS_LIB_DIR . '/ClassLoader.php');

set_include_path(
    TWGIT_ROOT_DIR . PATH_SEPARATOR .
    get_include_path()
);

ClassLoader::register('', TWGIT_TESTS_LIB_DIR);
ClassLoader::register('', TWGIT_TESTS_INC_DIR);

$GLOBALS['oErrorHandler'] = new ErrorHandler(
    TWGIT_DISPLAY_ERRORS,
    TWGIT_ERROR_LOG_PATH,
    TWGIT_ERROR_LEVEL,
    TWGIT_AUTH_ERROR_SUPPR_OP
);

// Avoid update process of Twgit:
touch(TWGIT_ROOT_DIR . '/.lastupdate');
