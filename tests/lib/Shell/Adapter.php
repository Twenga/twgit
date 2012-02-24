<?php

/**
 * Classe outil facilitant l'exécution des commandes shell.
 *
 * @package Lib
 * @author Geoffroy AUBRY <geoffroy.aubry@free.fr>
 */
class Shell_Adapter implements Shell_Interface
{

    /**
     * Table de hashage de mise en cache des demande de statuts de chemins système.
     * @var array
     * @see getPathStatus()
     * @see Shell_PathStatus
     */
    private $_aFileStatus;

    /**
     * Liste d'exclusions par défaut de toute commande rsync (traduits en --exclude xxx).
     * @var array
     * @see sync()
     */
    private static $_aDefaultRsyncExclude = array(
        '.bzr/', '.cvsignore', '.git/', '.gitignore', '.svn/', 'cvslog.*', 'CVS', 'CVS.adm'
    );

    /**
     * Constructeur.
     */
    public function __construct ()
    {
        $this->_aFileStatus = array();
    }

    /**
     * Exécute dans des processus parallèles les déclinaisons du pattern spécifié en fonction des valeurs.
     * Plusieurs lots de processus parallèles peuvent être générés si le nombre de valeurs
     * dépasse la limite $iMax.
     *
     * Exemple : $this->parallelize(array('aai@aai-01', 'prod@aai-01'), "ssh [] /bin/bash <<EOF\nls -l\nEOF\n");
     * Exemple : $this->parallelize(array('a', 'b'), 'cat /.../resources/[].txt');
     *
     * @param array $aValues liste de valeurs qui viendront remplacer le(s) '[]' du pattern
     * @param string $sPattern pattern possédant une ou plusieurs occurences de paires de crochets vides '[]'
     * qui seront remplacées dans les processus lancés en parallèle par l'une des valeurs spécifiées.
     * @param int $iMax nombre maximal de processus lancés en parallèles
     * @return array liste de tableau associatif : array(
     *     array(
     *         'value' => (string)"l'une des valeurs de $aValues",
     *         'error_code' => (int)code de retour Shell,
     *         'elapsed_time' => (int) temps approximatif en secondes,
     *         'cmd' => (string) commande shell exécutée,
     *         'output' => (string) sortie standard,
     *         'error' => (string) sortie d'erreur standard,
     *     ), ...
     * )
     * @throws RuntimeException si le moindre code de retour Shell non nul apparaît.
     * @throws RuntimeException si une valeur hors de $aValues apparaît dans les entrées 'value'.
     * @throws RuntimeException s'il manque des valeurs de $aValues dans le résultat final.
     */
    public function parallelize (array $aValues, $sPattern, $iMax=DEPLOYMENT_PARALLELIZATION_MAX_NB_PROCESSES)
    {
        // Segmentation de la demande de parallélisation en lots séquentiels de taille maîtrisée :
        $aAllValues = $aValues;
        $aAllResults = array();
        while (count($aValues) > $iMax) {
            $aSubset = array_slice($aValues, 0, $iMax);
            $aAllResults = array_merge($aAllResults, $this->parallelize($aSubset, $sPattern, $iMax));
            $aValues = array_slice($aValues, $iMax);
        }

        // Exécution de la demande de parallélisation :
        $sCmdPattern = DEPLOYMENT_BASH_PATH . ' ' . DEPLOYMENT_LIB_DIR . '/parallelize.inc.sh "%s" "%s"';
        $sCmd = sprintf($sCmdPattern, addcslashes(implode(' ', $aValues), '"'), addcslashes($sPattern, '"'));
        $aExecResult = $this->exec($sCmd);

        // Découpage du flux de retour d'exécution :
        $sResult = implode("\n", $aExecResult) . "\n";
        $sRegExp = '#^---\[(.*?)\]-->(\d+)\|(\d+)s\n\[CMD\]\n(.*?)\n\[OUT\]\n(.*?)\[ERR\]\n(.*?)///#ms';
        preg_match_all($sRegExp, $sResult, $aMatches, PREG_SET_ORDER);

        // Formatage des résultats :
        $aResult = array();
        foreach ($aMatches as $aSet) {
            $aResult[] = array(
                'value' => $aSet[1],
                'error_code' => (int)$aSet[2],
                'elapsed_time' => (int)$aSet[3],
                'cmd' => $aSet[4],
                'output' => (strlen($aSet[5]) > 0 ? substr($aSet[5], 0, -1) : ''),
                'error' => (strlen($aSet[6]) > 0 ? substr($aSet[6], 0, -1) : '')
            );
        }

        // Pas de code d'erreur shell ni de valeur non attendue ?
        foreach ($aResult as $aSubResult) {
            if ($aSubResult['error_code'] !== 0) {
                $sMsg = $aSubResult['error'] . "\nParallel result:\n" . print_r($aResult, true);
                throw new RuntimeException($sMsg, $aSubResult['error_code']);
            } else if ( ! in_array($aSubResult['value'], $aValues)) {
                $sMsg = "Not asked value: '" . $aSubResult['value'] . "'!\n"
                      . "Aksed values: '" . implode("', '", $aValues) . "'\n"
                      . "Parallel result:\n" . print_r($aResult, true);
                throw new RuntimeException($sMsg, 1);
            }
        }

        // Tous le monde est-il là ?
        $aAllResults = array_merge($aAllResults, $aResult);
        if (count($aAllResults) != count($aAllValues)) {
            $sMsg = "Missing values!\n"
                  . "Aksed values: '" . implode("', '", $aValues) . "'\n"
                  . "Parallel result:\n" . print_r($aAllResults, true);
            throw new RuntimeException($sMsg, 1);
        }

        return $aAllResults;
    }

