<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 */
class TwgitCUITest extends TwgitTestCase
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
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_ThrowExceptionWhenUnknownTypeAndNoDefinedType ()
    {
        $this->setExpectedException('RuntimeException', "Unknown display type 'info'!\nAvailable types: .");
        $sMsg = $this->_localShellCodeCall('CUI_COLORS=(); CUI_displayMsg info', false);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_ThrowExceptionWhenUnknownTypeAndOneDefinedType ()
    {
        $this->setExpectedException('RuntimeException', "Unknown display type 'info'!\nAvailable types: a.");
        $sMsg = $this->_localShellCodeCall('CUI_COLORS=([a]=b); CUI_displayMsg info', false);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_ThrowExceptionWhenUnknownTypeAndSeveralDefinedTypes ()
    {
        $this->setExpectedException('RuntimeException', "Unknown display type 'info'!\nAvailable types: a, c.");
        $sMsg = $this->_localShellCodeCall('CUI_COLORS=([a]=b [c]=d [c.bold]=d2 [c.header]=d3); CUI_displayMsg info', false);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_ThrowExceptionWhenUnknownTypeWithMsg ()
    {
        $this->setExpectedException('RuntimeException', "Unknown display type 'info'!\nAvailable types: .");
        $sMsg = $this->_localShellCodeCall('CUI_COLORS=(); CUI_displayMsg info blabla', false);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_Simple ()
    {
        $sMsg = $this->_localShellCodeCall('CUI_COLORS=([info]=\'\033[0;36m\'); CUI_displayMsg info bla', false);
        $this->assertEquals('\033[0;36mbla\033[0m', $sMsg);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_SimpleWithMultipleMsg ()
    {
        $sMsg = $this->_localShellCodeCall('CUI_COLORS=([info]=\'\033[0;36m\'); CUI_displayMsg info bla bla bla', false);
        $this->assertEquals('\033[0;36mbla bla bla\033[0m', $sMsg);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_ThrowExceptionWhenOnlyHeader ()
    {
        $this->setExpectedException('RuntimeException', "Unknown display type 'info'!\nAvailable types: .");
        $sMsg = $this->_localShellCodeCall('CUI_COLORS=([info.header]=\'\033[0;36m\'); CUI_displayMsg info bla', false);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_WithHeader ()
    {
        $sMsg = $this->_localShellCodeCall(
            'CUI_COLORS=([info]=\'\033[0;36m\' [info.header]=\'\033[1;36m(i) \'); '
            . 'CUI_displayMsg info bla bla', false
        );
        $this->assertEquals('\033[1;36m(i) \033[0;36mbla bla\033[0m', $sMsg);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_ThrowExceptionWhenOnlyBold ()
    {
        $this->setExpectedException('RuntimeException', "Unknown display type 'info'!\nAvailable types: .");
        $sMsg = $this->_localShellCodeCall('CUI_COLORS=([info.bold]=\'\033[0;36m\'); CUI_displayMsg info bla', false);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_WithBold ()
    {
        $sMsg = $this->_localShellCodeCall(
            'CUI_COLORS=([info]=\'\033[0;36m\' [info.bold]=\'\033[1;36m\'); '
            . 'CUI_displayMsg info \"bla<b>haha</b>bla\"', false
        );
        $this->assertEquals('\033[0;36mbla\033[1;36mhaha\033[0;36mbla\033[0m', $sMsg);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_WithMultipleBoldTags ()
    {
        $sMsg = $this->_localShellCodeCall(
            'CUI_COLORS=([info]=\'\033[0;36m\' [info.bold]=\'\033[1;36m\'); '
            . 'CUI_displayMsg info \"bla<b>haha</b>-<b>Hello!</b>bla<b></b>\"', false
        );
        $this->assertEquals('\033[0;36mbla\033[1;36mhaha\033[0;36m-\033[1;36mHello!\033[0;36mbla\033[1;36m\033[0;36m\033[0m', $sMsg);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_WithBoldTagsButWithoutBold ()
    {
        $sMsg = $this->_localShellCodeCall(
            'CUI_COLORS=([info]=\'\033[0;36m\'); '
            . 'CUI_displayMsg info \"bla<b>haha</b>bla\"', false
        );
        $this->assertEquals('\033[0;36mblahahabla\033[0m', $sMsg);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_WithMultipleBoldTagsButWithoutBold ()
    {
        $sMsg = $this->_localShellCodeCall(
            'CUI_COLORS=([info]=\'\033[0;36m\'); '
            . 'CUI_displayMsg info \"bla<b>haha</b>-<b>Hello!</b>bla<b></b>\"', false
        );
        $this->assertEquals('\033[0;36mblahaha-Hello!bla\033[0m', $sMsg);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_WithBoldAndHeader ()
    {
        $sMsg = $this->_localShellCodeCall(
            'CUI_COLORS=([info]=\'\033[0;36m\' [info.bold]=\'\033[1;36m\' [info.header]=\'\033[1;36m(i) \'); '
            . 'CUI_displayMsg info \"bla<b>haha</b>bla\"', false
        );
        $this->assertEquals('\033[1;36m(i) \033[0;36mbla\033[1;36mhaha\033[0;36mbla\033[0m', $sMsg);
    }

    /**
     * @shcovers inc/coloredUI.inc.sh::CUI_isSet
     * @shcovers inc/coloredUI.inc.sh::CUI_displayMsg
     */
    public function testDisplayMsg_WithBoldAndHeaderAndBackslashes ()
    {
        $sMsg = $this->_localShellCodeCall(
            'CUI_COLORS=([info]=\'\033[0;36m\' [info.bold]=\'/&\\\' [info.header]=\'/i\\ \'); '
            . 'CUI_displayMsg info \"bla<b>haha</b>bla\"', false
        );
        $this->assertEquals('/i\ \033[0;36mbla/&\haha\033[0;36mbla\033[0m', $sMsg);
    }
}
