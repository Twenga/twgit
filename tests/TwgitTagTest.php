<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitTagTest extends TwgitTestCase
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
    public function testList_WithAmbiguousRef ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' tag list');
        $this->assertNotContains("warning: refname 'v1.2.3' is ambiguous.", $sMsg);
    }

}
