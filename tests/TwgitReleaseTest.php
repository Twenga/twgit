<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitReleaseTest extends TwgitTestCase
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
     * @shcovers inc/twgit_release.inc.sh::cmd_reset
     */
    public function testReset_ThrowExceptionWhenReleaseParameterMissing ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->setExpectedException('RuntimeException', 'Missing argument <release>!');
        $this->_localExec(TWGIT_EXEC . ' release reset');
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::cmd_reset
     */
    public function testReset_ThrowExceptionWhenReleaseNotFound ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->setExpectedException('RuntimeException', "Remote branch 'origin/release-9.9.9' not found!");
        $this->_localExec(TWGIT_EXEC . ' release reset 9.9.9');
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::cmd_reset
     */
    public function testReset_WithMinorRelease ()
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
    public function testReset_WithMajorRelease ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec(TWGIT_EXEC . ' release reset 1.3.0 -IM');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' release list');
        $this->assertContains("Release: origin/release-2.0.0", $sMsg);
    }

    /**
     */
    public function testStart_WithAmbiguousRef ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->assertNotContains("warning: refname 'v1.2.3' is ambiguous.", $sMsg);
        $this->assertNotContains("fatal: Ambiguous object name: 'v1.2.3'.", $sMsg);
    }

    /**
     * Currently just check the tag annotation.
     */
    public function testFinish_WithMinorRelease ()
    {
        $this->_localShellCodeCall('echo \'2;The subject\' > \$TWGIT_FEATURES_SUBJECT_PATH');

        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $this->_localExec(TWGIT_EXEC . ' feature start 2');
        $this->_localExec('git merge --no-ff feature-1; git commit --allow-empty -m "empty"; git push origin;');
        $this->_localExec(TWGIT_EXEC . ' feature start 3');
        $this->_localExec(TWGIT_EXEC . ' feature start 4');

        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 2');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 4');
        $this->_localExec(TWGIT_EXEC . ' release finish');

        $sMsg = $this->_localExec('git show v1.3.0');
        $this->assertContains(
            "\n[twgit] Release finish: release-1.3.0"
            . "\n[twgit] Contains feature-1"
            . "\n[twgit] Contains feature-2: \"The subject\""
            . "\n[twgit] Contains feature-4\n\n"
            , $sMsg);
        $this->assertContains("Merge branch 'release-1.3.0' into stable", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testFinish_ThrowExceptionWhenExtraCommitIntoStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');

        $this->setExpectedException(
            'RuntimeException',
            "Local 'stable' branch is ahead of 'origin/stable'! Commits on 'stable' are out of process."
                . " Try: git checkout stable && git reset origin/stable"
        );
        $sMsg = $this->_localExec(TWGIT_EXEC . ' release finish');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testFinish_WithExtraCommitIntoStableThenReset ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');
        $this->_localExec('git checkout stable && git reset origin/stable');

        $this->_localExec(TWGIT_EXEC . ' release finish');
        $sMsg = $this->_localExec('git tag');
        $this->assertContains('v1.3.0', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testRemove_ThrowExceptionWhenExtraCommitIntoStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');

        $this->setExpectedException(
            'RuntimeException',
            "Local 'stable' branch is ahead of 'origin/stable'! Commits on 'stable' are out of process."
                . " Try: git checkout stable && git reset origin/stable"
        );
        $sMsg = $this->_localExec(TWGIT_EXEC . ' release remove 1.3.0');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testRemove_WithExtraCommitIntoStableThenReset ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');
        $this->_localExec('git checkout stable && git reset origin/stable');

        $this->_localExec(TWGIT_EXEC . ' release remove 1.3.0');
        $sMsg = $this->_localExec('git tag');
        $this->assertContains('v1.3.0', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testReset_ThrowExceptionWhenExtraCommitIntoStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');

        $this->setExpectedException(
            'RuntimeException',
            "Local 'stable' branch is ahead of 'origin/stable'! Commits on 'stable' are out of process."
                . " Try: git checkout stable && git reset origin/stable"
        );
        $sMsg = $this->_localExec(TWGIT_EXEC . ' release reset 1.3.0 -I');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_stable_branch_and_checkout
     */
    public function testReset_WithExtraCommitIntoStableThenReset ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec('git checkout stable');
        $this->_localExec('git commit --allow-empty -m "extra commit!"');
        $this->_localExec('git checkout stable && git reset origin/stable');

        $this->_localExec(TWGIT_EXEC . ' release reset 1.3.0 -I');
        $sMsg = $this->_localExec('git tag');
        $this->assertContains('v1.3.0', $sMsg);
    }
}
