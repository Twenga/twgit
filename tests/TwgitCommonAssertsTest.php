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
        $sErrorMsg = 'Unauthorized tag name:';
        return array(
            array('', $sErrorGitCheckRefMsg),
            array('a.', $sErrorGitCheckRefMsg),
            array('feature-a', $sErrorPrefixMsg),

            array('1', $sErrorMsg),
            array('1.0', $sErrorMsg),
            array('1.0.0.0', $sErrorMsg),

            array('a.0.1', $sErrorMsg),
            array('0.0.0', $sErrorMsg),
            array('01.0.0', $sErrorMsg),
            array('0.01.0', $sErrorMsg),
            array('0.0.01', $sErrorMsg),

            array('0.0.1', ''),
            array('0.1.0', ''),
            array('1.0.0', ''),
            array('10.10.10', ''),
            array('101.34.9', ''),
        );
    }
}