    /**
     * Exécute la commande shell spécifiée et retourne la sortie découpée par ligne dans un tableau.
     * En cas d'erreur shell (code d'erreur <> 0), lance une exception incluant le message d'erreur.
     *
     * @param string $sCmd
     * @return array tableau indexé du flux de sortie shell découpé par ligne
     * @throws RuntimeException en cas d'erreur shell
     */
    public function exec ($sCmd)
    {
        $sFullCmd = '( ' . $sCmd . ' ) 2>&1';
        exec($sFullCmd, $aResult, $iReturnCode);
        if ($iReturnCode !== 0) {
            throw new RuntimeException(implode("\n", $aResult), $iReturnCode);
        }
        return $aResult;
    }

    /**
     * Exécute la commande shell spécifiée en l'encapsulant au besoin dans une connexion SSH
     * pour atteindre les hôtes distants.
     *
     * @param string $sPatternCmd commande au format printf
     * @param string $sParam paramètre du pattern $sPatternCmd, permettant en plus de décider si l'on
     * doit encapsuler la commande dans un SSH (si serveur distant) ou non.
     * @return array tableau indexé du flux de sortie shell découpé par ligne
     * @throws RuntimeException en cas d'erreur shell
     * @see isRemotePath()
     */
    public function execSSH ($sPatternCmd, $sParam)
    {
        return $this->exec($this->buildSSHCmd($sPatternCmd, $sParam));
    }

    /**
     * Retourne la commande Shell spécifiée envoyée à sprintf avec $sParam,
     * et encapsule au besoin le tout dans une connexion SSH
     * pour atteindre les hôtes distants (si $sParam est un hôte distant).
     *
     * @param string $sPatternCmd commande au format printf
     * @param string $sParam paramètre du pattern $sPatternCmd, permettant en plus de décider si l'on
     * doit encapsuler la commande dans un SSH (si serveur distant) ou non.
     * @return string la commande Shell spécifiée envoyée à sprintf avec $sParam,
     * et encapsule au besoin le tout dans une connexion SSH
     * pour atteindre les hôtes distants (si $sParam est un hôte distant).
     * @see isRemotePath()
     */
    public function buildSSHCmd ($sPatternCmd, $sParam)
    {
        list($bIsRemote, $sServer, $sRealPath) = $this->isRemotePath($sParam);
        $sCmd = sprintf($sPatternCmd, $this->escapePath($sRealPath));
        //$sCmd = vsprintf($sPatternCmd, array_map(array(self, 'escapePath'), $mParams));
        if ($bIsRemote) {
            $sSSHOptions = ' -o StrictHostKeyChecking=no'
                         . ' -o ConnectTimeout=' . DEPLOYMENT_SSH_CONNECTION_TIMEOUT
                         . ' -o BatchMode=yes';
            $sCmd = "ssh$sSSHOptions -T $sServer " . DEPLOYMENT_BASH_PATH . " <<EOF\n$sCmd\nEOF\n";
        }
        return $sCmd;
    }

