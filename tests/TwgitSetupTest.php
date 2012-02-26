<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitSetupTest extends PHPUnit_Framework_TestCase
{

    /**
     * @var Shell_Adapter
     */
    private $_oShell;

    /**
    * This method is called before the first test of this test class is run.
    *
    * @since Method available since Release 3.4.0
    */
    public static function setUpBeforeClass ()
    {
        $oShell = new Shell_Adapter();
        $oShell->remove(TWGIT_REPOSITORY_ORIGIN_DIR);
        $oShell->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $oShell->remove(TWGIT_REPOSITORY_LOCAL_DIR);
        $oShell->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');
        $oShell->exec('touch $HOME/.gitconfig && mv $HOME/.gitconfig $HOME/.gitconfig.BAK');
    }

    /**
     * This method is called after the last test of this test class is run.
     *
     * @since Method available since Release 3.4.0
     */
    public static function tearDownAfterClass ()
    {
        $oShell = new Shell_Adapter();
        $oShell->exec('mv $HOME/.gitconfig.BAK $HOME/.gitconfig');
    }

    /**
     * Sets up the fixture, for example, open a network connection.
     * This method is called before a test is executed.
     */
    public function setUp ()
    {
        $this->_oShell = new Shell_Adapter();
    }

    /**
     * Tears down the fixture, for example, close a network connection.
     * This method is called after a test is executed.
     */
    public function tearDown ()
    {
        $this->_oShell = NULL;
    }

    /**
     * @shcovers inc/common.inc.sh::assert_git_configured
     */
    public function testAssertGitConfigured_ThrowExcpetionWhenUnknownUsername ()
    {
        $this->setExpectedException('RuntimeException', 'Unknown user.name!');
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' tag list');
    }

    /**
     * @depends testAssertGitConfigured_ThrowExcpetionWhenUnknownUsername
     * @shcovers inc/common.inc.sh::assert_git_configured
     */
    public function testAssertGitConfigured_ThrowExcpetionWhenUnknownUserEmail ()
    {
        $this->_oShell->exec("git config --global user.name 'Firstname Lastname'");
        $this->setExpectedException('RuntimeException', 'Unknown user.email!');
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' tag list');
    }

    /**
     * @depends testAssertGitConfigured_ThrowExcpetionWhenUnknownUserEmail
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_ThrowExcpetionWhenNotGitRepository ()
    {
        $this->_oShell->exec("git config --global user.email 'firstname.lastname@xyz.com'");
        $this->setExpectedException('RuntimeException', '[Git error msg] fatal: Not a git repository');
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' tag list');
    }


    /**
     * @depends testAssertGitRepository_ThrowExcpetionWhenNotGitRepository
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_ThrowExcpetionWhenNoRemoteRepository ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git init');
        $this->setExpectedException('RuntimeException', "No remote 'origin' repository specified!");
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' tag list');
    }

    /**
     * @depends testAssertGitRepository_ThrowExcpetionWhenNoRemoteRepository
     * @shcovers inc/common.inc.sh::process_fetch
     */
    public function testProcessFetch_ThrowExcpetionWhenBadRemoteRepository ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git remote add origin ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('RuntimeException', "Could not fetch 'origin'!");
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' tag list');
    }

    /**
     * @depends testProcessFetch_ThrowExcpetionWhenBadRemoteRepository
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_ThrowExcpetionWhenStableBranchNotFound ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git init');
        $this->setExpectedException('RuntimeException', 'Remote stable branch not found');
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' tag list');
    }

    /**
     * @depends testAssertGitRepository_ThrowExcpetionWhenStableBranchNotFound
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_ThrowExcpetionWhenNoTagFound ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . " && \\
touch .gitignore && \\
git add . && \\
git commit -m 'initial commit' && \\
git branch -m stable && \\
git push --set-upstream origin stable");
        $this->setExpectedException('RuntimeException', 'No tag found');
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' tag list');
    }

    /**
     * @depends testAssertGitRepository_ThrowExcpetionWhenNoTagFound
     * @shcovers inc/common.inc.sh::assert_git_repository
     */
    public function testAssertGitRepository_OK ()
    {
        $sCmd = 'cd ' . TWGIT_REPOSITORY_LOCAL_DIR . " && \\
git tag -a v1.0.0 -m 'first tag' && \\
git push --tags origin stable";
        $this->_oShell->exec($sCmd);
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' tag list');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains('Tag: v1.0.0', $sMsg);
    }
}
