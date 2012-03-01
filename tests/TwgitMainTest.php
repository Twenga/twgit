<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitMainTest extends PHPUnit_Framework_TestCase
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
        $oShell->exec("touch \$HOME/.gitconfig && mv \$HOME/.gitconfig \$HOME/.gitconfig.BAK && \\
git config --global user.name 'Firstname Lastname' && \\
git config --global user.email 'firstname.lastname@xyz.com'");
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
        $this->_oShell->remove(TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_oShell->remove(TWGIT_REPOSITORY_LOCAL_DIR);
        $this->_oShell->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $this->_oShell->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');
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
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_ThrowExceptionWhenTagParameterMissing ()
    {
        $this->setExpectedException('RuntimeException', 'Missing argument <tag>!');
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init');
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function xtestInit_ThrowExceptionWhenURLNeeded ()
    {
        $this->setExpectedException('RuntimeException', "Remote 'origin' repository url required!");
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3');
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function xtestInit_ThrowExceptionWhenBadRemoteRepository ()
    {
        $this->setExpectedException('RuntimeException', "Could not fetch 'origin'!");
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3 /tmp/origin');
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function xtestInit_Empty ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git init');
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3 /tmp/origin');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));

        $this->assertContains("Initialized empty Git repository in /tmp/local/.git/", $sMsg);
        $this->assertNotContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin /tmp/origin", $sMsg);

        $this->assertContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function xtestInit_WithGitInit ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git init');
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3 /tmp/origin');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));

        $this->assertNotContains("Initialized empty Git repository in /tmp/local/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin /tmp/origin", $sMsg);

        $this->assertContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function xtestInit_WithGitInitAndAddRemote ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git remote add origin /tmp/origin');
        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));

        $this->assertNotContains("Initialized empty Git repository in /tmp/local/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertNotContains("git remote add origin /tmp/origin", $sMsg);

        $this->assertContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function xtestInit_WithLocalMaster ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && touch .gitignore');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git add .');
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git commit -m 'initial commit'");

        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3 /tmp/origin');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));

        $this->assertNotContains("Initialized empty Git repository in /tmp/local/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin /tmp/origin", $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function xtestInit_WithRemoteMaster ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && touch .gitignore');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git add .');
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_ORIGIN_DIR . " && git commit -m 'initial commit'");

        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3 /tmp/origin');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));

        $this->assertContains("Initialized empty Git repository in /tmp/local/.git/", $sMsg);
        $this->assertNotContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin /tmp/origin", $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
    * @shcovers inc/common.inc.sh::init
    */
    public function xtestInit_WithLocalStable ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && touch .gitignore');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git add .');
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git commit -m 'initial commit'");
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git branch -m stable");

        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3 /tmp/origin');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));

                $this->assertNotContains("Initialized empty Git repository in /tmp/local/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin /tmp/origin", $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertContains("git push --set-upstream origin stable", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
    * @shcovers inc/common.inc.sh::init
    */
    public function xtestInit_WithLocalAndRemoteStable ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && touch .gitignore');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git add .');
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git commit -m 'initial commit'");
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git branch -m stable");
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git remote add origin /tmp/origin');
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git push --set-upstream origin stable");

        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3 /tmp/origin');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));

                $this->assertNotContains("Initialized empty Git repository in /tmp/local/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertNotContains("git remote add origin /tmp/origin", $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git push --set-upstream origin stable", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
    * @shcovers inc/common.inc.sh::init
    */
    public function xtestInit_WithRemoteStable ()
    {
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git init');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && touch .gitignore');
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git add .');
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git commit -m 'initial commit'");
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git branch -m stable");
        $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && git remote add origin /tmp/origin');
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git push --set-upstream origin stable");
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git checkout -b foo");
        $this->_oShell->exec("cd " . TWGIT_REPOSITORY_LOCAL_DIR . " && git branch -D stable");

        $aResult = $this->_oShell->exec('cd ' . TWGIT_REPOSITORY_LOCAL_DIR . ' && ' . TWGIT_EXEC . ' init 1.2.3 /tmp/origin');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));

        $this->assertNotContains("Initialized empty Git repository in /tmp/local/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertNotContains("git remote add origin /tmp/origin", $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git push --set-upstream origin stable", $sMsg);
        $this->assertContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }
}