    /**
     * Retourne l'une des constantes de Shell_PathStatus, indiquant pour le chemin spécifié s'il est
     * inexistant, un fichier, un répertoire, un lien symbolique sur fichier ou encore un lien symbolique sur
     * répertoire.
     *
     * Les éventuels slash terminaux sont supprimés.
     * Si le statut est différent de inexistant, l'appel est mis en cache.
     * Un appel à remove() s'efforce de maintenir cohérent ce cache.
     *
     * Le chemin spécifié peut concerner un hôte distant (user@server:/path), auquel cas un appel SSH sera effectué.
     *
     * @param string $sPath chemin à tester, de la forme [user@server:]/path
     * @return int l'une des constantes de Shell_PathStatus
     * @throws RuntimeException en cas d'erreur shell
     * @see Shell_PathStatus
     * @see _aFileStatus
     */
    public function getPathStatus ($sPath)
    {
        if (substr($sPath, -1) === '/') {
            $sPath = substr($sPath, 0, -1);
        }
        if (isset($this->_aFileStatus[$sPath])) {
            $iStatus = $this->_aFileStatus[$sPath];
        } else {
            $sFormat = '[ -h %1$s ] && echo -n 1; [ -d %1$s ] && echo 2 || ([ -f %1$s ] && echo 1 || echo 0)';
            //$aResult = $this->execSSH($sFormat, $sPath);
            $aResult = $this->exec($this->buildSSHCmd($sFormat, $sPath));
            $iStatus = (int)$aResult[0];
            if ($iStatus !== 0) {
                $this->_aFileStatus[$sPath] = $iStatus;
            }
        }
        return $iStatus;
    }

    /**
     * Pour chaque serveur retourne l'une des constantes de Shell_PathStatus, indiquant pour le chemin spécifié
     * s'il est inexistant, un fichier, un répertoire, un lien symbolique sur fichier
     * ou encore un lien symbolique sur répertoire.
     *
     * Comme getPathStatus(), mais sur une liste de serveurs.
     *
     * Les éventuels slash terminaux sont supprimés.
     * Si le statut est différent de inexistant, l'appel est mis en cache.
     * Un appel à remove() s'efforce de maintenir cohérent ce cache.
     *
     * @param string $sPath chemin à tester, sans mention de serveur
     * @param array $aServers liste de serveurs sur lesquels faire la demande de statut
     * @return array tableau associatif listant par serveur (clé) le status (valeur, constante de Shell_PathStatus)
     * @throws RuntimeException en cas d'erreur shell
     * @see getPathStatus()
     */
    public function getParallelSSHPathStatus ($sPath, array $aServers)
    {
        if (substr($sPath, -1) === '/') {
            $sPath = substr($sPath, 0, -1);
        }

        // Déterminer les serveurs pour lesquels nous n'avons pas la réponse en cache :
        $aResult = array();
        foreach ($aServers as $sServer) {
            $sKey = $sServer . ':' . $sPath;
            if (isset($this->_aFileStatus[$sKey])) {
                $aResult[$sServer] = $this->_aFileStatus[$sKey];
            }
        }
        $aServersToCheck = array_diff($aServers, array_keys($aResult));

        // Paralléliser l'appel sur chacun des serveurs restants :
        if (count($aServersToCheck) > 0) {
            $sFormat = '[ -h %1$s ] && echo -n 1; [ -d %1$s ] && echo 2 || ([ -f %1$s ] && echo 1 || echo 0)';
            $sPattern = $this->buildSSHCmd($sFormat, '[]:' . $sPath);
            $aParallelResult = $this->parallelize($aServersToCheck, $sPattern);

            // Traiter les résultats et MAJ le cache :
            foreach ($aParallelResult as $aServerResult) {
                $sServer = $aServerResult['value'];
                $iStatus = (int)$aServerResult['output'];
                if ($iStatus !== 0) {
                    $this->_aFileStatus[$sServer . ':' . $sPath] = $iStatus;
                }
                $aResult[$sServer] = $iStatus;
            }
        }

        return $aResult;
    }

