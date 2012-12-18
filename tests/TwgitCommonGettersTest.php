<?php

/**
 * @package Tests
 * @author Geoffroy Aubry <geoffroy.aubry@hi-media.com>
 */
class TwgitCommonGettersTest extends TwgitTestCase
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
        $o->remove(TWGIT_REPOSITORY_SECOND_REMOTE_DIR);
        $o->mkdir(TWGIT_REPOSITORY_ORIGIN_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_LOCAL_DIR, '0777');
        $o->mkdir(TWGIT_REPOSITORY_SECOND_REMOTE_DIR, '0777');
    }

    /**
     * @dataProvider providerTestGetDissidentRemoteBranches
     * @shcovers inc/common.inc.sh::get_dissident_remote_branches
     */
    public function testGetDissidentRemoteBranches ($sLocalCmd, $sExpectedResult)
    {
        $this->_remoteExec('git init && git commit --allow-empty -m "-" && git checkout -b feature-currentOfNonBareRepo');
        $this->_localExec(TWGIT_EXEC . ' init 1.2.3 ' . TWGIT_REPOSITORY_ORIGIN_DIR);
        $this->_localExec('cd ' . TWGIT_REPOSITORY_SECOND_REMOTE_DIR . ' && git init');
        $this->_localExec('git remote add second ' . TWGIT_REPOSITORY_SECOND_REMOTE_DIR);

        $this->_localExec($sLocalCmd);
        $sMsg = $this->_localFunctionCall('get_dissident_remote_branches');
        $this->assertEquals($sExpectedResult, $sMsg);
    }

    public function providerTestGetDissidentRemoteBranches ()
    {
        return array(
            array(':', ''),
            array(
                'git checkout -b feature-X && git push origin feature-X'
                    . ' && git checkout -b release-X && git push origin release-X'
                    . ' && git checkout -b hotfix-X && git push origin hotfix-X'
                    . ' && git checkout -b demo-X && git push origin demo-X'
                    . ' && git checkout -b master && git push origin master'
                    . ' && git checkout -b outofprocess && git push origin outofprocess'
                    . ' && git remote set-head origin stable',
                'origin/outofprocess'
            ),
            array(
                'git checkout -b outofprocess && git push origin outofprocess && git push second outofprocess'
                    . ' && git checkout -b out2 && git push origin out2 && git push second out2',
                'origin/out2' . "\n" . 'origin/outofprocess'
            ),
        );
    }

    /**
     * @shcovers inc/common.inc.sh::getFeatureSubject
     */
    public function testGetFeatureSubject_WithNoParameter ()
    {
        $sCmd = 'TWGIT_FEATURES_SUBJECT_PATH="$(tempfile -d ' . TWGIT_TMP_DIR . ')"; '
              . 'echo \'2;The subject of 2\' > \$TWGIT_FEATURES_SUBJECT_PATH; '
              . 'config_file=\'F\'; TWGIT_FEATURE_SUBJECT_CONNECTOR=\'github\'; '
              . 'getFeatureSubject; '
              . 'rm -f "\$TWGIT_FEATURES_SUBJECT_PATH"';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::getFeatureSubject
     */
    public function testGetFeatureSubject_WithParameterButNoSubjectNorConnector ()
    {
        $sCmd = 'TWGIT_FEATURES_SUBJECT_PATH="$(tempfile -d ' . TWGIT_TMP_DIR . ')"; '
              . 'config_file=\'F\'; TWGIT_FEATURE_SUBJECT_CONNECTOR=\'no_connector\'; '
              . 'getFeatureSubject 2; '
              . 'rm -f "\$TWGIT_FEATURES_SUBJECT_PATH"';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEmpty($sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::getFeatureSubject
     */
    public function testGetFeatureSubject_WithParameterAndSubject ()
    {
        $sCmd = 'TWGIT_FEATURES_SUBJECT_PATH="$(tempfile -d ' . TWGIT_TMP_DIR . ')"; '
              . 'echo \'2;The subject of 2\' > \$TWGIT_FEATURES_SUBJECT_PATH; '
              . 'config_file=\'F\'; TWGIT_FEATURE_SUBJECT_CONNECTOR=\'no_connector\'; '
              . 'getFeatureSubject 2; '
              . 'rm -f "\$TWGIT_FEATURES_SUBJECT_PATH"';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('The subject of 2', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::getFeatureSubject
     */
//     public function testGetFeatureSubject_WithParameterAndConnector ()
//     {
//         $sCmd = 'TWGIT_FEATURES_SUBJECT_PATH="$(tempfile -d ' . TWGIT_TMP_DIR . ')"; '
//               . 'config_file=\'F\'; TWGIT_FEATURE_SUBJECT_CONNECTOR=\'github\'; '
//               . 'getFeatureSubject 2; '
//               . 'rm -f "\$TWGIT_FEATURES_SUBJECT_PATH"';
//         $sMsg = $this->_localShellCodeCall($sCmd);
//         $this->assertEquals('email when too old features', $sMsg);
//     }
// => Pb with API rate limit: http://developer.github.com/v3/#rate-limiting

    /**
     * @shcovers inc/common.inc.sh::displayFeatureSubject
     */
    public function testDisplayFeatureSubject_WithKnownFeature ()
    {
        $sCmd = 'function getFeatureSubject() { echo "XYZ-\$1";}; '
              . 'displayFeatureSubject 2';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('XYZ-2', $sMsg);
    }

    /**
     * @shcovers inc/common.inc.sh::displayFeatureSubject
     */
    public function testDisplayFeatureSubject_WithUnknownFeature ()
    {
        $sCmd = 'function getFeatureSubject() { echo ;}; '
              . 'displayFeatureSubject 2 \"default subject\"';
        $sMsg = $this->_localShellCodeCall($sCmd);
        $this->assertEquals('default subject', $sMsg);
    }
}
