<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitFeatureTest extends TwgitTestCase
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
     */
    public function testStart_WithNoConnectorSetted ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->_localShellCodeCall('function getFeatureSubject(){ echo;}; . \$TWGIT_INC_DIR/twgit_feature.inc.sh; cmd_start 1');
        $sMsg = $this->_localExec('git show HEAD --format="%s"');
        $this->assertEquals("[twgit] Init feature 'feature-1'.", $sMsg);
    }

    /**
     */
    public function testStart_WithConnectorSetted ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->_localShellCodeCall('function getFeatureSubject(){ echo \"Bla\'\\\\\"bla\";}; . \$TWGIT_INC_DIR/twgit_feature.inc.sh; cmd_start 1');
        $sMsg = $this->_localExec('git show HEAD --format="%s"');
        $this->assertEquals("[twgit] Init feature 'feature-1': Bla'\"bla.", $sMsg);
    }

}
