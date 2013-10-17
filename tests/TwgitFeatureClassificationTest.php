<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 * @author Laurent Toussaint <lt.laurent.toussaint@gmail.com>
 */
class TwgitFeatureClassificationTest extends TwgitTestCase
{

    /**
     * Sets up the fixture, for example, open a network connection.
     * This method is called before a test is executed.
     */
    public function setUp ()
    {
        parent::setUp();
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.0.0 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_rev_parse
     */
    public function testGetGitRevParse_Empty ()
    {
        $sCmd = 'for key in "\${!REV_PARSE[@]}"; do printf "%s:%s" "\$key" "\${REV_PARSE[\$key]}"; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_rev_parse
     */
    public function testGetGitRevParse_WithoutParameters ()
    {
        $sCmd = 'get_git_rev_parse; for key in "\${!REV_PARSE[@]}"; do printf "%s:%s" "\$key" "\${REV_PARSE[\$key]}"; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_rev_parse
     */
    public function testGetGitRevParse_WithUnknownRef ()
    {
        $sCmd = 'get_git_rev_parse unknown-ref; '
            . 'for key in "\${!REV_PARSE[@]}"; do printf "%s:%s" "\$key" "\${REV_PARSE[\$key]}"; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('unknown-ref:', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_rev_parse
     */
    public function testGetGitRevParse_WithKnownRef ()
    {
        $sCmd = 'get_git_rev_parse ' . self::STABLE . '; '
            . 'for key in "\${!REV_PARSE[@]}"; do printf "%s:%s" "\$key" "\${REV_PARSE[\$key]}"; echo; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertRegExp('/^' . self::STABLE . ':[0-9a-f]{40}$/', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_rev_parse
     */
    public function testGetGitRevParse_With2Ref ()
    {
        $sCmd = 'git branch feature; get_git_rev_parse feature; get_git_rev_parse unknown-ref; '
            . 'for key in "\${!REV_PARSE[@]}"; do printf "%s:%s" "\$key" "\${REV_PARSE[\$key]}"; echo; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertRegExp('/^feature:[0-9a-f]{40}$/m', $sMsg);
        $this->assertRegExp('/^unknown-ref:$/m', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_rev_parse
     */
    public function testGetGitRevParse_WithFailedFirstCall ()
    {
        $sCmd = 'get_git_rev_parse feature; git branch feature; get_git_rev_parse feature; '
            . 'for key in "\${!REV_PARSE[@]}"; do printf "%s:%s" "\$key" "\${REV_PARSE[\$key]}"; echo; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertRegExp('/^feature:[0-9a-f]{40}$/', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_rev_parse
     */
    public function testGetGitRevParse_WithFilledCache ()
    {
        $sCmd = 'git branch feature; get_git_rev_parse feature; git branch -d feature 1>/dev/null; git branch feature; '
            . 'for key in "\${!REV_PARSE[@]}"; do printf "%s:%s" "\$key" "\${REV_PARSE[\$key]}"; echo; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertRegExp('/^feature:[0-9a-f]{40}$/', $sMsg);
    }



    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_Empty ()
    {
        $sCmd = 'for key in "\${!MERGED_BRANCHES[@]}"; do printf "%s:%s" "\$key" "\${MERGED_BRANCHES[\$key]}"; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithoutParameters ()
    {
        $sCmd = 'get_git_merged_branches; '
        . 'for key in "\${!MERGED_BRANCHES[@]}"; do printf "%s:%s" "\$key" "\${MERGED_BRANCHES[\$key]}"; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithUnknownRef ()
    {
        $sCmd = 'get_git_merged_branches unknown-ref; '
        . 'for key in "\${!MERGED_BRANCHES[@]}"; do printf "%s:%s" "\$key" "\${MERGED_BRANCHES[\$key]}"; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('unknown-ref:', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithKnownRef ()
    {
        $release = self::_remote('release-1.1.0');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $sCmd = 'get_git_merged_branches ' . $release . '; echo \${MERGED_BRANCHES[' . $release . ']}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($release . ' ' . self::$_remoteStable, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithFailedFirstCall ()
    {
        $release = self::_remote('release-1.1.0');
        $sCmd = 'get_git_merged_branches ' . $release . '; ' . TWGIT_EXEC . ' release start -I 1>/dev/null 2>&1; '
            . 'get_git_merged_branches ' . $release . '; echo \${MERGED_BRANCHES[' . $release . ']}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($release . ' ' . self::$_remoteStable, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithFilledCache ()
    {
        $release = self::_remote('release-1.1.0');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $sCmd = 'get_git_merged_branches ' . $release . '; ' . TWGIT_EXEC . ' release remove 1.1.0 1>/dev/null 2>&1; '
            . 'get_git_merged_branches ' . $release . '; echo \${MERGED_BRANCHES[' . $release . ']}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($release . ' ' . self::$_remoteStable, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithNewFeatureAndRelease ()
    {
        $release = self::_remote('release-1.1.0');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $sCmd = 'get_git_merged_branches ' . $release . '; echo \${MERGED_BRANCHES[' . $release . ']}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($release . ' ' . self::$_remoteStable, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithFeatureMergeIntoRelease ()
    {
        $release = self::_remote('release-1.1.0');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 1');
        $sCmd = 'get_git_merged_branches ' . $release . '; echo \${MERGED_BRANCHES[' . $release . ']}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals(self::_remote('feature-1') . ' ' . $release . ' ' . self::$_remoteStable, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_With2InterdependentFeatures1 ()
    {
        $release = self::_remote('release-1.1.0');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $this->_localExec(TWGIT_EXEC . ' feature start 2');
        $this->_localExec('git merge feature-1');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 1');
        $sCmd = 'get_git_merged_branches ' . $release . '; echo \${MERGED_BRANCHES[' . $release . ']}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals(self::_remote('feature-1') . ' ' . $release . ' ' . self::$_remoteStable, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_With2InterdependentFeatures2 ()
    {
        $release = self::_remote('release-1.1.0');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $this->_localExec(TWGIT_EXEC . ' feature start 2');
        $this->_localExec('git merge feature-1');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 2');
        $sCmd = 'get_git_merged_branches ' . $release . '; echo \${MERGED_BRANCHES[' . $release . ']}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals(self::_remote('feature-1') . ' ' . self::_remote('feature-2') . ' ' . $release . ' ' . self::$_remoteStable, $sMsg);
    }



    /**
     * @shcovers inc/common.inc.sh::get_git_merge_base
     */
    public function testGetGitMergedBase_Empty ()
    {
        $sCmd = 'for key in "\${!MERGE_BASE[@]}"; do printf "%s:%s" "\$key" "\${MERGE_BASE[\$key]}"; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merge_base
     */
    public function testGetGitMergedBase_WithoutParameters ()
    {
        $sCmd = 'get_git_merge_base; for key in "\${!MERGE_BASE[@]}"; do printf "%s:%s" "\$key" "\${MERGE_BASE[\$key]}"; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merge_base
     */
    public function testGetGitMergedBase_WithUnknownRef ()
    {
        $sCmd = 'get_git_merge_base unknown ref; '
        . 'for key in "\${!MERGE_BASE[@]}"; do printf "%s:%s" "\$key" "\${MERGE_BASE[\$key]}"; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('unknown|ref:', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merge_base
     */
    public function testGetGitMergedBase_WithKnownRef ()
    {
        $release = self::_remote('release-1.1.0');
        $feature = self::_remote('feature-1');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $sRev = $this->_localExec("git merge-base $release $feature");
        $sCmd = 'r="' . $release . '"; get_git_rev_parse \$r; r_rev="\${REV_PARSE[\$r]}"; '
            . 'f="' . $feature . '"; get_git_rev_parse \$f; f_rev="\${REV_PARSE[\$f]}"; '
            . 'get_git_merge_base \$r \$f; echo \${MERGE_BASE[\$r|\$f]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sRev, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merge_base
     */
    public function testGetGitMergedBase_WithFilledCache ()
    {
        $release = self::_remote('release-1.1.0');
        $feature = self::_remote('feature-1');
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $sRev = $this->_localExec("git merge-base $release $feature");
        $sCmd = 'r="' . $release . '"; get_git_rev_parse \$r; r_rev="\${REV_PARSE[\$r]}"; '
            . 'f="' . $feature . '"; get_git_rev_parse \$f; f_rev="\${REV_PARSE[\$f]}"; '
            . 'get_git_merge_base \$r \$f; '
            . TWGIT_EXEC . ' feature remove 1 1>/dev/null 2>&1; '
            . 'get_git_merge_base \$r \$f; '
            . 'echo \${MERGE_BASE[\$r|\$f]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sRev, $sMsg);
    }



    /**
     * @dataProvider providerTestGetFeatures_WithoutFeatureNorRelease
     * @shcovers inc/common.inc.sh::get_features
     */
    public function testGetFeatures_WithoutFeatureNorRelease ($aFeatureTypes, $sInRelease, $aOut)
    {
        $aMsg = array();
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' ' . $sInRelease . '; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);
    }

    public function providerTestGetFeatures_WithoutFeatureNorRelease ()
    {
        $aFeatureTypes = array('', 'xyz', 'free');
        return array(
            array($aFeatureTypes, '', array('', '', '')),
            array($aFeatureTypes, 'unknow-release', array('', '', '')),
        );
    }

    /**
     * @dataProvider providerTestGetFeatures_With1FreeFeatureWithoutRelease
     * @shcovers inc/common.inc.sh::get_features
     */
    public function testGetFeatures_With1FreeFeatureWithoutRelease ($aFeatureTypes, $sInRelease, $aOut)
    {
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $aMsg = array();
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' ' . $sInRelease . '; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);
    }

    public function providerTestGetFeatures_With1FreeFeatureWithoutRelease ()
    {
        $aFeatureTypes = array('', 'xyz', 'free', 'merged', 'merged_in_progress');
        return array(
            array($aFeatureTypes, '', array('', '', self::_remote('feature-1'), '', '')),
            array($aFeatureTypes, 'unknow-release', array('', '', self::_remote('feature-1'), '', '')),
        );
    }

    /**
     * @dataProvider providerTestGetFeatures_WithFeaturesAndRelease
     * @shcovers inc/common.inc.sh::get_features
     */
    public function testGetFeatures_WithFeaturesAndRelease ($aFeatureTypes, $sInRelease, $aOut)
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; '
            . TWGIT_EXEC . ' feature start 3; '
            . TWGIT_EXEC . ' feature start 4; '
            . TWGIT_EXEC . ' feature merge-into-release 1; '
            . TWGIT_EXEC . ' feature merge-into-release 4; '
            . TWGIT_EXEC . ' feature start 4; git commit --allow-empty -m "empty"; git push ' . self::ORIGIN
        );

        $aMsg = array();
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' ' . $sInRelease . '; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);
    }

    public function providerTestGetFeatures_WithFeaturesAndRelease ()
    {
        $aFeatureTypes = array('', 'xyz', 'free', 'merged', 'merged_in_progress');

        list($f1, $f2, $f3, $f4) = array(
            self::_remote('feature-1'),
            self::_remote('feature-2'),
            self::_remote('feature-3'),
            self::_remote('feature-4')
        );

        return array(
            array($aFeatureTypes, '', array('', '', "$f4 $f3 $f2 $f1", '', '')),
            array($aFeatureTypes, 'unknow-release', array('', '', "$f4 $f3 $f2 $f1", '', '')),
            array($aFeatureTypes, 'release-1.1.0', array('', '', "$f3 $f2", $f1, $f4)),
        );
    }

    /**
     * F2  F1  Realease
     *  \   \   \
     *   \   \   o---o---o--->
     *    \   \         /
     *     \   o---o---o
     *      \       \
     *       o---o---o--->
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures1 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature merge-into-release 1'
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array(self::_remote('feature-2'), self::_remote('feature-1'), '');
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * F3  F2  F1  Realease
     *  \   \   \   \
     *   \   \   \   o---o---o--->
     *    \   \   \         /
     *     \   \   o---o---o--->
     *      \   \   \           \
     *       \   o---o--->       \
     *        \                   \
     *         o---o---o---o---o---o--->
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures2 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature merge-into-release 1; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature start 3; git merge --no-ff feature-1; git push ' . self::ORIGIN . '; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array(self::_remote('feature-3') . ' ' . self::_remote('feature-2'), '', self::_remote('feature-1'));
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * F3  F2  F1  Realease
     *  \   \   \   \
     *   \   \   \   o---o---o--->
     *    \   \   \         /
     *     \   \   o---o---o---o--->
     *      \   \   \           \
     *       \   o---o--->       \
     *        \                   \
     *         o---o---o---o---o---o--->
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures2b ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature merge-into-release 1; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature start 3; git merge --no-ff feature-1; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push ' . self::ORIGIN . '; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array(self::_remote('feature-3') . ' ' . self::_remote('feature-2'), '', self::_remote('feature-1'));
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * F1  Realease
     *  \   \
     *   \   o---o--->
     *    \       \
     *     o---o---o--->
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures3 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; git merge release-1.1.0; git push ' . self::ORIGIN
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array(self::_remote('feature-1'), '', '');
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * F2  F1  Realease
     *  \   \   \
     *   \   \   o---o---o---o--->
     *    \   \             /
     *     \   o--->       /
     *      \       \     /
     *       o---o---o--->
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures4 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature merge-into-release 2'
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', self::_remote('feature-2') . ' ' . self::_remote('feature-1'), '');
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * F2  F1  Realease
     *  \   \   \
     *   \   \   o---o---o---o--->
     *    \   \             /
     *     \   o--->       /
     *      \       \     /
     *       o---o---o---o--->
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures5 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature merge-into-release 2; '
            . TWGIT_EXEC . ' feature start 2; git commit --allow-empty -m "empty"; git push ' . self::ORIGIN . '; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', self::_remote('feature-1'), self::_remote('feature-2'));
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * F2  F1  Realease
     *  \   \   \
     *   \   \   o---o---o---o--->
     *    \   \             /
     *     \   o---o--->   /
     *      \       \     /
     *       o---o---o--->
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures6 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature merge-into-release 2'
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', self::_remote('feature-2'), self::_remote('feature-1'));
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * F2  F1  Realease
     *  \   \   \
     *   \   \   o---o---o---o--->
     *    \   \             /
     *     \   o---o--->   /
     *      \       \     /
     *       o---o---o---o--->
     *
     * @medium
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures7 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push ' . self::ORIGIN . '; '
            . TWGIT_EXEC . ' feature merge-into-release 2; '
            . TWGIT_EXEC . ' feature start 2; git commit --allow-empty -m "empty"; git push ' . self::ORIGIN . '; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', '', self::_remote('feature-2') . ' ' . self::_remote('feature-1'));
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * F1  Realease
     *  \   \
     *   \   o---o--->
     *    \       \
     *     o---o--->
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures8 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; git merge --no-ff release-1.1.0; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array(self::_remote('feature-1'), '', '');
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * F1  Realease
     *  \   \
     *   \   o---o--->
     *    \       \
     *     o---o---o--->
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures9 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; git merge --no-ff release-1.1.0; '
            . 'git commit --allow-empty -m "empty"; git push ' . self::ORIGIN . '; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array(self::_remote('feature-1'), '', '');
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $sCmd = 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sMsg, $aMsg[1]);
    }

    /**
     * -o---A--->         Stable
     *   \   \
     *    \   o---o--->   Release
     *     \     /
     *      o---B---C---> F1
     * puis merge du tag A dans la feature en C.
     *
     * Le problème ici est que le merge-base de (R, F1) est A ou B (plusieurs possibilités).
     * Par défaut, sans l'option --all, git merge-base retourne ici A qui induit (avant fix) une disparition de F1
     * de la release (ou des démos).
     *
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_WithLastTagMergedIntoFeature ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' release finish; '
            . TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature merge-into-release 1; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', self::_remote('feature-1'), '');
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.2.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);

        $this->_localExec(TWGIT_EXEC . ' feature start 1; git merge --no-ff ' . self::STABLE . '; git push ' . self::ORIGIN . ' feature-1');
        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', '', self::_remote('feature-1'));
        foreach ($aFeatureTypes as $sType) {
            $sCmd = 'get_features ' . $sType . ' release-1.2.0; echo \$GET_FEATURES_RETURN_VALUE';
            $aMsg[] = $this->_localShellCodeCall($sCmd);
        }
        $this->assertEquals($aOut, $aMsg);
    }

    /**
     * Désactivé car en fait get_merged_features et get_features s'appellent mutuellement,
     * ce qui n'est pas terrible...
     *
     * @shcovers inc/common.inc.sh::get_merged_features
     */
//     public function testGetMergedFeatures_ThrowExceptionWhenInconsistent ()
//     {
//         $this->_localExec(
//             TWGIT_EXEC . ' release start -I; '
//             . TWGIT_EXEC . ' feature start 1; '
//             . TWGIT_EXEC . ' feature merge-into-release 1'
//         );

//         $sCmd = 'get_features merged release-1.1.0; echo \$GET_FEATURES_RETURN_VALUE';
//         $sMsg1 = $this->_localShellCodeCall($sCmd);
//         $this->assertEquals(self::_remote('feature-1'), $sMsg1);

//         $sCmd = "eval 'function get_git_merged_branches () { echo y;}'; "
//             . 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
//         $sMsg2 = $this->_localShellCodeCall($sCmd);
//         $this->assertEquals($sMsg2, $sMsg1);
//     }
}
