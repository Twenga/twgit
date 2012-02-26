<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitHelpTest extends PHPUnit_Framework_TestCase
{

    /**
     * @var Shell_Adapter
     */
    private $_oShell;

    /**
    * This method is called before the first test of this test class is run.
    *
    * @since Method available since Release 3.4.0
    */
    public static function setUpBeforeClass ()
    {
        $oShell = new Shell_Adapter();
        $oShell->remove(TWGIT_REPOSITORY_ORIGIN_DIR);
        $oShell->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $oShell->remove(TWGIT_REPOSITORY_LOCAL_DIR);
        $oShell->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');

        $oShell->exec("touch \$HOME/.gitconfig && mv \$HOME/.gitconfig \$HOME/.gitconfig.BAK && \\
git config --global user.name 'Firstname Lastname' && \\
git config --global user.email 'firstname.lastname@xyz.com'");
    }

    /**
     * This method is called after the last test of this test class is run.
     *
     * @since Method available since Release 3.4.0
     */
    public static function tearDownAfterClass ()
    {
        $oShell = new Shell_Adapter();
        $oShell->exec('mv $HOME/.gitconfig.BAK $HOME/.gitconfig');
    }

    /**
     * Sets up the fixture, for example, open a network connection.
     * This method is called before a test is executed.
     */
    public function setUp ()
    {
        $this->_oShell = new Shell_Adapter();
    }

    /**
     * Tears down the fixture, for example, close a network connection.
     * This method is called after a test is executed.
     */
    public function tearDown ()
    {
        $this->_oShell = NULL;
    }

    /**
     * @shcovers twgit::usage
     */
    public function testMainHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Command not found: 'unknownaction'");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' unknownaction');
    }

    /**
     * @shcovers twgit::usage
     */
    public function testMainHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit <command> [<action>]");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' unknownaction');
    }

    /**
     * @shcovers twgit::usage
     * @shcovers twgit::cmd_help
     */
    public function testMainHelp_OnHelpAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' help');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit <command> [<action>]", $sMsg);
    }

    /**
     * @shcovers twgit::usage
     * @shcovers twgit::cmd_help
     */
    public function testMainHelp_WithNoAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC);
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit <command> [<action>]", $sMsg);
    }

    /**
     * @shcovers inc/twgit_feature.inc.sh::usage
     */
    public function testFeatureHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Unknown action: 'unknownaction'");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' feature unknownaction');
    }

    /**
     * @shcovers inc/twgit_feature.inc.sh::usage
     */
    public function testFeatureHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit feature <action>");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' feature unknownaction');
    }

    /**
     * @shcovers inc/twgit_feature.inc.sh::usage
     * @shcovers inc/twgit_feature.inc.sh::cmd_help
     */
    public function testFeatureHelp_OnHelpAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' feature help');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit feature <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_feature.inc.sh::usage
     * @shcovers inc/twgit_feature.inc.sh::cmd_help
     */
    public function testFeatureHelp_WithNoAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' feature');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit feature <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::usage
     */
    public function testReleaseHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Unknown action: 'unknownaction'");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' release unknownaction');
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::usage
     */
    public function testReleaseHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit release <action>");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' release unknownaction');
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::usage
     * @shcovers inc/twgit_release.inc.sh::cmd_help
     */
    public function testReleaseHelp_OnHelpAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' release help');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit release <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::usage
     * @shcovers inc/twgit_release.inc.sh::cmd_help
     */
    public function testReleaseHelp_WithNoAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' release');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit release <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_hotfix.inc.sh::usage
     */
    public function testHotfixHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Unknown action: 'unknownaction'");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' hotfix unknownaction');
    }

    /**
     * @shcovers inc/twgit_hotfix.inc.sh::usage
     */
    public function testHotfixHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit hotfix <action>");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' hotfix unknownaction');
    }

    /**
     * @shcovers inc/twgit_hotfix.inc.sh::usage
     * @shcovers inc/twgit_hotfix.inc.sh::cmd_help
     */
    public function testHotfixHelp_OnHelpAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' hotfix help');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit hotfix <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_hotfix.inc.sh::usage
     * @shcovers inc/twgit_hotfix.inc.sh::cmd_help
     */
    public function testHotfixHelp_WithNoAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' hotfix');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit hotfix <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::usage
     */
    public function testTagHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Unknown action: 'unknownaction'");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' tag unknownaction');
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::usage
     */
    public function testTagHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit tag <action>");
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' tag unknownaction');
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::usage
     * @shcovers inc/twgit_tag.inc.sh::cmd_help
     */
    public function testTagHelp_OnHelpAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' tag help');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit tag <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::usage
     * @shcovers inc/twgit_tag.inc.sh::cmd_help
     */
    public function testTagHelp_WithNoAction ()
    {
        $aResult = $this->_oShell->exec(TWGIT_EXEC . ' tag');
        $sMsg = preg_replace('/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]/', '', implode("\n", $aResult));
        $this->assertContains("Usage:\n    twgit tag <action>", $sMsg);
    }
}
