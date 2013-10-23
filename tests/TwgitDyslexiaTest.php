<?php

/**
 * @package Tests
 * @author Sebastien Hanicotte <shanicotte@hi-media.com>
 */
class TwgitDyslexiaTest extends TwgitTestCase
{

    /**
    * @shcovers inc/dyslexia.inc.org::guess_dyslexia
    * @dataProvider providerTestListAboutDyslexiaActionsAndCommands
    */
    public function testList_AboutDyslexiaActionsAndCommands ($sScrambledCmd, $sExpectedContent, $sNotExpectedContent)
    {
        $sMsg = $this->_localFunctionCall('guess_dyslexia ' . $sScrambledCmd);
        if (strlen($sExpectedContent) > 0) {
            $this->assertContains($sExpectedContent, $sMsg);
        }
//        $this->assertEquals($RETVAL, $sRetval);
        if (strlen($sNotExpectedContent) > 0) {
            $this->assertNotContains($sNotExpectedContent, $sMsg);
        }
    }

    public function providerTestListAboutDyslexiaActionsAndCommands ()
    {
        return array(
            array('lance', "Assume 'lance' was 'clean'…", ''),
            /** Yep... But Lance <<Armstrong>> wasn't so clean **/
            array('mode', "Assume 'mode' was 'demo'…", ''),
            array('itni', "Assume 'itni' was 'init'…", ''),
            array('clean', '', 'Assume'),
            array('foxhit', "Assume 'foxhit' was 'hotfix'…", ''),
            array('relasee', "Assume 'relasee' was 'release'…", ''),
            array('faeture', "Assume 'faeture' was 'feature'…", ''),
            array('gta', "Assume 'gta' was 'tag'…", ''),
            array('upadte', "Assume 'upadte' was 'update'…", ''),
            array('pehl', "Assume 'pehl' was 'help'…", ''),
            array('trats', "Assume 'trats' was 'start'…", ''),
            array('hsinif', "Assume 'hsinif' was 'finish'…", ''),
            array('sautts', "Assume 'sautts' was 'status'…", ''),
            array('comimtetrs', "Assume 'comimtetrs' was 'committers'…", ''),
            array('commiters', '', 'Assume'),
            array('merg-einto-rleease', "Assume 'merg-einto-rleease' was 'merge-into-release'…", ''),
            array('migarte', "Assume 'migarte' was 'migrate'…", ''),
            array('hups', "Assume 'hups' was 'push'…", ''),
            array('movere', "Assume 'movere' was 'remove'…", ''),
            array('wath-changed', "Assume 'wath-changed' was 'what-changed'…", ''),
            array('stil', "Assume 'stil' was 'list'…", ''),
            array('merge-faeture', "Assume 'merge-faeture' was 'merge-feature'…", ''),
            array('seter', "Assume 'seter' was 'reset'…", ''),
        );
    } 
}

