<?php

/**
 * @package Tests
 * @author Sebastien Hanicotte <shanicotte@hi-media.com>
 */
class TwgitDemoTest extends TwgitTestCase
{

    public function testStart_WithPrefixNaming ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo start demo-42');
        $this->assertContains("Assume demo was '42' instead of 'demo-42'", $sMsg);
    }

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
        $this->assertContains("Assume feature was '43' instead of 'feature-43'", $sMsg);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo list demo-42');
        $this->assertContains("Assume demo was '42' instead of 'demo-42'", $sMsg);
        $this->assertContains("feature-42", $sMsg);
        $this->assertContains("feature-43", $sMsg);
    }

    public function testRemove_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' demo start 42');
        $this->_localExec('git checkout ' . self::STABLE);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo remove demo-42');
        $this->assertContains("Assume demo was '42' instead of 'demo-42'", $sMsg);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo list');
        $this->assertNotContains("demo-42", $sMsg);
    }

    public function testStatus_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' demo start 42');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' demo status demo-42');
        $this->assertContains("Assume demo was '42' instead of 'demo-42'", $sMsg);
    }

    public function testStartFromDemo_WithoutRemote ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('\RuntimeException', "Remote branch '" . self::_remote('demo-51') ."' not found!");
        $this->_localExec(TWGIT_EXEC . ' demo start 42 from-demo 51');
    }

    public function testStartFromDemo_WithExistingRemote ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_remoteExec(
            'git checkout -b demo-51'
            . ' && git commit --allow-empty -m "Initialize demo-51"'
            . ' && touch the-chosen-one'
            . ' && git add .'
            . ' && git commit -m "Add the chosen one"'
        );
        $this->_localExec(TWGIT_EXEC . ' demo start 42 from-demo 51');
        $sResult = $this->_localExec('ls');
        $this->assertContains('the-chosen-one', $sResult);
    }

    public function testStartFromRelease_WithoutRemote ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('\RuntimeException', 'No release in progress!');
        $this->_localExec(TWGIT_EXEC . ' demo start 42 from-release');
    }

    public function testStartFromRelease_WithExistingRemote ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_remoteExec(
            'git checkout -b release-1.3.0'
            . ' && git commit --allow-empty -m "Initialize release-1.3.0"'
            . ' && touch the-chosen-one'
            . ' && git add .'
            . ' && git commit -m "Add the chosen one"'
        );
        $this->_localExec(TWGIT_EXEC . ' demo start 42 from-release');
        $sResult = $this->_localExec('ls');
        $this->assertContains('the-chosen-one', $sResult);
    }
}

