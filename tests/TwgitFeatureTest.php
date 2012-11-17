<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitFeatureTest extends TwgitTestCase
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
        $o->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');
    }

    /**
     */
    public function testStart_WithAmbiguousRef ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $this->assertNotContains("warning: refname 'v1.2.3' is ambiguous.", $sMsg);
        $this->assertNotContains("fatal: Ambiguous object name: 'v1.2.3'.", $sMsg);
    }

    /**
     */
    public function testList_WithAmbiguousRef ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');
        $this->_localExec(TWGIT_EXEC . ' feature start 42');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature list');
        $this->assertNotContains("warning: refname 'v1.2.3' is ambiguous.", $sMsg);
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
        $sMsg = $this->_localExec('git show HEAD~1 --format="%s"');
        $this->assertEquals("[twgit] Init branch 'stable'.", $sMsg);
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
        $sMsg = $this->_localExec('git show HEAD~1 --format="%s"');
        $this->assertEquals("[twgit] Init branch 'stable'.", $sMsg);
    }

}
