<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 */
class TwgitTagTest extends TwgitTestCase
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
     * @shcovers inc/twgit_tag.inc.sh::cmd_list
     */
    public function testList_WithAmbiguousRef ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' tag list');
        $this->assertNotContains("warning: refname 'v1.2.3' is ambiguous.", $sMsg);
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::cmd_list
     */
    public function testList_WithUnknownRef ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $this->setExpectedException('RuntimeException', "/!\ Tag 'v6.6.6' does not exist! Try: twgit tag list");
        $this->_localExec(TWGIT_EXEC . ' tag list 6.6.6');
    }

    /**
     * @shcovers inc/twgit_tag.inc.sh::cmd_list
     */
    public function testList_WithBadRef ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $this->setExpectedException(
            'RuntimeException',
            "/!\ Unauthorized tag name: 'toto'! Must use <major.minor.revision> format, e.g. '1.2.3'."
        );
        $sMsg = $this->_localExec(TWGIT_EXEC . ' tag list toto');
    }

    /**
     * @medium
     * @dataProvider providerTestListWithValidTag
     * @shcovers inc/twgit_tag.inc.sh::cmd_list
     */
    public function testList_WithValidTag ($sSubCmd, $sExpectedResult)
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            git config user.name 'Firstname Lastname' && \\
            git config user.email 'firstname.lastname@xyz.com'"
        );
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' release start -I');

        $this->_localExec('echo \'2;The subject of 2\' > .twgit_features_subject');
        $this->_localExec('echo \'4;The subject of 4\' >> .twgit_features_subject');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $this->_localExec(TWGIT_EXEC . ' feature start 2');
        $this->_localExec('git merge --no-ff feature-1; git commit --allow-empty -m "empty"; git push ' . self::ORIGIN . ';');
        $this->_localExec(TWGIT_EXEC . ' feature start 3');
        $this->_localExec(TWGIT_EXEC . ' feature start 4');
        $this->_localExec(TWGIT_EXEC . ' feature start 5');

        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 2');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 4');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 5');
        $this->_localExec(TWGIT_EXEC . ' release finish -I');

        $this->_localExec('echo \'1;The NEW subject of 1\' > .twgit_features_subject');
        $this->_localExec('echo \'2;The NEW subject of 2\' >> .twgit_features_subject');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' tag list' . $sSubCmd);
        $sMsg = preg_replace("/^Date:.*$/mi", 'Date: ---', $sMsg);
        $this->assertContains($sExpectedResult, $sMsg);
    }

    public function providerTestListWithValidTag () {
        return array(
            array(
                '', "git# git fetch --prune " . self::ORIGIN
                . "\n"
                . "\n(i) List 5 last tags:"
                . "\nTag: v1.2.3"
                . "\nTagger: Firstname Lastname <firstname.lastname@xyz.com>"
                . "\nDate: ---"
                . "\nNo feature included and it's the first tag."
                . "\n"
                . "\nTag: v1.3.0"
                . "\nTagger: Firstname Lastname <firstname.lastname@xyz.com>"
                . "\nDate: ---"
                . "\nIncluded features:"
                . "\n    - " . self::ORIGIN . "/feature-1 The NEW subject of 1"
                . "\n    - " . self::ORIGIN . "/feature-2 The NEW subject of 2"
                . "\n    - " . self::ORIGIN . "/feature-4 The subject of 4"
                . "\n    - " . self::ORIGIN . "/feature-5"
                . "\n"
            ),
            array(
                ' 1.2.3', "git# git fetch --prune " . self::ORIGIN
                . "\n"
                . "\nCheck valid ref name..."
                . "\nCheck valid tag name..."
                . "\n"
                . "\nTag: v1.2.3"
                . "\nTagger: Firstname Lastname <firstname.lastname@xyz.com>"
                . "\nDate: ---"
                . "\nNo feature included and it's the first tag."
                . "\n"
            ),
            array(
                ' 1.3.0', "git# git fetch --prune " . self::ORIGIN
                . "\n"
                . "\nCheck valid ref name..."
                . "\nCheck valid tag name..."
                . "\n"
                . "\nTag: v1.3.0"
                . "\nTagger: Firstname Lastname <firstname.lastname@xyz.com>"
                . "\nDate: ---"
                . "\nIncluded features:"
                . "\n    - " . self::ORIGIN . "/feature-1 The NEW subject of 1"
                . "\n    - " . self::ORIGIN . "/feature-2 The NEW subject of 2"
                . "\n    - " . self::ORIGIN . "/feature-4 The subject of 4"
                . "\n    - " . self::ORIGIN . "/feature-5"
                . "\n"
            ),
        );
    }

}
