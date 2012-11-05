<?php

/**
 * Classe parente des tests Twgit, permet de faciliter les interactions entre PHP, Shell et Git.
 *
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitTestCase extends PHPUnit_Framework_TestCase
{

    /**
     * @var Shell_Adapter
     */
    protected static $_oShell = NULL;

    /**
     * Singleton.
     *
     * @return Shell_Adapter
     */
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
    public function __construct($sName=NULL, array $aData=array(), $sDataName='')
    {
        parent::__construct($sName, $aData, $sDataName);
    }

    /**
     * Supprime les couleurs Shell du message spécifié.
     *
     * @param string $sMsg
     * @return string
     */
    protected static function stripColors ($sMsg)
    {
        return preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', $sMsg);
    }

    /**
     * Exécute la commande shell spécifiée et retourne la sortie d'exécution sous forme d'une chaîne de caractères.
     * L'éventuelle coloration Shell est enlevée.
     * En cas d'erreur shell (code d'erreur <> 0), lance une exception incluant le message d'erreur.
     *
     * @param string $sCmd
     * @param bool $bStripBashColors Supprime ou non la coloration Bash de la chaîne retournée
     * @return string sortie d'exécution sous forme d'une chaîne de caractères.
     * @throws RuntimeException en cas d'erreur shell
     */
    protected function _exec ($sCmd, $bStripBashColors=true)
    {
        try {
            $aResult = self::_rawExec($sCmd);
        } catch (RuntimeException $oException) {
            $sMsg = ($oException->getMessage() != '' ? $oException->getMessage() : '-- no message --');
            throw new RuntimeException(
                self::stripColors($sMsg),
                $oException->getCode(),
                $oException
            );
        }
        $sMsg = implode("\n", $aResult);
        if ($bStripBashColors) {
            $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', $sMsg);
        } else {
            $sMsg = str_replace("\033", '\033', $sMsg);
        }
        return $sMsg;
    }

    /**
     * Exécute la commande shell spécifiée dans le répertoire du dépôt Git local,
     * et retourne la sortie d'exécution sous forme d'une chaîne de caractères.
     * L'éventuelle coloration Shell est enlevée.
     *
     * En cas d'erreur shell (code d'erreur <> 0), lance une exception incluant le message d'erreur.
     *
     * @param string $sCmd
     * @param bool $bStripBashColors Supprime ou non la coloration Bash de la chaîne retournée
     * @return string sortie d'exécution sous forme d'une chaîne de caractères.
     * @throws RuntimeException en cas d'erreur shell
     */
    protected function _localExec ($sCmd, $bStripBashColors=true)
    {
        $sLocalCmd = 'cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . $sCmd;
        return $this->_exec($sLocalCmd, $bStripBashColors);
    }

    /**
     * Appelle une fonction de inc/common.inc.sh une fois dans le répertoire du dépôt Git local,
     * et retourne la sortie d'exécution sous forme d'une chaîne de caractères.
     * L'éventuelle coloration Shell est enlevée.
     * Les fichiers de configuration Shell sont préalablement chargés.
     *
     * En cas d'erreur shell (code d'erreur <> 0), lance une exception incluant le message d'erreur.
     *
     * Par exemple : $this->_localFunctionCall('process_fetch x');
     *
     * @param string $sCmd
     * @param bool $bStripBashColors Supprime ou non la coloration Bash de la chaîne retournée
     * @return string sortie d'exécution sous forme d'une chaîne de caractères.
     * @throws RuntimeException en cas d'erreur shell
     */
    protected function _localFunctionCall ($sCmd, $bStripBashColors=true)
    {
        $sFunctionCall = '/bin/bash ' . TWGIT_TESTS_INC_DIR . '/testFunction.sh ' . $sCmd;
        return $this->_localExec($sFunctionCall, $bStripBashColors);
    }

    /**
     * Exécute du code appelant des fonctions de inc/common.inc.sh une fois dans le répertoire du dépôt Git local,
     * et retourne la sortie d'exécution sous forme d'une chaîne de caractères.
     * L'éventuelle coloration Shell est enlevée.
     * Les fichiers de configuration Shell sont préalablement chargés.
     *
     * En cas d'erreur shell (code d'erreur <> 0), lance une exception incluant le message d'erreur.
     *
     * Par exemple : $this->_localShellCodeCall('process_options x -aV; isset_option a; echo \$?');
     * Attention à l'échappement des dollars ($).
     *
     * @param string $sCmd
     * @param bool $bStripBashColors Supprime ou non la coloration Bash de la chaîne retournée
     * @return string sortie d'exécution sous forme d'une chaîne de caractères.
     * @throws RuntimeException en cas d'erreur shell
     */
    protected function _localShellCodeCall ($sCmd, $bStripBashColors=true)
    {
        $sShellCodeCall = '/bin/bash ' . TWGIT_TESTS_INC_DIR . '/testShellCode.sh "' . $sCmd . '"';
        return $this->_localExec($sShellCodeCall, $bStripBashColors);
    }

    /**
     * Exécute la commande shell spécifiée dans le répertoire du dépôt Git distant,
     * et retourne la sortie d'exécution sous forme d'une chaîne de caractères.
     * L'éventuelle coloration Shell est enlevée.
     * En cas d'erreur shell (code d'erreur <> 0), lance une exception incluant le message d'erreur.
     *
     * @param string $sCmd
     * @param bool $bStripBashColors Supprime ou non la coloration Bash de la chaîne retournée
     * @return string sortie d'exécution sous forme d'une chaîne de caractères.
     * @throws RuntimeException en cas d'erreur shell
     */
    protected function _remoteExec ($sCmd, $bStripBashColors=true)
    {
        $sRemoteCmd = 'cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && ' . $sCmd;
        return $this->_exec($sRemoteCmd, $bStripBashColors);
    }
}
