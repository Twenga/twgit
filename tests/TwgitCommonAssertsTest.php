<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitCommonAssertsTest extends TwgitTestCase
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
        $o->remove(TWGIT_REPOSITORY_SECOND_REMOTE_DIR);
        $o->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_SECOND_REMOTE_DIR, '0777');
    }

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
        $sErrorPrefixMsg = '/!\ Unauthorized reference! Pick another name without using any prefix'
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

            array('feature-a', $sErrorPrefixMsg),
            array('xfeature-a', ''),
            array('release-a', $sErrorPrefixMsg),
            array('xrelease-a', ''),
            array('hotfix-a', $sErrorPrefixMsg),
            array('xhotfix-a', ''),
            array('demo-a', $sErrorPrefixMsg),
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
        $sErrorPrefixMsg = '/!\ Unauthorized reference! Pick another name without using any prefix'
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
        $sErrorPrefixMsg = '/!\ Unauthorized reference! Pick another name without using any prefix'
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
}
