<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitReleaseTest extends TwgitTestCase
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
     * @shcovers inc/twgit_release.inc.sh::cmd_reset
     */
    public function testInit_ThrowExceptionWhenReleaseParameterMissing ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->setExpectedException('RuntimeException', 'Missing argument <release>!');
        $this->_localExec(TWGIT_EXEC . ' release reset');
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::cmd_reset
     */
    public function testInit_ThrowExceptionWhenReleaseNotFound ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->setExpectedException('RuntimeException', "Remote branch 'origin/release-9.9.9' not found!");
        $this->_localExec(TWGIT_EXEC . ' release reset 9.9.9');
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::cmd_reset
     */
    public function testInit_WithMinorRelease ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec(TWGIT_EXEC . ' release reset 1.3.0 -I');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' release list');
        $this->assertContains("Release: origin/release-1.4.0", $sMsg);
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::cmd_reset
     */
    public function testInit_WithMajorRelease ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec(TWGIT_EXEC . ' release reset 1.3.0 -IM');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' release list');
        $this->assertContains("Release: origin/release-2.0.0", $sMsg);
    }
}