    /**
     * Retourne un triplet dont la 1re valeur (bool) indique si le chemin spécifié commence par
     * '[user@]servername_or_ip:', la 2e (string) est le serveur (ou chaîne vide si $sPath est local),
     * et la 3e (string) est le chemin dépourvu de l'éventuel serveur.
     *
     * @param string $sPath chemin au format [[user@]servername_or_ip:]/path
     * @return array triplet dont la 1re valeur (bool) indique si le chemin spécifié commence par
     * '[user@]servername_or_ip:', la 2e (string) est le serveur (ou chaîne vide si $sPath est local),
     * et la 3e (string) est le chemin dépourvu de l'éventuel serveur.
     */
    public function isRemotePath ($sPath)
    {
        $result = preg_match('/^((?:[^@]+@)?[^:]+):(.+)$/i', $sPath, $aMatches);
        $bIsRemotePath = ($result === 1);
        if ($bIsRemotePath) {
            $sServer = $aMatches[1];
            $sRealPath = $aMatches[2];
        } else {
            $sServer = '';
            $sRealPath = $sPath;
        }

        return array($bIsRemotePath, $sServer, $sRealPath);
    }

    /**
     * Copie un chemin vers un autre.
     * Les jokers '*' et '?' sont autorisés.
     * Par exemple copiera le contenu de $sSrcPath si celui-ci se termine par '/*'.
     * Si le chemin de destination n'existe pas, il sera créé.
     *
     * @param string $sSrcPath chemin source, au format [[user@]hostname_or_ip:]/path
     * @param string $sDestPath chemin de destination, au format [[user@]hostname_or_ip:]/path
     * @param bool $bIsDestFile précise si le chemin de destination est un simple fichier ou non,
     * information nécessaire si l'on doit créer une partie de ce chemin si inexistant
     * @return array tableau indexé du flux de sortie shell découpé par ligne
     * @throws RuntimeException en cas d'erreur shell
     */
    public function copy ($sSrcPath, $sDestPath, $bIsDestFile=false)
    {
        if ($bIsDestFile) {
            $this->mkdir(pathinfo($sDestPath, PATHINFO_DIRNAME));
        } else {
            $this->mkdir($sDestPath);
        }
        list(, $sSrcServer, ) = $this->isRemotePath($sSrcPath);
        list(, $sDestServer, $sDestRealPath) = $this->isRemotePath($sDestPath);

        if ($sSrcServer != $sDestServer) {
            $sCmd = 'scp -rpq ' . $this->escapePath($sSrcPath) . ' ' . $this->escapePath($sDestPath);
            return $this->exec($sCmd);
        } else {
            $sCmd = 'cp -a %s ' . $this->escapePath($sDestRealPath);
            return $this->execSSH($sCmd, $sSrcPath);
        }
    }

    /**
     * Crée un lien symbolique de chemin $sLinkPath vers la cible $sTargetPath.
     *
     * @param string $sLinkPath nom du lien, au format [[user@]hostname_or_ip:]/path
     * @param string $sTargetPath cible sur laquelle faire pointer le lien, au format [[user@]hostname_or_ip:]/path
     * @return array tableau indexé du flux de sortie shell découpé par ligne
     * @throws DomainException si les chemins référencent des serveurs différents
     * @throws RuntimeException en cas d'erreur shell
     */
    public function createLink ($sLinkPath, $sTargetPath)
    {
        list(, $sLinkServer, ) = $this->isRemotePath($sLinkPath);
        list(, $sTargetServer, $sTargetRealPath) = $this->isRemotePath($sTargetPath);
        if ($sLinkServer != $sTargetServer) {
            throw new DomainException("Hosts must be equals. Link='$sLinkPath'. Target='$sTargetPath'.");
        }
        $aResult = $this->execSSH('mkdir -p "$(dirname %1$s)" && ln -snf "' . $sTargetRealPath . '" %1$s', $sLinkPath);
        // TODO optimisation possible :
        // $this->_aFileStatus[$sPath] = Shell_PathStatus::STATUS_SYMLINKED_DIR ou STATUS_SYMLINKED_FILE;
        return $aResult;
    }

    /**
     * Entoure le chemin de guillemets doubles en tenant compte des jokers '*' et '?' qui ne les supportent pas.
     * Par exemple : '/a/b/img*jpg', donnera : '"/a/b/img"*"jpg"'.
     * Pour rappel, '*' vaut pour 0 à n caractères, '?' vaut pour exactement 1 caractère (et non 0 à 1).
     *
     * @param string $sPath
     * @return string
     */
    public function escapePath ($sPath)
    {
        $sEscapedPath = preg_replace('#(\*|\?)#', '"\1"', '"' . $sPath . '"');
        $sEscapedPath = str_replace('""', '', $sEscapedPath);
        return $sEscapedPath;
    }

