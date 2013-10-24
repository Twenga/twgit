<?php

/**
 * @package Tests
 * @author Sebastien Hanicotte <shanicotte@hi-media.com>
 */
class TwgitDyslexiaTest extends TwgitTestCase
{

    /**
    * @shcovers inc/dyslexia.inc.sh::guess_dyslexia
    * @dataProvider providerTestListAboutDyslexiaActionsAndCommands
    */
    public function testList_AboutDyslexiaActionsAndCommands ($sScrambledCmd, $sExpectedContent, $sNotExpectedContent, $sRetval)
    {
        $sMsg = $this->_localFunctionCall('guess_dyslexia ' . $sScrambledCmd);
        if (strlen($sExpectedContent) > 0) {
            $this->assertContains($sExpectedContent, $sMsg);
        }
//        $this->assertEquals($RETVAL, $sRetval);
        if (strlen($sNotExpectedContent) > 0) {
            $this->assertNotContains($sNotExpectedContent, $sMsg);
        }

        $sCmd = 'guess_dyslexia ' . $sScrambledCmd . '; echo \$RETVAL;';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertContains($sRetval, $sMsg);
    }

    public function providerTestListAboutDyslexiaActionsAndCommands ()
    {
        return array(
            array('lance', "Assume 'lance' was 'clean'…", '', 'clean'),
            /** Yep... But Lance <<Armstrong>> wasn't so clean **/
            array('mode', "Assume 'mode' was 'demo'…", '', 'demo'),
            array('itni', "Assume 'itni' was 'init'…", '', 'init'),
            /** Testing one clean commande **/
            array('clean', '', 'Assume', 'clean'),
            array('foxhit', "Assume 'foxhit' was 'hotfix'…", '', 'hotfix'),
            array('relasee', "Assume 'relasee' was 'release'…", '', 'release'),
            array('faeture', "Assume 'faeture' was 'feature'…", '', 'feature'),
            array('gta', "Assume 'gta' was 'tag'…", '', 'tag'),
            array('upadte', "Assume 'upadte' was 'update'…", '', 'update'),
            array('pehl', "Assume 'pehl' was 'help'…", '', 'help'),
            array('trats', "Assume 'trats' was 'start'…", '', 'start'),
            array('hsinif', "Assume 'hsinif' was 'finish'…", '', 'finish'),
            array('sautts', "Assume 'sautts' was 'status'…", '', 'status'),
            array('comimtetrs', "Assume 'comimtetrs' was 'committers'…", '', 'committers'),
            /** Testing one unknowk hash key **/
            array('commiters', '', 'Assume', 'commiters'),
            array('merg-einto-rleease', "Assume 'merg-einto-rleease' was 'merge-into-release'…", '', 'merge-into-release'),
            array('migarte', "Assume 'migarte' was 'migrate'…", '', 'migrate'),
            array('hups', "Assume 'hups' was 'push'…", '', 'push'),
            array('movere', "Assume 'movere' was 'remove'…", '', 'remove'),
            array('wath-changed', "Assume 'wath-changed' was 'what-changed'…", '', 'what-changed'),
            array('stil', "Assume 'stil' was 'list'…", '', 'list'),
            array('merge-faeture', "Assume 'merge-faeture' was 'merge-feature'…", '', 'merge-feature'),
            array('seter', "Assume 'seter' was 'reset'…", '', 'reset'),
        );
    } 
}

