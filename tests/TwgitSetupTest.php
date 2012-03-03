<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitSetupTest extends TwgitTestCase
{

    /**
    * This method is called before the first test of this test class is run.
    *
    * @since Method available since Release 3.4.0
    */
    public static function setUpBeforeClass ()
    {
        self::_rawExec('touch $HOME/.gitconfig && mv $HOME/.gitconfig $HOME/.gitconfig.BAK');
    }

    /**
     * This method is called after the last test of this test class is run.
     *
     * @since Method available since Release 3.4.0
     */
    public static function tearDownAfterClass ()
    {
        self::_rawExec('mv $HOME/.gitconfig.BAK $HOME/.gitconfig');
    }

    /**
    * Sets up the fixture, for example, open a network connection.
    * This method is called before a test is executed.
    */
    public function setUp ()
    {
        $o = self::_getShellInstance();
        $o->remove(TWGIT_REPOSITORY_ORIGIN_DIR);
        $o->remove(TWGIT_REPOSITORY_LOCAL_DIR);
        $o->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_configured
     */
    public function testAssertGitConfigured_ThrowExcpetionWhenUnknownUsername ()
    {
        $this->setExpectedException('RuntimeException', 'Unknown user.name!');
        $this->_localFunctionCall('assert_git_configured');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_configured
     */
    public function testAssertGitConfigured_ThrowExcpetionWhenUnknownUserEmail ()
    {
        $this->_exec("git config --global user.name 'Firstname Lastname'");
        $this->setExpectedException('RuntimeException', 'Unknown user.email!');
        $this->_localFunctionCall('assert_git_configured');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_configured
     */
    public function testAssertGitConfigured_OK ()
    {
        $this->_exec(
            "git config --global user.name 'Firstname Lastname' && \\
            git config --global user.email 'firstname.lastname@xyz.com'"
        );
        $sMsg = $this->_localFunctionCall('assert_git_configured');
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_ThrowExcpetionWhenNoRemoteRepository ()
    {
        $this->_localExec('git init && git remote add origin bad_repository_url');
        $this->setExpectedException('RuntimeException', "Could not fetch 'origin'!");
        $this->_localFunctionCall('process_fetch');
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_ThrowExcpetionWhenBadRemoteRepository ()
    {
        $this->_localExec('git init && git remote add origin ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('RuntimeException', "Could not fetch 'origin'!");
        $this->_localFunctionCall('process_fetch');
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_WithBadRemoteRepositoryAndSettedOption ()
    {
        $this->_localExec('git init && git remote add origin ' . TWGIT_REPOSITORY_ORIGIN_DIR);
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
        $this->_localExec('git init && git remote add origin ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $sMsg = $this->_localFunctionCall('process_fetch');
        $this->assertEquals('git# git fetch --prune origin', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_WithoutSettedOption ()
    {
        $this->_remoteExec('git init');
        $this->_localExec('git init && git remote add origin ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $sMsg = $this->_localFunctionCall('process_fetch x');
        $this->assertEquals('git# git fetch --prune origin' . "\n", $sMsg);
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
        $this->setExpectedException('RuntimeException', "No remote 'origin' repository specified!");
        $this->_localFunctionCall('assert_git_repository');
    }

    /**
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testAssertGitRepository_ThrowExcpetionWhenBadRemoteRepository ()
    {
        $this->_localExec('git init && git remote add origin ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('RuntimeException', "Could not fetch 'origin'!");
        $this->_localFunctionCall('assert_git_repository');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_ThrowExcpetionWhenStableBranchNotFound ()
    {
        $this->_remoteExec('git init');
        $this->_localExec('git init && git remote add origin ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('RuntimeException', 'Remote stable branch not found');
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
            git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR . " && \\
            git commit --allow-empty -m 'initial commit' && \\
            git branch -m stable && \\
            git push --set-upstream origin stable"
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
            git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR . " && \\
            git commit --allow-empty -m 'initial commit' && \\
            git branch -m stable && \\
            git push --set-upstream origin stable && \\
            git tag -a v1.0.0 -m 'first tag' && \\
            git push --tags origin stable"
        );
        $sMsg = $this->_localFunctionCall('assert_git_repository');
        $this->assertEmpty($sMsg);
    }
}
