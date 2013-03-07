<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 */
class TwgitCommonProcessingTest extends TwgitTestCase
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
        $o->remove(TWGIT_REPOSITORY_THIRD_REMOTE_DIR);
        $o->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_SECOND_LOCAL_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_SECOND_REMOTE_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_THIRD_REMOTE_DIR, '0777');
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.0.0 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
    }

    /**
     * @shcovers inc/common.inc.sh::exec_git_command
     */
    public function testExecGitCommand_WithoutError ()
    {
        $sMsg = $this->_localFunctionCall('exec_git_command "git --version" "error msg"');
        $this->assertContains("git# git --version\ngit version ", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::exec_git_command
     */
    public function testExecGitCommand_ThrowExceptionWhenError ()
    {
        $this->setExpectedException('RuntimeException', "/!\ error msg");
        $sMsg = $this->_localFunctionCall('exec_git_command "git checkout notexists" "error msg"');
    }

    /**
     * @shcovers inc/common.inc.sh::remove_local_branch
     */
    public function testRemoveLocalBranch_WhenNotExists ()
    {
        $sMsg = $this->_localFunctionCall('remove_local_branch notexists');
        $this->assertEquals("Local branch 'notexists' not found.", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::remove_local_branch
     */
    public function testRemoveLocalBranch_WhenExistsAndNotCurrent ()
    {
        $this->_localExec(TWGIT_EXEC . ' feature start 1; ' . TWGIT_EXEC . ' feature start 2');
        $this->_localFunctionCall('remove_local_branch feature-1');
        $sMsg = $this->_localExec("git branch -a | sed 's/^[* ]*//' | sed 's/ *$//g'");
        $this->assertEquals(
            "feature-2\nstable\nremotes/origin/feature-1\nremotes/origin/feature-2\nremotes/origin/stable",
            $sMsg
        );
    }

    /**
     * @shcovers inc/common.inc.sh::remove_remote_branch
     */
    public function testRemoveRemoteBranch_ThrowExceptionWhenNotExists ()
    {
        $this->setExpectedException('RuntimeException', "/!\ Remote branch 'origin/notexists' not found!");
        $sMsg = $this->_localFunctionCall('remove_remote_branch notexists');
    }

    /**
     * @shcovers inc/common.inc.sh::remove_remote_branch
     */
    public function testRemoveRemoteBranch_WhenExistsAndNotAlreadyDeleted ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; '
        );
        $this->_localFunctionCall('remove_remote_branch feature-1');
        $sMsg = $this->_localExec("git branch -a | sed 's/^[* ]*//' | sed 's/ *$//g'");
        $this->assertEquals(
            "feature-1\nfeature-2\nstable\nremotes/origin/feature-2\nremotes/origin/stable",
            $sMsg
        );
    }

    /**
     * @shcovers inc/common.inc.sh::remove_remote_branch
     */
    public function testRemoveRemoteBranch_ThrowExceptionWhenAlreadyDeleted ()
    {
        $this->_localExec(TWGIT_EXEC . ' feature start 1; ' . TWGIT_EXEC . ' feature start 2; ');
        $this->_localExec(
            'git init && git remote add origin ' . TWGIT_REPOSITORY_ORIGIN_DIR . ' && git fetch origin'
            , true, 2
        );
        $this->_localFunctionCall('remove_remote_branch feature-1');

        $this->setExpectedException('RuntimeException', "/!\ Delete remote branch 'origin/feature-1' failed!");
        $sMsg = $this->_localFunctionCall('remove_remote_branch feature-1', true, 2);
    }

    /**
     * @shcovers inc/common.inc.sh::remove_branch
     */
    public function testRemoveBranch ()
    {
        $this->_localExec(TWGIT_EXEC . ' feature start 1; ' . TWGIT_EXEC . ' feature start 2; ');
        $sMsg = $this->_localFunctionCall('remove_branch 1 feature-');
        $this->assertContains('Check valid ref name...', $sMsg);
        $this->assertContains('Check clean working tree...', $sMsg);
        $this->assertContains('Check current branch...', $sMsg);
        $this->assertContains('git# git fetch --prune origin', $sMsg);

        $sMsg = $this->_localExec("git branch -a | sed 's/^[* ]*//' | sed 's/ *$//g'");
        $this->assertEquals(
            "feature-2\nstable\nremotes/origin/feature-2\nremotes/origin/stable",
            $sMsg
        );
    }

    /**
     * @shcovers inc/common.inc.sh::remove_demo
     */
    public function testRemoveDemo ()
    {
        $this->_localExec(TWGIT_EXEC . ' demo start 1; ' . TWGIT_EXEC . ' demo start 2; ');
        $sMsg = $this->_localFunctionCall('remove_demo 1');
        $this->assertContains('Check valid ref name...', $sMsg);
        $this->assertContains('Check clean working tree...', $sMsg);
        $this->assertContains('Check current branch...', $sMsg);
        $this->assertContains('git# git fetch --prune origin', $sMsg);

        $sMsg = $this->_localExec("git branch -a | sed 's/^[* ]*//' | sed 's/ *$//g'");
        $this->assertEquals(
            "demo-2\nstable\nremotes/origin/demo-2\nremotes/origin/stable",
            $sMsg
        );
    }

    /**
     * @shcovers inc/common.inc.sh::remove_feature
     */
    public function testRemoveFeature ()
    {
        $this->_localExec(TWGIT_EXEC . ' feature start 1; ' . TWGIT_EXEC . ' feature start 2; ');
        $sMsg = $this->_localFunctionCall('remove_feature 1');
        $this->assertContains('Check valid ref name...', $sMsg);
        $this->assertContains('Check clean working tree...', $sMsg);
        $this->assertContains('Check current branch...', $sMsg);
        $this->assertContains('git# git fetch --prune origin', $sMsg);

        $sMsg = $this->_localExec("git branch -a | sed 's/^[* ]*//' | sed 's/ *$//g'");
        $this->assertEquals(
            "feature-2\nstable\nremotes/origin/feature-2\nremotes/origin/stable",
            $sMsg
        );
    }
}