    /**
     * Supprime le chemin spécifié, répertoire ou fichier, distant ou local.
     * S'efforce de maintenir cohérent le cache de statut de chemins rempli par getPathStatus().
     *
     * @param string $sPath chemin à supprimer, au format [[user@]hostname_or_ip:]/path
     * @return array tableau indexé du flux de sortie shell découpé par ligne
     * @throws DomainException si chemin invalide (garde-fou)
     * @throws RuntimeException en cas d'erreur shell
     * @see getPathStatus()
     */
    public function remove ($sPath)
    {
        $sPath = trim($sPath);

        // Garde-fou :
        if (empty($sPath) || strlen($sPath) < 4) {
            throw new DomainException("Illegal path: '$sPath'");
        }

        // Supprimer du cache de getPathStatus() :
        foreach (array_keys($this->_aFileStatus) as $sCachedPath) {
            if (substr($sCachedPath, 0, strlen($sPath)+1) === $sPath . '/') {
                unset($this->_aFileStatus[$sCachedPath]);
            }
        }
        unset($this->_aFileStatus[$sPath]);

        return $this->execSSH('rm -rf %s', $sPath);
    }

    /**
     * Effectue un tar gzip du répertoire $sSrcPath dans $sBackupPath.
     *
     * @param string $sSrcPath au format [[user@]hostname_or_ip:]/path
     * @param string $sBackupPath au format [[user@]hostname_or_ip:]/path
     * @return array tableau indexé du flux de sortie shell découpé par ligne
     * @throws RuntimeException en cas d'erreur shell
     */
    public function backup ($sSrcPath, $sBackupPath)
    {
        list($bIsSrcRemote, $sSrcServer, $sSrcRealPath) = $this->isRemotePath($sSrcPath);
        list(, $sBackupServer, $sBackupRealPath) = $this->isRemotePath($sBackupPath);

        if ($sSrcServer != $sBackupServer) {
            $sTmpDir = ($bIsSrcRemote ? $sSrcServer. ':' : '') . TWGIT_TMP_DIR . '/'
                     . uniqid('deployment_', true);
            $sTmpPath = $sTmpDir . '/' . pathinfo($sBackupPath, PATHINFO_BASENAME);
            return array_merge(
                $this->backup($sSrcPath, $sTmpPath),
                $this->copy($sTmpPath, $sBackupPath, true),
                $this->remove($sTmpDir)
            );
        } else {
            $this->mkdir(pathinfo($sBackupPath, PATHINFO_DIRNAME));
            $sSrcFile = pathinfo($sSrcRealPath, PATHINFO_BASENAME);
            $sFormat = 'cd %1$s; tar cfpz %2$s ./%3$s';
            if ($bIsSrcRemote) {
                $sSrcDir = pathinfo($sSrcRealPath, PATHINFO_DIRNAME);
                $sFormat = 'ssh %4$s <<EOF' . "\n" . $sFormat . "\nEOF\n";
                $sCmd = sprintf(
                    $sFormat,
                    $this->escapePath($sSrcDir),
                    $this->escapePath($sBackupRealPath),
                    $this->escapePath($sSrcFile),
                    $sSrcServer
                );
            } else {
                $sSrcDir = pathinfo($sSrcPath, PATHINFO_DIRNAME);
                $sCmd = sprintf(
                    $sFormat,
                    $this->escapePath($sSrcDir),
                    $this->escapePath($sBackupPath),
                    $this->escapePath($sSrcFile)
                );
            }
            return $this->exec($sCmd);
        }
    }

