<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitTestCase extends PHPUnit_Framework_TestCase
{

    /**
     * @var Shell_Adapter
     */
    protected static $_oShell = NULL;

    protected static function _getShellInstance ()
    {
        if (self::$_oShell === NULL) {
            self::$_oShell = new Shell_Adapter();
        }
        return self::$_oShell;
    }

    /**
     * Exécute la commande shell spécifiée et retourne la sortie découpée par ligne dans un tableau.
     * En cas d'erreur shell (code d'erreur <> 0), lance une exception incluant le message d'erreur.
     *
     * @param string $sCmd
     * @return array tableau indexé du flux de sortie shell découpé par ligne
     * @throws RuntimeException en cas d'erreur shell
     */
    protected static function _rawExec ($sCmd)
    {
        return self::_getShellInstance()->exec($sCmd);
    }

    /**
     * Constructs a test case with the given name.
     *
     * @param  string $name
     * @param  array  $data
     * @param  string $dataName
     */
    public function __construct($name=NULL, array $data=array(), $dataName='')
    {
        parent::__construct($name, $data, $dataName);
    }

    /**
     * Exécute la commande shell spécifiée et retourne la sortie découpée par ligne dans un tableau.
     * En cas d'erreur shell (code d'erreur <> 0), lance une exception incluant le message d'erreur.
     *
     * @param string $sCmd
     * @return array tableau indexé du flux de sortie shell découpé par ligne
     * @throws RuntimeException en cas d'erreur shell
     */
    protected function _exec ($sCmd)
    {
        $aResult = self::_rawExec($sCmd);
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        return $sMsg;
    }

    protected function _localExec ($sCmd)
    {
        $sLocalCmd = 'cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . $sCmd;
        return $this->_exec($sLocalCmd);
    }

    protected function _localFunctionCall ($sCmd)
    {
        $sFunctionCall = '/bin/bash ' . TWGIT_TESTS_INC_DIR . '/testFunction.sh ' . $sCmd;
        return $this->_localExec($sFunctionCall);
    }

    protected function _localShellCodeCall ($sCmd)
    {
        $sShellCodeCall = '/bin/bash ' . TWGIT_TESTS_INC_DIR . '/testShellCode.sh "' . $sCmd . '"';
        return $this->_localExec($sShellCodeCall);
    }

    protected function _remoteExec ($sCmd)
    {
        $sRemoteCmd = 'cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && ' . $sCmd;
        return $this->_exec($sRemoteCmd);
    }

    /**
     * Sets up the fixture, for example, open a network connection.
     * This method is called before a test is executed.
     */
    public function setUp ()
    {
    }

    /**
     * Tears down the fixture, for example, close a network connection.
     * This method is called after a test is executed.
     */
    public function tearDown ()
    {
    }
}
