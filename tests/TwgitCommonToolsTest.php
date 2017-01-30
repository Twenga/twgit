<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 */
class TwgitCommonToolsTest extends TwgitTestCase
{

    /**
     * @dataProvider providerTestDisplayQuotedEnum
     * @shcovers inc/common.inc.sh::displayQuotedEnum
     */
    public function testDisplayQuotedEnum ($sValues, $sExpectedResult)
    {
        $sMsg = $this->_localFunctionCall('displayQuotedEnum "' . $sValues . '"');
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerTestDisplayQuotedEnum ()
    {
        return array(
            array('', ''),
            array('a', "'<b>a</b>'"),
            array('a b', "'<b>a</b>', '<b>b</b>'"),
            array('  a     b     ', "'<b>a</b>', '<b>b</b>'"),
            array("a\nb", "'<b>a</b>', '<b>b</b>'"),
            array("a  \n  b", "'<b>a</b>', '<b>b</b>'"),
            array('a"   "b', "'<b>a</b>', '<b>b</b>'"),
            array('a b c', "'<b>a</b>', '<b>b</b>', '<b>c</b>'"),
        );
    }

    /**
     * @dataProvider providerTestDisplayInterval
     * @shcovers inc/common.inc.sh::displayInterval
     */
    public function testDisplayInterval ($sValues, $sExpectedResult)
    {
        $sMsg = $this->_localFunctionCall('displayInterval "' . $sValues . '"');
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerTestDisplayInterval ()
    {
        return array(
            array('', ''),
            array('a', "'<b>a</b>'"),
            array('a b', "'<b>a</b>' to '<b>b</b>'"),
            array('  a     b     ', "'<b>a</b>' to '<b>b</b>'"),
            array("a\nb", "'<b>a</b>' to '<b>b</b>'"),
            array("a  \n  b", "'<b>a</b>' to '<b>b</b>'"),
            array('a"   "b', "'<b>a</b>' to '<b>b</b>'"),
            array('a b c', "'<b>a</b>' to '<b>c</b>'"),
        );
    }

    /**
     * @dataProvider providerConvertList2CSV
     * @shcovers inc/common.inc.sh::convertList2CSV
     */
    public function testConvertList2CSV ($sValues, $sExpectedResult)
    {
        $sMsg = $this->_localFunctionCall('convertList2CSV ' . $sValues);
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerConvertList2CSV ()
    {
        return array(
            array('', ''),
            array('a', '"a"'),
            array('a b', '"a";"b"'),
            array('"a b"', '"a b"'),
            array('  a     b     ', '"a";"b"'),
            array('"  a     b     "', '" a b "'),
            array("'a\nb'", '"a b"'),
            array('a b c', '"a";"b";"c"'),
            array('"a\"b"', '"a""b"'),
            array('"a\'b"', '"a\\\'b"'),
        );
    }

    /**
     * @dataProvider providerCleanPrefixes
     * @shcovers inc/common.inc.sh::clean_prefixes
     */
    public function testCleanPrefixes ($sBranchName, $sBranchType, $sExpectedResult)
    {
        $sMsg = $this->_localShellCodeCall('clean_prefixes ' . $sBranchName . ' ' . $sBranchType . '; echo \$RETVAL;');
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerCleanPrefixes ()
    {
        return array(
            array('1224', 'feature', '1224'),
            array('7889', 'demo', '7889'),
            array('1.2.0', 'release', '1.2.0'),
            array('1.2.3', 'hotfix', '1.2.3'),
            array('3.1.4', 'tag', '3.1.4'),
            array('feature-1224', 'feature', "/!\\ Assume feature was '1224' instead of 'feature-1224'…\n1224"),
            array('demo-7889', 'demo', "/!\\ Assume demo was '7889' instead of 'demo-7889'…\n7889"),
            array('release-1.2.0', 'release', "/!\\ Assume release was '1.2.0' instead of 'release-1.2.0'…\n1.2.0"),
            array('hotfix-1.2.3', 'hotfix', "/!\\ Assume hotfix was '1.2.3' instead of 'hotfix-1.2.3'…\n1.2.3"),
            array('v3.1.4', 'tag', "/!\\ Assume tag was '3.1.4' instead of 'v3.1.4'…\n3.1.4"),
            array('tag-3.1.4', 'tag', 'tag-3.1.4'),
            array('unknown-148', 'unknown', 'unknown-148'),
        );
    }
}
