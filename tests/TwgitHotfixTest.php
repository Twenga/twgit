<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 * @author Geoffroy Letournel <gletournel@hi-media.com>
 * @author Sebastien Hanicotte <shanicotte@hi-media.com>
 */
class TwgitHotfixTest extends TwgitTestCase
{

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
     */
    public function testStart_WithFullColoredGit ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->_localExec(TWGIT_EXEC . ' hotfix start -I');
        $this->_localExec(
            "git config color.branch always\n"
            . "git config color.diff always\n"
            . "git config color.interactive always\n"
            . "git config color.status always\n"
            . "git config color.ui always\n"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' hotfix start');
        $sExpected = "(i) Local branch 'hotfix-1.2.4' up-to-date with remote '" . self::_remote('hotfix-1.2.4') . "'.";
        $this->assertContains($sExpected, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testFinish_ThrowExceptionWhenExtraCommitIntoStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' hotfix start -I');

        $this->_localExec('git checkout ' . self::STABLE);
        $this->_localExec('git commit --allow-empty -m "extra commit!"');

        $this->setExpectedException(
            'RuntimeException',
            "Local '" . self::STABLE . "' branch is ahead of '" . self::$_remoteStable . "'! Commits on '" . self::STABLE . "' are out of process."
                . " Try: git checkout " . self::STABLE . " && git reset " . self::$_remoteStable
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

        $this->_localExec('git checkout ' . self::STABLE);
        $this->_localExec('git commit --allow-empty -m "extra commit!"');
        $this->_localExec('git checkout ' . self::STABLE . ' && git reset ' . self::$_remoteStable);

        $this->_localExec(TWGIT_EXEC . ' hotfix finish -I');
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
        $this->_localExec(TWGIT_EXEC . ' hotfix finish -I');
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

        $this->_localExec('git checkout ' . self::STABLE);
        $this->_localExec('git commit --allow-empty -m "extra commit!"');

        $this->setExpectedException(
            'RuntimeException',
            "Local '" . self::STABLE . "' branch is ahead of '" . self::$_remoteStable . "'! Commits on '" . self::STABLE . "' are out of process."
                . " Try: git checkout " . self::STABLE . " && git reset " . self::$_remoteStable
        );
        $sMsg = $this->_localExec(TWGIT_EXEC . ' hotfix remove 1.2.4');
    }

    public function testRemove_ThrowExceptionWhenExtraCommitIntoStableWithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' hotfix start -I');

        $this->_localExec('git checkout ' . self::STABLE);
        $this->_localExec('git commit --allow-empty -m "extra commit!"');

        $this->setExpectedException(
            'RuntimeException',
            "Local '" . self::STABLE . "' branch is ahead of '" . self::$_remoteStable . "'!"
                . " Commits on '" . self::STABLE . "' are out of process."
                . " Try: git checkout " . self::STABLE . " && git reset " . self::$_remoteStable
        );
        $sMsg = $this->_localExec(TWGIT_EXEC . ' hotfix remove hotfix-1.2.4');
        $this->assertContains("Assume hotfix was '1.2.4' instead of 'hotfix-1.2.4'", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testRemove_WithExtraCommitIntoStableThenReset ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' hotfix start -I');

        $this->_localExec('git checkout ' . self::STABLE);
        $this->_localExec('git commit --allow-empty -m "extra commit!"');
        $this->_localExec('git checkout ' . self::STABLE . ' && git reset ' . self::$_remoteStable);

        $this->_localExec(TWGIT_EXEC . ' hotfix remove 1.2.4');
        $sMsg = $this->_localExec('git tag');
        $this->assertContains('v1.2.4', $sMsg);
    }

    /**
     * @dataProvider providerTestListAboutBranchesOutOfProcess
     */
    public function testList_AboutBranchesOutOfProcess ($sLocalCmd, $sExpectedContent, $sNotExpectedContent)
    {
        $this->_remoteExec('git init && git commit --allow-empty -m "-" && git checkout -b feature-currentOfNonBareRepo');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('cd ' . TWGIT_REPOSITORY_SECOND_REMOTE_DIR . ' && git init');
        $this->_localExec('git remote add second ' . TWGIT_REPOSITORY_SECOND_REMOTE_DIR);

        $this->_localExec($sLocalCmd);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' hotfix list');
        if ( ! empty($sExpectedContent)) {
            $this->assertContains($sExpectedContent, $sMsg);
        }
        if ( ! empty($sNotExpectedContent)) {
            $this->assertNotContains($sNotExpectedContent, $sMsg);
        }
    }

    public function providerTestListAboutBranchesOutOfProcess ()
    {
        return array(
            array(':', '', 'Following branches are out of process'),
            array(':', '', 'Following local branches are ambiguous'),
            array(
                'git checkout -b feature-X && git push ' . self::ORIGIN . ' feature-X'
                    . ' && git checkout -b release-X && git push ' . self::ORIGIN . ' release-X'
                    . ' && git checkout -b hotfix-X && git push ' . self::ORIGIN . ' hotfix-X'
                    . ' && git checkout -b demo-X && git push ' . self::ORIGIN . ' demo-X'
                    . ' && git checkout -b master && git push ' . self::ORIGIN . ' master'
                    . ' && git checkout -b outofprocess && git push ' . self::ORIGIN . ' outofprocess'
                    . ' && git remote set-head ' . self::ORIGIN . ' ' . self::STABLE,
                "/!\ Following branches are out of process: '" . self::_remote('outofprocess') . "'!",
                'Following local branches are ambiguous'
            ),
            array(
                'git checkout -b outofprocess && git push ' . self::ORIGIN . ' outofprocess && git push second outofprocess'
                    . ' && git checkout -b out2 && git push ' . self::ORIGIN . ' out2 && git push second out2',
                "/!\ Following branches are out of process: '" . self::_remote('out2') . "', '" . self::_remote('outofprocess') . "'!",
                'Following local branches are ambiguous'
            ),
            array(
                'git branch v1.2.3 v1.2.3',
                "/!\ Following local branches are ambiguous: 'v1.2.3'!",
                'Following branches are out of process'
            ),
            array(
                'git checkout -b outofprocess && git push ' . self::ORIGIN . ' outofprocess && git branch v1.2.3 v1.2.3',
                "/!\ Following branches are out of process: '" . self::_remote('outofprocess') . "'!\n"
                    . "/!\ Following local branches are ambiguous: 'v1.2.3'!",
                ''
            ),
        );
    }
}