    /**
     * Crée le chemin spécifié s'il n'existe pas déjà, avec les droits éventuellement transmis dans tous les cas.
     *
     * @param string $sPath chemin à créer, au format [[user@]hostname_or_ip:]/path
     * @param string $sMode droits utilisateur du chemin appliqués même si ce dernier existe déjà.
     * Par exemple '644'.
     * @return array tableau indexé du flux de sortie shell découpé par ligne
     * @throws RuntimeException en cas d'erreur shell
     */
    /*public function mkdir ($sPath, $sMode='')
    {
        // On passe par 'chmod' car 'mkdir -m xxx' exécuté ssi répertoire inexistant :
        if ($sMode !== '') {
            $sMode = " && chmod $sMode %1\$s";
        }
        $aResult = $this->execSSH("mkdir -p %1\$s$sMode", $sPath);
        $this->_aFileStatus[$sPath] = Shell_PathStatus::STATUS_DIR;
        return $aResult;
    }*/
    public function mkdir ($sPath, $sMode='', array $aValues=array())
    {
        // On passe par 'chmod' car 'mkdir -m xxx' exécuté ssi répertoire inexistant :
        if ($sMode !== '') {
            $sMode = " && chmod $sMode %1\$s";
        }
        $sPattern = "mkdir -p %1\$s$sMode";
        $sCmd = $this->buildSSHCmd($sPattern, $sPath);
        //var_dump($sPath, $sPattern, $sCmd);

        if (strpos($sPath, '[]') !== false && count($aValues) > 0) {
            $aParallelResult = $this->parallelize($aValues, $sCmd);

            // Traiter les résultats et MAJ le cache :
            $aResult = array();
            foreach ($aParallelResult as $aServerResult) {
                $sValue = $aServerResult['value'];
                $sOutput = $aServerResult['output'];
                $sFinalPath = str_replace('[]', $sValue, $sPath);
                $this->_aFileStatus[$sFinalPath] = Shell_PathStatus::STATUS_DIR;
                if (strlen($sOutput) > 0) {
                    $aResult[] = "$sValue: $sOutput";
                }
            }
        } else {
            $aResult = $this->exec($sCmd);
            $this->_aFileStatus[$sPath] = Shell_PathStatus::STATUS_DIR;
        }
        return $aResult;
    }

    /**
     * Synchronise une source avec une ou plusieurs destinations.
     *
     * @param string $sSrcPath au format [[user@]hostname_or_ip:]/path
     * @param string|array $mDestPath chaque destination au format [[user@]hostname_or_ip:]/path
     * @param array $aValues liste de valeurs (string) optionnelles pour générer autant de demande de
     * synchronisation en parallèle. Dans ce cas ces valeurs viendront remplacer l'une après l'autre
     * les occurences de crochets vide '[]' présents dans $sSrcPath ou $sDestPath.
     * @param array $aIncludedPaths chemins à transmettre aux paramètres --include de la commande shell rsync.
     * Il précéderons les paramètres --exclude.
     * @param array $aExcludedPaths chemins à transmettre aux paramètres --exclude de la commande shell rsync
     * @return array tableau indexé du flux de sortie shell des commandes rsync exécutées,
     * découpé par ligne et analysé par _resumeSyncResult()
     * @throws RuntimeException en cas d'erreur shell
     * @throws RuntimeException car non implémenté quand plusieurs $mDestPath et $sSrcPath sont distants
     */
    public function sync ($sSrcPath, $sDestPath, array $aValues=array(),
            array $aIncludedPaths=array(), array $aExcludedPaths=array())
    {
        // Cas non gérés :
        list($bIsSrcRemote, $sSrcServer, $sSrcRealPath) = $this->isRemotePath($sSrcPath);
        list($bIsDestRemote, $sDestServer, $sDestRealPath) = $this->isRemotePath($sDestPath);
        $this->mkdir($sDestPath, '', $aValues);

        // Inclusions / exclusions :
        $sIncludedPaths = (count($aIncludedPaths) === 0
                              ? ''
                              : '--include="' . implode('" --include="', array_unique($aIncludedPaths)) . '" ');
        $aExcludedPaths = array_unique(array_merge(self::$_aDefaultRsyncExclude, $aExcludedPaths));
        $sExcludedPaths = (count($aExcludedPaths) === 0
                              ? ''
                              : '--exclude="' . implode('" --exclude="', $aExcludedPaths) . '" ');

        // Construction de la commande :
        $sRsyncCmd = sprintf(
            'rsync -axz --delete %s%s--stats -e ssh %s %s',
            $sIncludedPaths, $sExcludedPaths, '%s', '%s'
        );
        if (substr($sSrcPath, -2) === '/*') {
            $sRsyncCmd = 'if ls -1 "' . substr($sSrcRealPath, 0, -2) . '" | grep -q .; then ' . $sRsyncCmd . '; fi';
        }
        if ($bIsSrcRemote && $bIsDestRemote) {
            $sFinalDestPath = ($sSrcServer == $sDestServer ? $sDestRealPath : $sDestPath);
            $sRsyncCmd = sprintf($sRsyncCmd, '%s', $this->escapePath($sFinalDestPath));
            $sRsyncCmd = $this->buildSSHCmd($sRsyncCmd, $sSrcPath);
        } else {
            $sRsyncCmd = sprintf($sRsyncCmd, $this->escapePath($sSrcPath), $this->escapePath($sDestPath));
        }

        if (count($aValues) === 0 || (count($aValues) === 1 && $aValues[0] == '')) {
            $aValues=array('-');
        }
        $aParallelResult = $this->parallelize($aValues, $sRsyncCmd, DEPLOYMENT_RSYNC_MAX_NB_PROCESSES);
        $aAllResults = array();
        foreach ($aParallelResult as $aServerResult) {
            if ($aServerResult['value'] == '-') {
                $sHeader = '';
            } else {
                $sHeader = "Server: " . $aServerResult['value']
                         . ' (~' . $aServerResult['elapsed_time'] . 's)' . "\n";
            }
            $aRawOutput = explode("\n", $aServerResult['output']);
            $aOutput = $this->_resumeSyncResult($aRawOutput);
            $aOutput = array($sHeader . $aOutput[0]);
            $aAllResults = array_merge($aAllResults, $aOutput);
        }

        return $aAllResults;
    }

