<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitMainTest extends TwgitTestCase
{

    /**
     * This method is called before the first test of this test class is run.
     *
     * @since Method available since Release 3.4.0
     */
    public static function setUpBeforeClass ()
    {
        self::_rawExec(
            "touch \$HOME/.gitconfig && mv \$HOME/.gitconfig \$HOME/.gitconfig.BAK && \\
            git config --global user.name 'Firstname Lastname' && \\
            git config --global user.email 'firstname.lastname@xyz.com'"
        );
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
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_ThrowExceptionWhenTagParameterMissing ()
    {
        $this->setExpectedException('RuntimeException', 'Missing argument <tag>!');
        $this->_localExec(TWGIT_EXEC . ' init');
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_ThrowExceptionWhenURLNeeded ()
    {
        $this->setExpectedException('RuntimeException', "Remote 'origin' repository url required!");
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3');
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_ThrowExceptionWhenBadRemoteRepository ()
    {
        $this->setExpectedException('RuntimeException', "Could not fetch 'origin'!");
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 /tmp/origin');
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_Empty ()
    {
        $this->_remoteExec('git init');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 /tmp/origin');

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
    public function testInit_WithGitInit ()
    {
        $this->_remoteExec('git init');
        $this->_localExec('git init');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 /tmp/origin');

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
    public function testInit_WithGitInitAndAddRemote ()
    {
        $this->_remoteExec('git init');
        $this->_localExec('git init && git remote add origin /tmp/origin');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3');

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
    public function testInit_WithLocalMaster ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit'"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 /tmp/origin');

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
    public function testInit_WithRemoteMaster ()
    {
        $this->_remoteExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit'"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 /tmp/origin');

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
    public function testInit_WithLocalStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit' && \\
            git branch -m stable"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 /tmp/origin');

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
    public function testInit_WithLocalAndRemoteStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit' && \\
            git branch -m stable && \\
            git remote add origin /tmp/origin && \\
            git push --set-upstream origin stable"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 /tmp/origin');

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
    public function testInit_WithRemoteStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit' && \\
            git branch -m stable && \\
            git remote add origin /tmp/origin && \\
            git push --set-upstream origin stable && \\
            git checkout -b foo && \\
            git branch -D stable"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 /tmp/origin');

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
