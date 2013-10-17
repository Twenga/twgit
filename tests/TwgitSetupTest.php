<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 */
class TwgitSetupTest extends TwgitTestCase
{

    /**
    * Sets up the fixture, for example, open a network connection.
    * This method is called before a test is executed.
    */
    public function setUp ()
    {
        $o = self::_getShellInstance();
        $o->remove(TWGIT_REPOSITORY_ORIGIN_DIR);
        $o->remove(TWGIT_REPOSITORY_LOCAL_DIR);
        $o->remove(TWGIT_REPOSITORY_SECOND_REMOTE_DIR);
        $o->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_SECOND_REMOTE_DIR, '0777');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_configured
     */
    public function testAssertGitConfigured_ThrowExcpetionWhenUnknownUsername ()
    {
        $this->_localExec("git init && git config user.name ''");
        $this->setExpectedException('RuntimeException', 'Unknown user.name!');
        $this->_localFunctionCall('assert_git_configured');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_configured
     */
    public function testAssertGitConfigured_ThrowExcpetionWhenUnknownUserEmail ()
    {
        $this->_localExec(
            "git init && \\
            git config user.name 'Firstname Lastname' && \\
            git config user.email ''"
        );
        $this->setExpectedException('RuntimeException', 'Unknown user.email!');
        $this->_localFunctionCall('assert_git_configured');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_configured
     */
    public function testAssertGitConfigured_OK ()
    {
        $this->_localExec(
            "git init && \\
            git config user.name 'Firstname Lastname' && \\
            git config user.email 'firstname.lastname@xyz.com'"
        );
        $sMsg = $this->_localFunctionCall('assert_git_configured');
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_ThrowExcpetionWhenNoRemoteRepository ()
    {
        $this->_localExec('git init && git remote add ' . self::ORIGIN . ' bad_repository_url');
        $this->setExpectedException('RuntimeException', "Could not fetch '" . self::ORIGIN . "'!");
        $this->_localFunctionCall('process_fetch');
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_ThrowExcpetionWhenBadRemoteRepository ()
    {
        $this->_localExec('git init && git remote add ' . self::ORIGIN . ' ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('RuntimeException', "Could not fetch '" . self::ORIGIN . "'!");
        $this->_localFunctionCall('process_fetch');
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_WithBadRemoteRepositoryAndSettedOption ()
    {
        $this->_localExec('git init && git remote add ' . self::ORIGIN . ' ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $sCmd = 'process_options -F; process_fetch F';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_WithoutOption ()
    {
        $this->_remoteExec('git init');
        $this->_localExec('git init && git remote add ' . self::ORIGIN . ' ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $sMsg = $this->_localFunctionCall('process_fetch');
        $this->assertEquals('git# git fetch --prune ' . self::ORIGIN, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_WithoutSettedOption ()
    {
        $this->_remoteExec('git init');
        $this->_localExec('git init && git remote add ' . self::ORIGIN . ' ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $sMsg = $this->_localFunctionCall('process_fetch x');
        $this->assertEquals('git# git fetch --prune ' . self::ORIGIN . "\n", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_ThrowExcpetionWhenNotGitRepository ()
    {
        $this->setExpectedException('RuntimeException', '[Git error msg] fatal: Not a git repository');
        $this->_localFunctionCall('assert_git_repository');
    }


    /**
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_ThrowExcpetionWhenNoRemoteRepository ()
    {
        $this->_localExec('git init');
        $this->setExpectedException('RuntimeException', "No remote '" . self::ORIGIN . "' repository specified!");
        $this->_localFunctionCall('assert_git_repository');
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testAssertGitRepository_ThrowExcpetionWhenBadRemoteRepository ()
    {
        $this->_localExec('git init && git remote add ' . self::ORIGIN . ' ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('RuntimeException', "Could not fetch '" . self::ORIGIN . "'!");
        $this->_localFunctionCall('assert_git_repository');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_ThrowExcpetionWhenStableBranchNotFound ()
    {
        $this->_remoteExec('git init');
        $this->_localExec('git init && git remote add ' . self::ORIGIN . ' ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('RuntimeException', 'Remote ' . self::STABLE . ' branch not found');
        $this->_localFunctionCall('assert_git_repository');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_ThrowExcpetionWhenNoTagFound ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            git remote add " . self::ORIGIN . " " . TWGIT_REPOSITORY_ORIGIN_DIR . " && \\
            git commit --allow-empty -m 'initial commit' && \\
            git branch -m " . self::STABLE . " && \\
            git push --set-upstream " . self::ORIGIN . " " . self::STABLE
        );
        $this->setExpectedException('RuntimeException', 'No tag found');
        $this->_localFunctionCall('assert_git_repository');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_OK ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            git remote add " . self::ORIGIN . " " . TWGIT_REPOSITORY_ORIGIN_DIR . " && \\
            git commit --allow-empty -m 'initial commit' && \\
            git branch -m " . self::STABLE . " && \\
            git push --set-upstream " . self::ORIGIN . " " . self::STABLE . " && \\
            git tag -a v1.0.0 -m 'first tag' && \\
            git push --tags " . self::ORIGIN . " " . self::STABLE
        );
        $sMsg = $this->_localFunctionCall('assert_git_repository');
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_connectors_well_configured
     */
    public function testAssertConnectorsWellConfigured_ThrowExceptionWhenConnectorNotFound ()
    {
        $sMsg = "/!\ 'X' connector not found! Please adjust TWGIT_FEATURE_SUBJECT_CONNECTOR in 'F'.";
        $this->setExpectedException('RuntimeException', $sMsg);

        $sCmd = 'config_file=\'F\'; TWGIT_FEATURE_SUBJECT_CONNECTOR=\'X\'; assert_connectors_well_configured';
        $sMsg = $this->_localShellCodeCall($sCmd);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_connectors_well_configured
     */
    public function testAssertConnectorsWellConfigured_ThrowExceptionWhenWgetNotFound ()
    {
        $sMsg = "/!\ Feature's subject not available because wget was not found! "
              . "Install it (e.g.: apt-get install wget) or switch off connectors in 'F'.";
        $this->setExpectedException('RuntimeException', $sMsg);

        $sWgetPath = $this->_exec('which wget');
        $sPath = $this->_exec('echo $PATH');
        $sPathWOWget = preg_replace('#(^|:)' . substr($sWgetPath, 0, -5) . '(:|$)#', ':', $sPath);
        $sCmd = "PATH='$sPathWOWget'; "
              . 'config_file=\'F\'; TWGIT_FEATURE_SUBJECT_CONNECTOR=\'github\'; assert_connectors_well_configured';
        $sMsg = $this->_localShellCodeCall($sCmd);
    }

    /**
     * @dataProvider providerTestAssertConnectorsWellConfigured_WithConnectorAndWget
     * @shcovers inc/common.inc.sh::assert_connectors_well_configured
     */
    public function testAssertConnectorsWellConfigured_WithConnectorAndWget ($sConnector)
    {
        $sCmd = 'config_file=\'F\'; TWGIT_FEATURE_SUBJECT_CONNECTOR=\''
              . $sConnector . '\'; assert_connectors_well_configured';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    public function providerTestAssertConnectorsWellConfigured_WithConnectorAndWget ()
    {
        return array(
            array(''),
            array('github'),
            array('redmine'),
        );
    }

    /**
     * @dataProvider providerTestAlertDissidentBranches
     * @shcovers inc/common.inc.sh::alert_dissident_branches
     */
    public function testAlertDissidentBranches ($sLocalCmd, $sExpectedResult)
    {
        $this->_remoteExec('git init && git commit --allow-empty -m "-" && git checkout -b feature-currentOfNonBareRepo');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('cd ' . TWGIT_REPOSITORY_SECOND_REMOTE_DIR . ' && git init');
        $this->_localExec('git remote add second ' . TWGIT_REPOSITORY_SECOND_REMOTE_DIR);

        $this->_localExec($sLocalCmd);
        $sMsg = $this->_localFunctionCall('alert_dissident_branches');
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerTestAlertDissidentBranches ()
    {
        return array(
            array(':', ''),
            array(
                'git checkout -b feature-X && git push ' . self::ORIGIN . ' feature-X'
                    . ' && git checkout -b release-X && git push ' . self::ORIGIN . ' release-X'
                    . ' && git checkout -b hotfix-X && git push ' . self::ORIGIN . ' hotfix-X'
                    . ' && git checkout -b demo-X && git push ' . self::ORIGIN . ' demo-X'
                    . ' && git checkout -b master && git push ' . self::ORIGIN . ' master'
                    . ' && git checkout -b outofprocess && git push ' . self::ORIGIN . ' outofprocess'
                    . ' && git remote set-head ' . self::ORIGIN . ' ' . self::STABLE,
                "/!\ Following branches are out of process: '" . self::_remote('outofprocess') . "'!\n"
            ),
            array(
                'git checkout -b outofprocess && git push ' . self::ORIGIN . ' outofprocess && git push second outofprocess'
                    . ' && git checkout -b out2 && git push ' . self::ORIGIN . ' out2 && git push second out2',
                "/!\ Following branches are out of process: '" . self::_remote('out2') . "', '" . self::_remote('outofprocess') . "'!\n"
            ),
            array(
                'git branch v1.2.3 v1.2.3',
                "/!\ Following local branches are ambiguous: 'v1.2.3'!\n"
            ),
            array(
                'git checkout -b outofprocess && git push ' . self::ORIGIN . ' outofprocess && git branch v1.2.3 v1.2.3',
                "/!\ Following branches are out of process: '" . self::_remote('outofprocess') . "'!\n"
                    . "/!\ Following local branches are ambiguous: 'v1.2.3'!\n"
            ),
        );
    }
}
