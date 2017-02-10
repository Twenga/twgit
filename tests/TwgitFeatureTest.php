<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 * @author Geoffroy Letournel <gletournel@hi-media.com>
 * @author Sebastien Hanicotte <shanicotte@hi-media.com>
 */
class TwgitFeatureTest extends TwgitTestCase
{

    /**
     */
    public function testStart_WithPrefixNaming ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature start feature-42');
        $this->assertContains("Assume feature was '42' instead of 'feature-42'", $sMsg);
    }

    public function testStart_WithAmbiguousRef ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $this->assertNotContains("warning: refname 'v1.2.3' is ambiguous.", $sMsg);
        $this->assertNotContains("fatal: Ambiguous object name: 'v1.2.3'.", $sMsg);
    }

    /**
     */
    public function testList_WithAmbiguousRef ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('git branch v1.2.3 v1.2.3');
        $this->_localExec(TWGIT_EXEC . ' feature start 42');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature list');
        $this->assertNotContains("warning: refname 'v1.2.3' is ambiguous.", $sMsg);
    }

    /**
     */
    public function testStart_WithNoConnectorSetted ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->_localShellCodeCall('function getFeatureSubject(){ echo;}; . \$TWGIT_INC_DIR/twgit_feature.inc.sh; cmd_start 1');
        $sMsg = $this->_localExec('git show HEAD --format="%s"');
        $this->assertEquals("[twgit] Init feature 'feature-1'.", $sMsg);
        $sMsg = $this->_localExec('git show HEAD~2 --format="%s"'); // HEAD~1 = 'Add minimal .gitignore'…
        $this->assertEquals("[twgit] Init branch 'stable'.", $sMsg);
    }

    /**
     */
    public function testStart_WithConnectorSetted ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->_localShellCodeCall('function getFeatureSubject(){ echo \"Bla\'\\\\\"bla\";}; . \$TWGIT_INC_DIR/twgit_feature.inc.sh; cmd_start 1');
        $sMsg = $this->_localExec('git show HEAD --format="%s"');
        $this->assertEquals("[twgit] Init feature 'feature-1': Bla'\"bla.", $sMsg);
        $sMsg = $this->_localExec('git show HEAD~2 --format="%s"'); // HEAD~1 = 'Add minimal .gitignore'…
        $this->assertEquals("[twgit] Init branch 'stable'.", $sMsg);
    }

    /**
     */
    public function testList_WithFullColoredGit ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $this->_localExec(
            "git config color.branch always\n"
            . "git config color.diff always\n"
            . "git config color.interactive always\n"
            . "git config color.status always\n"
            . "git config color.ui always\n"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature list');
        $this->assertContains("(i) Remote free features:\nFeature: " . self::_remote('feature-1') . "* (from v1.2.3)", $sMsg);
    }

    /**
    * @dataProvider providerTestListAboutBranchesOutOfProcess
    */
    public function testList_AboutBranchesOutOfProcess ($sLocalCmd, $sExpectedContent, $sNotExpectedContent)
    {
        $this->_remoteExec('git init && git commit --allow-empty -m "-" && git checkout -b feature-currentOfNonBareRepo');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('cd ' . TWGIT_REPOSITORY_SECOND_REMOTE_DIR . ' && git init');
        $this->_localExec('git remote add second ' . TWGIT_REPOSITORY_SECOND_REMOTE_DIR);

        $this->_localExec($sLocalCmd);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature list');
        if ( ! empty($sExpectedContent)) {
            $this->assertContains($sExpectedContent, $sMsg);
        }
        if ( ! empty($sNotExpectedContent)) {
            $this->assertNotContains($sNotExpectedContent, $sMsg);
        }
    }

    public function providerTestListAboutBranchesOutOfProcess ()
    {
        return array(
            array(':', '', 'Following branches are out of process'),
            array(':', '', 'Following local branches are ambiguous'),
            array(
                'git checkout -b feature-X && git push ' . self::ORIGIN . ' feature-X'
                    . ' && git checkout -b release-X && git push ' . self::ORIGIN . ' release-X'
                    . ' && git checkout -b hotfix-X && git push ' . self::ORIGIN . ' hotfix-X'
                    . ' && git checkout -b demo-X && git push ' . self::ORIGIN . ' demo-X'
                    . ' && git checkout -b master && git push ' . self::ORIGIN . ' master'
                    . ' && git checkout -b outofprocess && git push ' . self::ORIGIN . ' outofprocess'
                    . ' && git remote set-head ' . self::ORIGIN . ' ' . self::STABLE,
                "/!\ Following branches are out of process: '" . self::_remote('outofprocess') . "'!",
                'Following local branches are ambiguous'
            ),
            array(
                'git checkout -b outofprocess && git push ' . self::ORIGIN . ' outofprocess && git push second outofprocess'
                    . ' && git checkout -b out2 && git push ' . self::ORIGIN . ' out2 && git push second out2',
                "/!\ Following branches are out of process: '" . self::_remote('out2') . "', '" . self::_remote('outofprocess') . "'!",
                'Following local branches are ambiguous'
            ),
            array(
                'git branch v1.2.3 v1.2.3',
                "/!\ Following local branches are ambiguous: 'v1.2.3'!",
                'Following branches are out of process'
            ),
            array(
                'git checkout -b outofprocess && git push ' . self::ORIGIN . ' outofprocess && git branch v1.2.3 v1.2.3',
                "/!\ Following branches are out of process: '" . self::_remote('outofprocess') . "'!\n"
                    . "/!\ Following local branches are ambiguous: 'v1.2.3'!",
                ''
            ),
        );
    }

    public function testMergeIntoRelease_WhenReleaseNotYetFetched ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $sMsg = $this->_localExec('cd ' . TWGIT_REPOSITORY_SECOND_LOCAL_DIR
            . ' && git init && git remote add ' . self::ORIGIN . ' ' . TWGIT_REPOSITORY_ORIGIN_DIR
            . ' && git pull ' . self::ORIGIN . ' ' . self::STABLE . ':' . self::STABLE
            . ' && ' . TWGIT_EXEC . ' release start -I');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 42');
        $sExpectedMsg = "git# git pull " . self::ORIGIN . " release-1.3.0\n"
            . "From " . TWGIT_REPOSITORY_ORIGIN_DIR . "\n"
            . " * branch            release-1.3.0 -> FETCH_HEAD\n"
            . "Already up-to-date.\n"
            . "git# git merge --no-ff feature-42\n"
            . "Already up-to-date!";
        $this->assertContains($sExpectedMsg, $sMsg);
        $this->assertContains("git# git push " . self::ORIGIN . " release-1.3.0", $sMsg);
    }

    public function testMergeIntoRelease_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $sMsg = $this->_localExec('cd ' . TWGIT_REPOSITORY_SECOND_LOCAL_DIR
            . ' && git init && git remote add ' . self::ORIGIN . ' ' . TWGIT_REPOSITORY_ORIGIN_DIR
            . ' && git pull ' . self::ORIGIN . ' ' . self::STABLE . ':' . self::STABLE
            . ' && ' . TWGIT_EXEC . ' release start -I');

        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature merge-into-release feature-42');
        $this->assertContains("Assume feature was '42' instead of 'feature-42'", $sMsg);
    }

    public function testCommiters_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature committers feature-42');
        $this->assertContains("Assume feature was '42' instead of 'feature-42'", $sMsg);
    }

    public function testMigrate_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_remoteExec('git checkout ' . self::STABLE . ' && git branch toto');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature migrate -I toto feature-42');
        $this->assertContains("Assume feature was '42' instead of 'feature-42'", $sMsg);
    }

    public function testRemove_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $this->_localExec('git checkout ' . self::STABLE);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature remove feature-42');
        $this->assertContains("Assume feature was '42' instead of 'feature-42'", $sMsg);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature list');
        $this->assertNotContains("feature-42", $sMsg);
    }

    public function testStatus_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature status feature-42');
        $this->assertContains("Assume feature was '42' instead of 'feature-42'", $sMsg);
}

    public function testWhatChanged_WithPrefixes ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' feature what-changed feature-42');
        $this->assertContains("Assume feature was '42' instead of 'feature-42'", $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::update_version_information
     */
    public function testStartWithVersionInfo ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(TWGIT_EXEC . ' feature start 42');
        $this->_localExec('echo "TWGIT_VERSION_INFO_PATH=\'not_exists,csv_tags\'" >> .twgit');
        $this->_localExec('cp ' . TWGIT_TESTS_DIR . '/resources/csv_tags csv_tags');
        $this->_localExec('git add .');
        $this->_localExec('git commit -m "Adding testing files"');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 42');
        $this->_localExec(TWGIT_EXEC . ' release finish -I');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $sResult = $this->_localExec('cat csv_tags');
        $sExpected = "\$Id:1.4.0\$\n"
            . "-------\n"
            . "\$Id:1.4.0\$\n"
            . "-------\n"
            . "\$id\$\n"
            . "-------\n"
            . "\$Id:1.4.0\$ \$Id:1.4.0\$";
        $this->assertEquals($sExpected, $sResult);
    }

    /**
     * @dataProvider provideStartFrom
     */
    public function testStartFrom_WithoutRemote ($sSourceBranchType)
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('\RuntimeException', "Remote branch '" . self::_remote($sSourceBranchType . '-51') ."' not found!");
        $this->_localExec(TWGIT_EXEC . ' feature start 42 from-' . $sSourceBranchType . ' 51');
    }

    /**
     * @dataProvider provideStartFrom
     */
    public function testStartFrom_WithExistingRemote ($sSourceBranchType)
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_remoteExec(
            'git checkout -b ' . $sSourceBranchType . '-51'
            . ' && git commit --allow-empty -m "Initialize ' . $sSourceBranchType . '-51"'
            . ' && touch the-chosen-one'
            . ' && git add .'
            . ' && git commit -m "Add the chosen one"'
        );
        $this->_localExec(TWGIT_EXEC . ' feature start 42 from-' . $sSourceBranchType . ' 51');
        $sResult = $this->_localExec('ls');
        $this->assertContains('the-chosen-one', $sResult);
    }

    public function provideStartFrom ()
    {
        return array(
            array('feature'),
            array('demo'),
        );
    }

    public function testStartFromRelease_WithoutRemote ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->setExpectedException('\RuntimeException', 'No release in progress!');
        $this->_localExec(TWGIT_EXEC . ' feature start 42 from-release');
    }

    public function testStartFromRelease_WithExistingRemote ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_remoteExec(
            'git checkout -b release-1.3.0'
            . ' && git commit --allow-empty -m "Initialize release-1.3.0"'
            . ' && touch the-chosen-one'
            . ' && git add .'
            . ' && git commit -m "Add the chosen one"'
        );
        $this->_localExec(TWGIT_EXEC . ' feature start 42 from-release');
        $sResult = $this->_localExec('ls');
        $this->assertContains('the-chosen-one', $sResult);
    }
}

