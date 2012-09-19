<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitHotfixTest extends TwgitTestCase
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

        $sMsg = $this->_localExec(TWGIT_EXEC . ' hotfix start -I');
        $this->assertNotContains("warning: refname 'v1.2.3' is ambiguous.", $sMsg);
        $this->assertNotContains("fatal: Ambiguous object name: 'v1.2.3'.", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testFinish_ThrowExceptionWhenExtraCommitIntoStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' hotfix start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');

        $this->setExpectedException(
            'RuntimeException',
            "Local 'stable' branch is ahead of 'origin/stable'! Commits on 'stable' are out of process."
                . " Try: git checkout stable && git reset origin/stable"
        );
        $sMsg = $this->_localExec(TWGIT_EXEC . ' hotfix finish');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testFinish_WithExtraCommitIntoStableThenReset ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' hotfix start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');
        $this->_localExec('git checkout stable && git reset origin/stable');

        $this->_localExec(TWGIT_EXEC . ' hotfix finish');
        $sMsg = $this->_localExec('git tag');
        $this->assertContains('v1.2.4', $sMsg);
    }

    /**
    */
    public function testFinish_WithEmptyHotfix ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' hotfix start -I');
        $this->_localExec(TWGIT_EXEC . ' hotfix finish');
        $sMsg = $this->_localExec('git tag');
        $this->assertContains('v1.2.4', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testRemove_ThrowExceptionWhenExtraCommitIntoStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' hotfix start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');

        $this->setExpectedException(
            'RuntimeException',
            "Local 'stable' branch is ahead of 'origin/stable'! Commits on 'stable' are out of process."
                . " Try: git checkout stable && git reset origin/stable"
        );
        $sMsg = $this->_localExec(TWGIT_EXEC . ' hotfix remove 1.2.4');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testRemove_WithExtraCommitIntoStableThenReset ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' hotfix start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');
        $this->_localExec('git checkout stable && git reset origin/stable');

        $this->_localExec(TWGIT_EXEC . ' hotfix remove 1.2.4');
        $sMsg = $this->_localExec('git tag');
        $this->assertContains('v1.2.4', $sMsg);
    }
}
