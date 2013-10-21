<?php

/**
 * @package Tests
 * @author Sebastien Hanicotte <shanicotte@hi-media.com>
 */
class TwgitDemoTest extends TwgitTestCase
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
        $o->remove(TWGIT_REPOSITORY_SECOND_LOCAL_DIR);
        $o->remove(TWGIT_REPOSITORY_SECOND_REMOTE_DIR);
        $o->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_SECOND_LOCAL_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_SECOND_REMOTE_DIR, '0777');
    }

    /**
     * @shcovers inc/twgit_demo.inc.sh::cmd_start
     */
    public function testStart_WithPrefixNaming ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo start demo-42');
        $this->assertContains("assume tag was 42 instead of demo-42", $sMsg);
    }

    /**
     * @shcovers inc/twgit_demo.inc.sh::cmd_list
     */
    public function testList_WithPrefix ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');
        $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $this->_localExec(TWGIT_EXEC . ' feature start 43');
        $this->_localExec(TWGIT_EXEC . ' demo start 42');
        $this->_localExec(TWGIT_EXEC . ' demo merge-feature 42');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo merge-feature feature-43');
        $this->assertContains("assume tag was 43 instead of feature-43", $sMsg);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo list demo-42');
        $this->assertContains("assume tag was 42 instead of demo-42", $sMsg);
        $this->assertContains("feature-42", $sMsg);
        $this->assertContains("feature-43", $sMsg);
    }

    public function testRemove_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' demo start 42');
        $this->_localExec('git checkout stable');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo remove demo-42');
        $this->assertContains("assume tag was 42 instead of demo-42", $sMsg);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo list');
        $this->assertNotContains("demo-42", $sMsg);
    }

    /**
     * @shcovers inc/twgit_demo.inc.sh::cmd_status
     */
    public function testStatus_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' demo start 42');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo status demo-42');
        $this->assertContains("assume tag was 42 instead of demo-42", $sMsg);
    }
}

