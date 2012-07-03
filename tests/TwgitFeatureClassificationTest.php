<?php

/**
 * @package Tests
 * @author Geoffroy AUBRY <geoffroy.aubry@hi-media.com>
 */
class TwgitFeatureClassificationTest extends TwgitTestCase
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
        $this->_remoteExec('git init');
        $this->_localExec(TWGIT_EXEC . ' init 1.0.0 /tmp/origin');
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
        $sCmd = 'get_git_rev_parse stable; '
            . 'for key in "\${!REV_PARSE[@]}"; do printf "%s:%s" "\$key" "\${REV_PARSE[\$key]}"; echo; done';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertRegExp('/^stable:[0-9a-f]{40}$/', $sMsg);
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
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $sCmd = 'get_git_merged_branches origin/release-1.1.0; echo \${MERGED_BRANCHES[origin/release-1.1.0]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('origin/release-1.1.0 origin/stable', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithFailedFirstCall ()
    {
        $sCmd = 'get_git_merged_branches origin/release-1.1.0; ' . TWGIT_EXEC . ' release start -I 1>/dev/null 2>&1; '
            . 'get_git_merged_branches origin/release-1.1.0; echo \${MERGED_BRANCHES[origin/release-1.1.0]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('origin/release-1.1.0 origin/stable', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithFilledCache ()
    {
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $sCmd = 'get_git_merged_branches origin/release-1.1.0; ' . TWGIT_EXEC . ' release remove 1.1.0 1>/dev/null 2>&1; '
            . 'get_git_merged_branches origin/release-1.1.0; echo \${MERGED_BRANCHES[origin/release-1.1.0]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('origin/release-1.1.0 origin/stable', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithNewFeatureAndRelease ()
    {
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $sCmd = 'get_git_merged_branches origin/release-1.1.0; echo \${MERGED_BRANCHES[origin/release-1.1.0]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('origin/release-1.1.0 origin/stable', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_WithFeatureMergeIntoRelease ()
    {
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 1');
        $sCmd = 'get_git_merged_branches origin/release-1.1.0; echo \${MERGED_BRANCHES[origin/release-1.1.0]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('origin/feature-1 origin/release-1.1.0 origin/stable', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_With2InterdependentFeatures1 ()
    {
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $this->_localExec(TWGIT_EXEC . ' feature start 2');
        $this->_localExec('git merge feature-1');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 1');
        $sCmd = 'get_git_merged_branches origin/release-1.1.0; echo \${MERGED_BRANCHES[origin/release-1.1.0]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('origin/feature-1 origin/release-1.1.0 origin/stable', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merged_branches
     */
    public function testGetGitMergedBranches_With2InterdependentFeatures2 ()
    {
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $this->_localExec(TWGIT_EXEC . ' feature start 2');
        $this->_localExec('git merge feature-1');
        $this->_localExec(TWGIT_EXEC . ' feature merge-into-release 2');
        $sCmd = 'get_git_merged_branches origin/release-1.1.0; echo \${MERGED_BRANCHES[origin/release-1.1.0]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('origin/feature-1 origin/feature-2 origin/release-1.1.0 origin/stable', $sMsg);
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
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $sRev = $this->_localExec('git merge-base origin/release-1.1.0 origin/feature-1');
        $sCmd = 'r="origin/release-1.1.0"; get_git_rev_parse \$r; r_rev="\${REV_PARSE[\$r]}"; '
            . 'f="origin/feature-1"; get_git_rev_parse \$f; f_rev="\${REV_PARSE[\$f]}"; '
            . 'get_git_merge_base \$r \$f; echo \${MERGE_BASE[\$r|\$f]}';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals($sRev, $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::get_git_merge_base
     */
    public function testGetGitMergedBase_WithFilledCache ()
    {
        $this->_localExec(TWGIT_EXEC . ' release start -I');
        $this->_localExec(TWGIT_EXEC . ' feature start 1');
        $sRev = $this->_localExec('git merge-base origin/release-1.1.0 origin/feature-1');
        $sCmd = 'r="origin/release-1.1.0"; get_git_rev_parse \$r; r_rev="\${REV_PARSE[\$r]}"; '
            . 'f="origin/feature-1"; get_git_rev_parse \$f; f_rev="\${REV_PARSE[\$f]}"; '
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
            array($aFeatureTypes, '', array('', '', 'origin/feature-1', '', '')),
            array($aFeatureTypes, 'unknow-release', array('', '', 'origin/feature-1', '', '')),
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
            . TWGIT_EXEC . ' feature start 4; git commit --allow-empty -m "empty"; git push origin'
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
        list($f1, $f2, $f3, $f4) =
            array('origin/feature-1', 'origin/feature-2', 'origin/feature-3', 'origin/feature-4');

        return array(
            array($aFeatureTypes, '', array('', '', "$f1 $f2 $f3 $f4", '', '')),
            array($aFeatureTypes, 'unknow-release', array('', '', "$f1 $f2 $f3 $f4", '', '')),
            array($aFeatureTypes, 'release-1.1.0', array('', '', "$f2 $f3", $f1, $f4)),
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
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push origin; '
            . TWGIT_EXEC . ' feature merge-into-release 1'
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('origin/feature-2', 'origin/feature-1', '');
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
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push origin; '
            . TWGIT_EXEC . ' feature merge-into-release 1; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push origin; '
            . TWGIT_EXEC . ' feature start 3; git merge --no-ff feature-1; git push origin; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('origin/feature-2 origin/feature-3', '', 'origin/feature-1');
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
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push origin; '
            . TWGIT_EXEC . ' feature merge-into-release 1; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push origin; '
            . TWGIT_EXEC . ' feature start 3; git merge --no-ff feature-1; git push origin; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push origin; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('origin/feature-2 origin/feature-3', '', 'origin/feature-1');
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
            . TWGIT_EXEC . ' feature start 1; git merge release-1.1.0; git push origin'
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('origin/feature-1', '', '');
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
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push origin; '
            . TWGIT_EXEC . ' feature merge-into-release 2'
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', 'origin/feature-1 origin/feature-2', '');
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
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push origin; '
            . TWGIT_EXEC . ' feature merge-into-release 2; '
            . TWGIT_EXEC . ' feature start 2; git commit --allow-empty -m "empty"; git push origin; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', 'origin/feature-1', 'origin/feature-2');
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
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; git push origin; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push origin; '
            . TWGIT_EXEC . ' feature merge-into-release 2'
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', 'origin/feature-2', 'origin/feature-1');
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
     * @shcovers inc/common.inc.sh::get_features
     * @shcovers inc/common.inc.sh::get_merged_features
     */
    public function testGetFeatures_With2InterdependentFeatures7 ()
    {
        $this->_localExec(
            TWGIT_EXEC . ' release start -I; '
            . TWGIT_EXEC . ' feature start 1; '
            . TWGIT_EXEC . ' feature start 2; git merge --no-ff feature-1; '
            . TWGIT_EXEC . ' feature start 1; git commit --allow-empty -m "empty"; git push origin; '
            . TWGIT_EXEC . ' feature merge-into-release 2; '
            . TWGIT_EXEC . ' feature start 2; git commit --allow-empty -m "empty"; git push origin; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('', '', 'origin/feature-1 origin/feature-2');
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
        $aOut = array('origin/feature-1', '', '');
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
            . 'git commit --allow-empty -m "empty"; git push origin; '
        );

        $aMsg = array();
        $aFeatureTypes = array('free', 'merged', 'merged_in_progress');
        $aOut = array('origin/feature-1', '', '');
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
//         $this->assertEquals('origin/feature-1', $sMsg1);

//         $sCmd = "eval 'function get_git_merged_branches () { echo y;}'; "
//             . 'get_merged_features release-1.1.0; echo \$GET_MERGED_FEATURES_RETURN_VALUE';
//         $sMsg2 = $this->_localShellCodeCall($sCmd);
//         $this->assertEquals($sMsg2, $sMsg1);
//     }
}
