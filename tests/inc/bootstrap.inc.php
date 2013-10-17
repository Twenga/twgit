<?php

/**
 * Bootstrap for unit tests only.
 *
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@free.fr>
 */

include_once(__DIR__ . '/../../conf/phpunit.php');
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

// Overload conf/twgit.sh with PHP defines in conf/phpunit.php.
// Result into TWGIT_TMP_DIR . '/conf-twgit.sh'
// copy(TWGIT_ROOT_DIR . '/conf/twgit.sh', TWGIT_TMP_DIR . '/conf-twgit.sh');
$sConf = file_get_contents(TWGIT_ROOT_DIR . '/conf/twgit.sh');
$aAllDefines = get_defined_constants(true);
$aUserDefines = $aAllDefines['user'];
// $sAddConfig = "\n\n# From " . __FILE__ . ":\n";
// 			. "TWGIT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"";
foreach ($aUserDefines as $sKey => $sValue) {
    if (strpos($sKey, 'TWGIT_') === 0) {
//         $sAddConfig .= "$sKey='$sValue'\n";
        $sConf = preg_replace("/^$sKey=.*$/m", "$sKey='$sValue'", $sConf);
    }
}
file_put_contents(TWGIT_TMP_DIR . '/conf-twgit.sh', $sConf);
