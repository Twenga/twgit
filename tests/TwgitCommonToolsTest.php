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
}
