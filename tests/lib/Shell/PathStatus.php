<?php

/**
 * Collection des statuts possibles pour un chemin du système de fichiers.
 *
 * @package Lib
 * @copyright 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
 * @license http://www.apache.org/licenses/LICENSE-2.0
 * @see Shell_Interface::getPathStatus()
 */
final class Shell_PathStatus
{
    /**
     * Le chemin n'existe pas.
     * @var int
     */
    const STATUS_NOT_EXISTS = 0;

    /**
     * Le chemin est un fichier.
     * @var int
     */
    const STATUS_FILE = 1;

    /**
     * Le chemin est un répertoire.
     * @var int
     */
    const STATUS_DIR = 2;

    /**
     * Le chemin est un lien symbolique cassé.
     * @var int
     */
    const STATUS_BROKEN_SYMLINK = 10;

    /**
     * Le chemin est un lien symbolique pointant sur un fichier.
     * @var int
     */
    const STATUS_SYMLINKED_FILE = 11;

    /**
     * Le chemin est un lien symbolique pointant sur un répertoire.
     * @var int
     */
    const STATUS_SYMLINKED_DIR = 12;

    /**
     * Classe de constantes, non instanciable.
     */
    private function __construct()
    {
    }
}
