<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 */
class TwgitOptionsHandlerTest extends TwgitTestCase
{

    /**
     * @dataProvider providerTestProcessOptions
     * @shcovers inc/options_handler.inc.sh::process_options
     */
    public function testProcessOptions ($sIn, $sOutParameters, $sOutOptions)
    {
        $sCmd = 'process_options ' . $sIn . '; echo \$FCT_PARAMETERS; echo \$FCT_OPTIONS';
        $sMsg = $this->_localShellCodeCall($sCmd);
        list($sParameters, $sOptions) = explode("\n", $sMsg);
        $this->assertEquals($sOutParameters, $sParameters);
        $this->assertEquals($sOutOptions, $sOptions);
    }

    public function providerTestProcessOptions ()
    {
        return array(
            array('', '', ''),
            array('a', 'a', ''),
            array('-a', '', 'a'),
            array('x-a', 'x-a', ''),
            array('x -y Z', 'x Z', 'y'),
            array('x -yZ aa', 'x aa', 'y Z'),
            array('-x-yZ aa bbb c -rst', 'aa bbb c', 'x y Z r s t'),
            array('a -b C -d -e f', 'a C f', 'b d e'),
        );
    }

    /**
     * @dataProvider providerTestIssetOption
     * @shcovers inc/options_handler.inc.sh::isset_option
     */
    public function testIssetOption ($sInOptions, $sInOptionToTest, $sOut)
    {
        $sCmd = 'process_options ' . $sInOptions . '; isset_option ' . $sInOptionToTest . '; echo \$?';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sOut, $sMsg);
    }

    public function providerTestIssetOption ()
    {
        return array(
            array('a', 'a', '1'),
            array('a', 'b', '1'),
            array('-A', 'a', '1'),
            array('-a', 'A', '1'),
            array('-a', 'a', '0'),
            array('-A', 'A', '0'),
            array('x -aV', 'x', '1'),
            array('x -aV', 'X', '1'),
            array('x -aV', 'a', '0'),
            array('x -aV', 'V', '0'),
        );
    }

    /**
     * @dataProvider providerTestSetOptions
     * @shcovers inc/options_handler.inc.sh::set_options
     */
    public function testSetOptions ($sInOptions, $sInOptionsToAdd, $sInOptionToTest, $sOut)
    {
        $sCmd = 'process_options ' . $sInOptions . '; set_options ' . $sInOptionsToAdd
              . '; isset_option ' . $sInOptionToTest . '; echo \$?';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sOut, $sMsg);
    }

    public function providerTestSetOptions ()
    {
        return array(
            array('-a', 'a', 'a', '0'),
            array('-a', 'a', 'A', '1'),
            array('-a', 'A', 'a', '0'),
            array('-a', 'A', 'A', '0'),
            array('-a', 'a', 'b', '1'),
            array('-a', 'b', 'b', '0'),
            array('-a', 'b', 'c', '1'),
            array('-a', 'bc', 'b', '0'),
            array('-a', 'bc', 'c', '0'),
            array('-ab', 'bc', 'c', '0'),
        );
    }
}
