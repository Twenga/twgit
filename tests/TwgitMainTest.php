<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 * @author Laurent Toussaint <lt.laurent.toussaint@gmail.com>
 */
class TwgitMainTest extends TwgitTestCase
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
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_ThrowExceptionWhenTagParameterMissing ()
    {
        $this->setExpectedException('RuntimeException', 'Missing argument <tag>!');
        $this->_localExec(TWGIT_EXEC . ' init');
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_ThrowExceptionWhenURLNeeded ()
    {
        $this->setExpectedException('RuntimeException', "Remote 'origin' repository url required!");
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3');
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_ThrowExceptionWhenBadRemoteRepository ()
    {
        $this->setExpectedException('RuntimeException', "Could not fetch 'origin'!");
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_Empty ()
    {
        $this->_remoteExec('git init');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->assertContains("Initialized empty Git repository in " . TWGIT_REPOSITORY_LOCAL_DIR . "/.git/", $sMsg);
        $this->assertNotContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR, $sMsg);

        $this->assertContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_WithGitInit ()
    {
        $this->_remoteExec('git init');
        $this->_localExec('git init');
        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->assertNotContains("Initialized empty Git repository in " . TWGIT_REPOSITORY_LOCAL_DIR . "/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR, $sMsg);

        $this->assertContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_WithGitInitAndAddRemote ()
    {
        $this->_remoteExec('git init');
        $this->_localExec('git init && git remote add origin ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3');

        $this->assertNotContains("Initialized empty Git repository in " . TWGIT_REPOSITORY_LOCAL_DIR . "/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertNotContains("git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR, $sMsg);

        $this->assertContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_WithLocalMaster ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit'"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->assertNotContains("Initialized empty Git repository in " . TWGIT_REPOSITORY_LOCAL_DIR . "/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR, $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::init
     */
    public function testInit_WithRemoteMaster ()
    {
        $this->_remoteExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit'"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->assertContains("Initialized empty Git repository in " . TWGIT_REPOSITORY_LOCAL_DIR . "/.git/", $sMsg);
        $this->assertNotContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR, $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
    * @shcovers inc/common.inc.sh::init
    */
    public function testInit_WithLocalStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit' && \\
            git branch -m stable"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->assertNotContains("Initialized empty Git repository in " . TWGIT_REPOSITORY_LOCAL_DIR . "/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertContains("git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR, $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertContains("git push --set-upstream origin stable", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
    * @shcovers inc/common.inc.sh::init
    */
    public function testInit_WithLocalAndRemoteStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit' && \\
            git branch -m stable && \\
            git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR . " && \\
            git push --set-upstream origin stable"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->assertNotContains("Initialized empty Git repository in " . TWGIT_REPOSITORY_LOCAL_DIR . "/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertNotContains("git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR, $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git push --set-upstream origin stable", $sMsg);
        $this->assertNotContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
    * @shcovers inc/common.inc.sh::init
    */
    public function testInit_WithRemoteStable ()
    {
        $this->_remoteExec('git init');
        $this->_localExec(
            "git init && \\
            touch .gitignore && \\
            git add . && \\
            git commit -m 'initial commit' && \\
            git branch -m stable && \\
            git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR . " && \\
            git push --set-upstream origin stable && \\
            git checkout -b foo && \\
            git branch -D stable"
        );

        $sMsg = $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);

        $this->assertNotContains("Initialized empty Git repository in " . TWGIT_REPOSITORY_LOCAL_DIR . "/.git/", $sMsg);
        $this->assertContains("Check clean working tree...", $sMsg);

        $this->assertNotContains("git remote add origin " . TWGIT_REPOSITORY_ORIGIN_DIR, $sMsg);

        $this->assertNotContains("git branch -m stable", $sMsg);
        $this->assertNotContains("git checkout -b stable master", $sMsg);
        $this->assertNotContains("git checkout -b stable origin/master", $sMsg);
        $this->assertNotContains("git push --set-upstream origin stable", $sMsg);
        $this->assertContains("git checkout --track -b stable origin/stable", $sMsg);

        $this->assertContains('git tag -a v1.2.3 -m "[twgit] First tag."', $sMsg);
    }

    /**
     * @dataProvider providerTestGetContributors_WithOnly1Author
     * @shcovers inc/common.inc.sh::get_contributors
     */
    public function testGetContributors_WithOnly1Author ($sConfEmailDomainName, $sExpectedResult)
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(
            "git config user.name 'Firstname Lastname' && \\
            git config user.email 'firstname.lastname@xyz.com' && \\
            " . TWGIT_EXEC . ' feature start 1'
        );
        $sCmd = 'TWGIT_EMAIL_DOMAIN_NAME=\"' . $sConfEmailDomainName . '\" && get_contributors feature-1 3';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerTestGetContributors_WithOnly1Author ()
    {
        return array(
            array('', 'Firstname Lastname <firstname.lastname@xyz.com>'),
            array('xyz.com', 'Firstname Lastname <firstname.lastname@xyz.com>'),
            array('other.unknown', ''),
        );
    }

    /**
     * @dataProvider providerTestGetContributors_WithMultipleAuthors
     * @shcovers inc/common.inc.sh::get_contributors
     */
    public function testGetContributors_WithMultipleAuthors ($sConfEmailDomainName, $iMaxNbToDisplay, $sExpectedResult)
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(
            "git config user.name 'F1 L1' && \\
            git config user.email 'f1.l1@xyz.com' && \\
            " . TWGIT_EXEC . ' feature start 1'
        );
        $this->_localExec(
            "git config user.name 'F2 L2' && \\
            git config user.email 'f2.l2@xyz.com' && \\
            " . 'git commit --allow-empty -m "A" && git commit --allow-empty -m "B"'
            . ' && git commit --allow-empty -m "C" && git push origin'
        );
        $this->_localExec(
            "git config user.name 'F3 L3' && \\
            git config user.email 'f3.l3@other.com' && \\
            " . 'git commit --allow-empty -m "D" && git commit --allow-empty -m "E" && git push origin'
        );
        $sCmd = 'TWGIT_EMAIL_DOMAIN_NAME=\"' . $sConfEmailDomainName . '\" '
              . '&& get_contributors feature-1 ' . $iMaxNbToDisplay;
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerTestGetContributors_WithMultipleAuthors ()
    {
        return array(
            array('', 1, 'F2 L2 <f2.l2@xyz.com>'),
            array('', 3, "F2 L2 <f2.l2@xyz.com>\nF3 L3 <f3.l3@other.com>\nF1 L1 <f1.l1@xyz.com>"),
            array('xyz.com', 1, 'F2 L2 <f2.l2@xyz.com>'),
            array('xyz.com', 3, "F2 L2 <f2.l2@xyz.com>\nF1 L1 <f1.l1@xyz.com>"),
            array('other.unknown', 1, ''),
            array('other.unknown', 3, ''),
        );
    }

    /**
     * @dataProvider providerDisplayRankContributors_WithOnly1Author
     * @shcovers inc/common.inc.sh::display_rank_contributors
     */
    public function testDisplayRankContributors_WithOnly1Author (
        $sConfEmailDomainName, $iMaxNbToDisplay, $sExpectedResult
    ) {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(
            "git config user.name 'Firstname Lastname' && \\
            git config user.email 'firstname.lastname@xyz.com' && \\
            " . TWGIT_EXEC . ' feature start 1'
        );
        $sCmd = 'TWGIT_EMAIL_DOMAIN_NAME=\"' . $sConfEmailDomainName . '\"'
              . ' && TWGIT_DEFAULT_NB_COMMITTERS=3'
              . ' && display_rank_contributors feature-1 ' . $iMaxNbToDisplay;
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerDisplayRankContributors_WithOnly1Author ()
    {
        return array(
            array('', '', "First 3 committers into 'origin/feature-1' remote branch:\nFirstname Lastname <firstname.lastname@xyz.com>\n"),
            array('', 1, "First committer into 'origin/feature-1' remote branch:\nFirstname Lastname <firstname.lastname@xyz.com>\n"),
            array('', 2, "First 2 committers into 'origin/feature-1' remote branch:\nFirstname Lastname <firstname.lastname@xyz.com>\n"),
            array('xyz.com', '', "First 3 committers into 'origin/feature-1' remote branch (filtered by email domain: '@xyz.com'):\nFirstname Lastname <firstname.lastname@xyz.com>\n"),
            array('xyz.com', 1, "First committer into 'origin/feature-1' remote branch (filtered by email domain: '@xyz.com'):\nFirstname Lastname <firstname.lastname@xyz.com>\n"),
            array('xyz.com', 2, "First 2 committers into 'origin/feature-1' remote branch (filtered by email domain: '@xyz.com'):\nFirstname Lastname <firstname.lastname@xyz.com>\n"),
            array('other.unknown', '', "First 3 committers into 'origin/feature-1' remote branch (filtered by email domain: '@other.unknown'):\nnobody\n"),
            array('other.unknown', 1, "First committer into 'origin/feature-1' remote branch (filtered by email domain: '@other.unknown'):\nnobody\n"),
            array('other.unknown', 2, "First 2 committers into 'origin/feature-1' remote branch (filtered by email domain: '@other.unknown'):\nnobody\n"),
        );
    }

    /**
     * @dataProvider providerTestGetContributors_WithMultipleAuthors
     * @shcovers inc/common.inc.sh::display_rank_contributors
     */
    public function testDisplayRankContributors_WithMultipleAuthors ($sConfEmailDomainName, $iMaxNbToDisplay, $sExpectedResult)
    {
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec(
            "git config user.name 'F1 L1' && \\
            git config user.email 'f1.l1@xyz.com' && \\
            " . TWGIT_EXEC . ' feature start 1'
        );
        $this->_localExec(
            "git config user.name 'F2 L2' && \\
            git config user.email 'f2.l2@xyz.com' && \\
            " . 'git commit --allow-empty -m "A" && git commit --allow-empty -m "B"'
            . ' && git commit --allow-empty -m "C" && git push origin'
        );
        $this->_localExec(
            "git config user.name 'F3 L3' && \\
            git config user.email 'f3.l3@other.com' && \\
            " . 'git commit --allow-empty -m "D" && git commit --allow-empty -m "E" && git push origin'
        );
        $sCmd = 'TWGIT_EMAIL_DOMAIN_NAME=\"' . $sConfEmailDomainName . '\" '
              . ' && TWGIT_DEFAULT_NB_COMMITTERS=3'
              . '&& get_contributors feature-1 ' . $iMaxNbToDisplay;
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerDisplayRankContributors_WithMultipleAuthors ()
    {
        return array(
            array('', '', "First 3 committers into 'origin/feature-1' remote branch:\nF2 L2 <f2.l2@xyz.com>\nF3 L3 <f3.l3@other.com>\nF1 L1 <f1.l1@xyz.com>\n"),
            array('', 1, "First committer into 'origin/feature-1' remote branch:\nF2 L2 <f2.l2@xyz.com>\n"),
            array('', 2, "First 2 committers into 'origin/feature-1' remote branch:\nF2 L2 <f2.l2@xyz.com>\nF3 L3 <f3.l3@other.com>\n"),
            array('xyz.com', '', "First 3 committers into 'origin/feature-1' remote branch (filtered by email domain: '@xyz.com'):\nF2 L2 <f2.l2@xyz.com>\nF1 L1 <f1.l1@xyz.com>\n"),
            array('xyz.com', 1, "First committer into 'origin/feature-1' remote branch (filtered by email domain: '@xyz.com'):\nF2 L2 <f2.l2@xyz.com>\n"),
            array('xyz.com', 2, "First 2 committers into 'origin/feature-1' remote branch (filtered by email domain: '@xyz.com'):\nF2 L2 <f2.l2@xyz.com>\nF1 L1 <f1.l1@xyz.com>\n"),
            array('other.unknown', '', "First 3 committers into 'origin/feature-1' remote branch (filtered by email domain: '@other.unknown'):\nnobody\n"),
            array('other.unknown', 1, "First committer into 'origin/feature-1' remote branch (filtered by email domain: '@other.unknown'):\nnobody\n"),
            array('other.unknown', 2, "First 2 committers into 'origin/feature-1' remote branch (filtered by email domain: '@other.unknown'):\nnobody\n"),
        );
    }
}
