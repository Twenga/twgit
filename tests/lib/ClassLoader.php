<?php

/**
 * Sur une base de https://gist.github.com/221634.
 * Pour aller plus loin :
 *  - https://wiki.php.net/rfc/splclassloader
 *  - http://blog.runpac.com/post/splclassloader-php-extension-benchmarks
 *  - https://gist.github.com/221634
 *
 * @package Lib
 * @copyright 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
 * @license http://www.apache.org/licenses/LICENSE-2.0
 */
class ClassLoader
{
    private $_sFileExtension;
    private $_sNamespace;
    private $_sIncludePath;

    public function __construct($sNamespace, $sIncludePath, $sFileExtension)
    {
        $this->_sNamespace = $sNamespace;
        $this->_sIncludePath = $sIncludePath;
        $this->_sFileExtension = $sFileExtension;
    }

    /**
     * Installs this class loader on the SPL autoload stack.
     */
    public static function register($sNamespace='', $sIncludePath='', $sFileExtension='.php')
    {
        spl_autoload_register(array(new self($sNamespace, $sIncludePath, $sFileExtension), 'loadClass'));
    }

    /**
     * Loads the given class or interface.
     *
     * @param string $sClassName The name of the class to load.
     * @return bool
     */
    public function loadClass($sClassName)
    {
        if (
                $this->_sNamespace === ''
                || $this->_sNamespace.'\\' === substr($sClassName, 0, strlen($this->_sNamespace.'\\'))
        ) {

            if ($this->_sNamespace !== '' && $this->_sIncludePath !== '') {
                $sClassName = substr($sClassName, strlen($this->_sNamespace.'\\'));
            }

            $fileName = '';
            $namespace = '';
            $lastNsPos = strripos($sClassName, '\\');
            if ($lastNsPos !== false) {
                $namespace = substr($sClassName, 0, $lastNsPos);
                $sClassName = substr($sClassName, $lastNsPos + 1);
                $fileName .= str_replace('\\', DIRECTORY_SEPARATOR, $namespace) . DIRECTORY_SEPARATOR;
            }
            $fileName .= str_replace('_', DIRECTORY_SEPARATOR, $sClassName) . $this->_sFileExtension;
            if ($this->_sIncludePath !== '') {
                $fileName = $this->_sIncludePath . DIRECTORY_SEPARATOR . $fileName;
            }
            $filePath = stream_resolve_include_path($fileName);
            if ($filePath !== false) {
                require $filePath;
            }

            return ($filePath !== false);
        } else {
            return false;
        }
    }
}