    /**
     * Analyse la sortie shell de commandes rsync et en propose un résumé.
     *
     * Exemple :
     *  - entrée :
     *  	Number of files: 1774
     *  	Number of files transferred: 2
     *  	Total file size: 64093953 bytes
     *  	Total transferred file size: 178 bytes
     *  	Literal data: 178 bytes
     *  	Matched data: 0 bytes
     *  	File list size: 39177
     *  	File list generation time: 0.013 seconds
     *  	File list transfer time: 0.000 seconds
     *  	Total bytes sent: 39542
     *  	Total bytes received: 64
     *  	sent 39542 bytes  received 64 bytes  26404.00 bytes/sec
     *  	total size is 64093953  speedup is 1618.29
     *  - sortie :
     *  	Number of transferred files ( / total): 2 / 1774
     *  	Total transferred file size ( / total): <1 / 61 Mio
     *
     * @param array $aRawResult tableau indexé du flux de sortie shell de la commande rsync, découpé par ligne
     * @return array du tableau indexé du flux de sortie shell de commandes rsync résumé
     * et découpé par ligne
     */
    private function _resumeSyncResult (array $aRawResult)
    {
        if (count($aRawResult) === 0 || (count($aRawResult) === 1 && $aRawResult[0] == '')) {
            $aResult = array('Empty source directory.');
        } else {
            $aKeys = array(
                'number of files',
                'number of files transferred',
                'total file size',
                'total transferred file size',
            );
            $aEmptyStats = array_fill_keys($aKeys, '?');

            $aAllStats = array();
            $aStats = NULL;
            foreach ($aRawResult as $sLine) {
                if (preg_match('/^([^:]+):\s(\d+)\b/i', $sLine, $aMatches) === 1) {
                    $sKey = strtolower($aMatches[1]);
                    if ($sKey === 'number of files') {
                        if ($aStats !== NULL) {
                            $aAllStats[] = $aStats;
                        }
                        $aStats = $aEmptyStats;
                    }
                    if (isset($aStats[$sKey])) {
                        $aStats[$sKey] = (int)$aMatches[2];
                    }
                }
            }
            if ($aStats !== NULL) {
                $aAllStats[] = $aStats;
            }

            $aResult = array();
            foreach ($aAllStats as $aStats) {
                list($sTransferred, ) = Tools::convertFileSize2String(
                    $aStats['total transferred file size'],
                    $aStats['total file size']
                );
                list($sTotal, $sUnit) = Tools::convertFileSize2String($aStats['total file size']);

                $aResult[] = 'Number of transferred files ( / total): ' . $aStats['number of files transferred']
                           . ' / ' . $aStats['number of files'] . "\n"
                           . 'Total transferred file size ( / total): '
                           . $sTransferred . ' / ' . $sTotal . " $sUnit";
            }
        }
        return $aResult;
    }
}
