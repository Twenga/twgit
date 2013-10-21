<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitCommonAssertsTest extends TwgitTestCase
{

    /**
     * @dataProvider providerTestAssertValidRefName
     * @shcovers inc/common.inc.sh::assert_valid_ref_name
     */
    public function testAssertValidRefName ($sBranch, $sExpectedResult)
    {
        if ( ! empty($sExpectedResult)) {
            $this->setExpectedException('RuntimeException', $sExpectedResult);
        }
        $sMsg = $this->_localFunctionCall('assert_valid_ref_name "' . $sBranch . '"');
        if (empty($sExpectedResult)) {
            $this->assertEquals('Check valid ref name...', $sMsg);
        }
    }

    public function providerTestAssertValidRefName ()
    {
        $sErrorGitCheckRefMsg = ' is not a valid reference name! See git check-ref-format for more details.';
        $sErrorPrefixMsg = "/!\ Unauthorized reference: '%s'! Pick another name without using any prefix"
                         . " ('feature-', 'release-', 'hotfix-', 'demo-').";

        return array(
            array('', $sErrorGitCheckRefMsg),
            array('a.', $sErrorGitCheckRefMsg),
            array('a/', $sErrorGitCheckRefMsg),
            array('a.lock', $sErrorGitCheckRefMsg),
            array('a..b', $sErrorGitCheckRefMsg),
            array('a~b', $sErrorGitCheckRefMsg),
            array('a^b', $sErrorGitCheckRefMsg),
            array('a:b', $sErrorGitCheckRefMsg),
            array('a?b', $sErrorGitCheckRefMsg),
            array('a*b', $sErrorGitCheckRefMsg),
            array('a[b', $sErrorGitCheckRefMsg),
            array('a\\b', $sErrorGitCheckRefMsg),
            array('a@{b', $sErrorGitCheckRefMsg),
            array('a b', $sErrorGitCheckRefMsg),

            array('feature-a', sprintf($sErrorPrefixMsg, 'feature-a')),
            array('xfeature-a', ''),
            array('release-a', sprintf($sErrorPrefixMsg, 'release-a')),
            array('xrelease-a', ''),
            array('hotfix-a', sprintf($sErrorPrefixMsg, 'hotfix-a')),
            array('xhotfix-a', ''),
            array('demo-a', sprintf($sErrorPrefixMsg, 'demo-a')),
            array('xdemo-a', ''),
            array('0.0.1', ''),
        );
    }

    /**
     * @dataProvider providerTestAssertValidTagName
     * @shcovers inc/common.inc.sh::assert_valid_tag_name
     */
    public function testAssertValidTagName ($sBranch, $sExpectedResult)
    {
        if ( ! empty($sExpectedResult)) {
            $this->setExpectedException('RuntimeException', $sExpectedResult);
        }
        $sMsg = $this->_localFunctionCall('assert_valid_tag_name "' . $sBranch . '"');
        if (empty($sExpectedResult)) {
            $this->assertEquals("Check valid ref name...\nCheck valid tag name...", $sMsg);
        }
    }

    public function providerTestAssertValidTagName ()
    {
        $sErrorGitCheckRefMsg = ' is not a valid reference name! See git check-ref-format for more details.';
        $sErrorPrefixMsg = "/!\ Unauthorized reference: 'feature-a'! Pick another name without using any prefix"
            . " ('feature-', 'release-', 'hotfix-', 'demo-').";
        $sErrorUnauthorizedMsg = 'Unauthorized tag name:';

        return array(
            array('', $sErrorGitCheckRefMsg),
            array('a.', $sErrorGitCheckRefMsg),
            array('feature-a', $sErrorPrefixMsg),

            array('1', $sErrorUnauthorizedMsg),
            array('1.0', $sErrorUnauthorizedMsg),
            array('1.0.0.0', $sErrorUnauthorizedMsg),

            array('a.0.1', $sErrorUnauthorizedMsg),
            array('0.0.0', $sErrorUnauthorizedMsg),
            array('01.0.0', $sErrorUnauthorizedMsg),
            array('0.01.0', $sErrorUnauthorizedMsg),
            array('0.0.01', $sErrorUnauthorizedMsg),

            array('0.0.1', ''),
            array('0.1.0', ''),
            array('1.0.0', ''),
            array('10.10.10', ''),
            array('101.34.9', ''),
        );
    }

    /**
     * @dataProvider providerTestAssertNewAndValidTagName
     * @shcovers inc/common.inc.sh::assert_new_and_valid_tag_name
     */
    public function testAssertNewAndValidTagName ($sBranch, $sExpectedResult)
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        if ( ! empty($sExpectedResult)) {
            $this->setExpectedException('RuntimeException', $sExpectedResult);
        }
        $sMsg = $this->_localFunctionCall('assert_new_and_valid_tag_name "' . $sBranch . '"');
        if (empty($sExpectedResult)) {
            $sExpectedMsg = "Check valid ref name...\nCheck valid tag name...\n"
                          . "Check whether tag '$sBranch' already exists...";
            $this->assertEquals($sExpectedMsg, $sMsg);
        }
    }

    public function providerTestAssertNewAndValidTagName ()
    {
        $sErrorGitCheckRefMsg = ' is not a valid reference name! See git check-ref-format for more details.';
        $sErrorPrefixMsg = "/!\ Unauthorized reference: 'feature-a'! Pick another name without using any prefix"
            . " ('feature-', 'release-', 'hotfix-', 'demo-').";
        $sErrorUnauthorizedMsg = 'Unauthorized tag name:';
        $sErrorAlreadyExistsMsg = "/!\ Tag 'v1.2.3' already exists! Try: twgit tag list";

        return array(
            array('', $sErrorGitCheckRefMsg),
            array('a.', $sErrorGitCheckRefMsg),
            array('feature-a', $sErrorPrefixMsg),

            array('1.0', $sErrorUnauthorizedMsg),
            array('1.0.0.0', $sErrorUnauthorizedMsg),
            array('01.0.0', $sErrorUnauthorizedMsg),

            array('1.2.3', $sErrorAlreadyExistsMsg),
            array('1.2.2', ''),
            array('1.2.4', ''),
            array('101.34.9', ''),
        );
    }

    /**
     * @shcovers inc/common.inc.sh::assert_tag_exists
     */
    public function testAssertTagExists_ThrowExceptionWhenNoTag ()
    {
        $this->_localExec('git init');
        $this->setExpectedException('RuntimeException', "Get last tag...\n/!\ No tag exists!");
        $sMsg = $this->_localFunctionCall('assert_tag_exists');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_tag_exists
     */
    public function testAssertTagExists_WithOneTag ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $sMsg = $this->_localFunctionCall('assert_tag_exists');
        $this->assertEquals("Get last tag...\nLast tag: v1.2.3", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_tag_exists
     */
    public function testAssertTagExists_WithMultipleTags ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' release finish -I');

        $sMsg = $this->_localFunctionCall('assert_tag_exists');
        $this->assertEquals("Get last tag...\nLast tag: v1.3.0", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_working_tree
     */
    public function testAssertCleanWorkingTree_WhenWorkingTreeEmpty ()
    {
        $this->_localExec('rm .twgit && git init && git commit --allow-empty -m init');
        $sMsg = $this->_localFunctionCall('assert_clean_working_tree');
        $this->assertEquals("Check clean working tree...", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_working_tree
     */
    public function testAssertCleanWorkingTree_ThrowExceptionWhenNewFile ()
    {
        $this->_localExec('git init && git commit --allow-empty -m init');
        $this->_localExec('touch a_file');
        $this->setExpectedException(
            'RuntimeException',
            "/!\ Untracked files or changes to be committed in your working tree!"
        );
        $this->_localFunctionCall('assert_clean_working_tree');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_working_tree
     */
    public function testAssertCleanWorkingTree_ThrowExceptionWhenChangesToBeCommitted ()
    {
        $this->_localExec('git init && git commit --allow-empty -m init');
        $this->_localExec('touch a_file && git add .');
        $this->setExpectedException(
            'RuntimeException',
            "/!\ Untracked files or changes to be committed in your working tree!"
        );
        $this->_localFunctionCall('assert_clean_working_tree');
    }

    /**
     * @shcovers inc/common.inc.sh::assert_clean_working_tree
     */
    public function testAssertCleanWorkingTree_AfterCommit ()
    {
        $this->_localExec('git init && git commit --allow-empty -m init');
        $this->_localExec('touch a_file && git add . && git commit -am comment');
        $sMsg = $this->_localFunctionCall('assert_clean_working_tree');
        $this->assertEquals("Check clean working tree...", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_working_tree_is_not_on_delete_branch
     */
    public function testAssertWorkingTreeIsNotOnDeleteBranch_WhenOnDeleteBranch ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' feature start 1; ' . TWGIT_EXEC . ' feature start 2');
        $this->_localExec('git checkout feature-1');
        $sMsg = $this->_localFunctionCall('assert_working_tree_is_not_on_delete_branch feature-1');
        $sExpectedMsg =
            "Check current branch...\n"
            . "Cannot delete the branch 'feature-1' which you are currently on! So:\n"
            . "git# git checkout " . self::STABLE . "\n"
            . "Switched to branch '" . self::STABLE . "'";
        $this->assertContains($sExpectedMsg, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::assert_working_tree_is_not_on_delete_branch
     */
    public function testAssertWorkingTreeIsNotOnDeleteBranch_WhenOK ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' feature start 1; ' . TWGIT_EXEC . ' feature start 2');
        $this->_localExec('git checkout feature-2');
        $sMsg = $this->_localFunctionCall('assert_working_tree_is_not_on_delete_branch feature-1');
        $this->assertNotContains("Cannot delete the branch 'feature-1' which you are currently on!", $sMsg);
    }
}
