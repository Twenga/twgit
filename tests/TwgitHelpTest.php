<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitHelpTest extends TwgitTestCase
{

    /**
    * This method is called before the first test of this test class is run.
    *
    * @since Method available since Release 3.4.0
    */
    public static function setUpBeforeClass ()
    {
        $o = self::_getShellInstance();
        $o->remove(TWGIT_REPOSITORY_ORIGIN_DIR);
        $o->remove(TWGIT_REPOSITORY_LOCAL_DIR);
        $o->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');

        self::_rawExec(
            "touch \$HOME/.gitconfig && mv \$HOME/.gitconfig \$HOME/.gitconfig.BAK && \\
            git config --global user.name 'Firstname Lastname' && \\
            git config --global user.email 'firstname.lastname@xyz.com'"
        );
    }

    /**
     * This method is called after the last test of this test class is run.
     *
     * @since Method available since Release 3.4.0
     */
    public static function tearDownAfterClass ()
    {
        self::_rawExec('mv $HOME/.gitconfig.BAK $HOME/.gitconfig');
    }

    /**
     * @shcovers twgit::usage
     */
    public function testMainHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Command not found: 'unknownaction'");
        $this->_exec(TWGIT_EXEC . ' unknownaction');
    }

    /**
     * @shcovers twgit::usage
     */
    public function testMainHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit <command> [<action>]");
        $this->_exec(TWGIT_EXEC . ' unknownaction');
    }

    /**
     * @shcovers twgit::usage
     * @shcovers twgit::cmd_help
     */
    public function testMainHelp_OnHelpAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC . ' help');
        $this->assertContains("Usage:\n    twgit <command> [<action>]", $sMsg);
    }

    /**
     * @shcovers twgit::usage
     * @shcovers twgit::cmd_help
     */
    public function testMainHelp_WithNoAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC);
        $this->assertContains("Usage:\n    twgit <command> [<action>]", $sMsg);
    }

    /**
     * @shcovers inc/twgit_feature.inc.sh::usage
     */
    public function testFeatureHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Unknown action: 'unknownaction'");
        $this->_exec(TWGIT_EXEC . ' feature unknownaction');
    }

    /**
     * @shcovers inc/twgit_feature.inc.sh::usage
     */
    public function testFeatureHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit feature <action>");
        $this->_exec(TWGIT_EXEC . ' feature unknownaction');
    }

    /**
     * @shcovers inc/twgit_feature.inc.sh::usage
     * @shcovers inc/twgit_feature.inc.sh::cmd_help
     */
    public function testFeatureHelp_OnHelpAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC . ' feature help');
        $this->assertContains("Usage:\n    twgit feature <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_feature.inc.sh::usage
     * @shcovers inc/twgit_feature.inc.sh::cmd_help
     */
    public function testFeatureHelp_WithNoAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC . ' feature');
        $this->assertContains("Usage:\n    twgit feature <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::usage
     */
    public function testReleaseHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Unknown action: 'unknownaction'");
        $this->_exec(TWGIT_EXEC . ' release unknownaction');
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::usage
     */
    public function testReleaseHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit release <action>");
        $this->_exec(TWGIT_EXEC . ' release unknownaction');
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::usage
     * @shcovers inc/twgit_release.inc.sh::cmd_help
     */
    public function testReleaseHelp_OnHelpAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC . ' release help');
        $this->assertContains("Usage:\n    twgit release <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_release.inc.sh::usage
     * @shcovers inc/twgit_release.inc.sh::cmd_help
     */
    public function testReleaseHelp_WithNoAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC . ' release');
        $this->assertContains("Usage:\n    twgit release <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_hotfix.inc.sh::usage
     */
    public function testHotfixHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Unknown action: 'unknownaction'");
        $this->_exec(TWGIT_EXEC . ' hotfix unknownaction');
    }

    /**
     * @shcovers inc/twgit_hotfix.inc.sh::usage
     */
    public function testHotfixHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit hotfix <action>");
        $this->_exec(TWGIT_EXEC . ' hotfix unknownaction');
    }

    /**
     * @shcovers inc/twgit_hotfix.inc.sh::usage
     * @shcovers inc/twgit_hotfix.inc.sh::cmd_help
     */
    public function testHotfixHelp_OnHelpAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC . ' hotfix help');
        $this->assertContains("Usage:\n    twgit hotfix <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_hotfix.inc.sh::usage
     * @shcovers inc/twgit_hotfix.inc.sh::cmd_help
     */
    public function testHotfixHelp_WithNoAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC . ' hotfix');
        $this->assertContains("Usage:\n    twgit hotfix <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::usage
     */
    public function testTagHelp_ThrowExcpetionWhenUnknownAction1 ()
    {
        $this->setExpectedException('RuntimeException', "Unknown action: 'unknownaction'");
        $this->_exec(TWGIT_EXEC . ' tag unknownaction');
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::usage
     */
    public function testTagHelp_ThrowExcpetionWhenUnknownAction2 ()
    {
        $this->setExpectedException('RuntimeException', "Usage:\x1B[0;37m\n    \x1B[0;37m\x1B[1;37mtwgit tag <action>");
        $this->_exec(TWGIT_EXEC . ' tag unknownaction');
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::usage
     * @shcovers inc/twgit_tag.inc.sh::cmd_help
     */
    public function testTagHelp_OnHelpAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC . ' tag help');
        $this->assertContains("Usage:\n    twgit tag <action>", $sMsg);
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::usage
     * @shcovers inc/twgit_tag.inc.sh::cmd_help
     */
    public function testTagHelp_WithNoAction ()
    {
        $sMsg = $this->_exec('cd ' . TWGIT_TMP_DIR . '; ' . TWGIT_EXEC . ' tag');
        $this->assertContains("Usage:\n    twgit tag <action>", $sMsg);
    }
}
