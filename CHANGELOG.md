ChangeLog
=========

## Version 1.19.0 (2017-02-27)

Features:

  - [#169](https://github.com/Twenga/twgit/pull/169): Add feature start from release and improve bash completion.

## Version 1.18.0 (2017-01-30)

Features:

  - [#168](https://github.com/Twenga/twgit/pull/168): New feature or demo starting from a demo.
  - [#166](https://github.com/Twenga/twgit/pull/166): Improve copy/paste of git command to apply last tag in current branch.

## Version 1.17.1 (2016-03-01)

Features:

  - [#165](https://github.com/Twenga/twgit/pull/165): When twgit ask for confirmation, it is unclear if the default is yes or no.

## Version 1.17.0 (2015-12-29)

Features:

  - [#159](https://github.com/Twenga/twgit/pull/159): Add release merge-demo, demo merge-demo, and demo update-features.

Fixes:

  - [#161](https://github.com/Twenga/twgit/pull/161): Fix Gitlab project_addr.

## Version 1.16.0 (2015-01-12)

Features:

  - [#155](https://github.com/Twenga/twgit/pull/155): Add a more verbose code coverage.
  - [#153](https://github.com/Twenga/twgit/issues/153): Add Trello connector.

## Version 1.15.3 (2014-12-06)

Fixes:

  - [#154](https://github.com/Twenga/twgit/pull/154):
    Fixed an issue with feature migrate task when local repository has multiple remotes.

## Version 1.15.2 (2014-11-13)

Fixes:

  - [#151](https://github.com/Twenga/twgit/pull/151): Fix hard coded URL when using Python in Gitlab connector.

## Version 1.15.1 (2014-09-22)

Fixes:

  - Fix changelog

## Version 1.15.0 (2014-09-20)

Features:

  - [#146](https://github.com/Twenga/twgit/issues/146): Use curl as failover of wget for connectors
  - [#145](https://github.com/Twenga/twgit/pull/145): Add gitlab connector
  - [#125](https://github.com/Twenga/twgit/issues/125): Add command `twgit feature merge-into-hotfix`

## Version 1.14.3 (2014-07-30)

Fixes:
  - [#141](https://github.com/Twenga/twgit/issues/141): Fix user home detection

## Version 1.14.2 (2014-04-10)

Fixes:

  - Bad detection of release initial author if one of its features is older.
  - Python version of Jira connector doesn't handle unicode characters.

## Version 1.14.1 (2014-04-04)

Fixes:

  - Remaining code in installation process for testing purpose only.

## Version 1.14.0 (2014-04-02)

Features:

  - [#129](https://github.com/Twenga/twgit/issues/129): Add Jira connector.
  - [#127](https://github.com/Twenga/twgit/issues/127): Support for zsh in addition to bash.
  - [#118](https://github.com/Twenga/twgit/issues/118): `$Id$` tag substitution à la SVN: replace all tags `$Id$` and `$Id:X.Y.Z$`
    found in files specified by `TWGIT_VERSION_INFO_PATH` by the next version
    on `twgit init`, `twgit release start`, and `twgit hotfix start` commands.
  - [#117](https://github.com/Twenga/twgit/issues/117): Detect words in disorder: `twgit featuer lsit` will work.
  - [#85](https://github.com/Twenga/twgit/issues/85): Alert on `twgit hotfix start` or `twgit release start`
    when current user is different from creator.

Unit tests:

  - estimated code coverage: 34% (710 of 2112 lines).

## Version 1.13.0 (2013-10-21)

Features:

  - [#114](https://github.com/Twenga/twgit/issues/114): Making twgit ignoring all `feature-`, `demo-`, `hotfix-`,
    `release-` and tag prefixes on command launch.
    For example: `twgit feature start feature-1` will no longer generate an error.
  - [#113](https://github.com/Twenga/twgit/issues/113): Allow partial color overloading between config files:
    `twgit/conf/twgit-dist.sh`, `twgit/conf/twgit.sh` and repository's `.twgit`.
  - [#109](https://github.com/Twenga/twgit/issues/109): Now current branch is highlighted with an asterisk
    during both feature and demo list.
  - [#105](https://github.com/Twenga/twgit/issues/105): Add command `twgit <branch-type> push`.
    For example, `twgit feature push` is a shortcut for: `git push $TWGIT_ORIGIN <current-feature>`.
  - [#98](https://github.com/Twenga/twgit/issues/98): Add more messages to help to merge last tag on feature.

Fixes:

  - [#112](https://github.com/Twenga/twgit/issues/112): Now always sort features and demos in reverse numerical order.
  - [#110](https://github.com/Twenga/twgit/issues/110): Found static references to `stable` branch and `origin`
    repository in code, bypassing `TWGIT_ORIGIN` and `TWGIT_STABLE` parameters.

Core enhancements:

  - [#115](https://github.com/Twenga/twgit/issues/115): Remove `.twgit` configuration file —for github— from repository.

Doc:

  - [#108](https://github.com/Twenga/twgit/issues/108): Insert links to issues in `CHANGELOG.md`.

Unit tests:

  - [#111](https://github.com/Twenga/twgit/issues/111): Now tests ensure that code uses `TWGIT_ORIGIN` and `TWGIT_STABLE`.
  - estimated code coverage: 33% (653 of 1978 lines).

## Version 1.12.0 (2013-06-23)

Features:

  - [#100](https://github.com/Twenga/twgit/issues/100): Add command `twgit demo status` to know if we are up to date with the remote branch.

Fixes:

  - [#102](https://github.com/Twenga/twgit/issues/102): Add `--no-color` option to all `git branch` commands to fix
    the problem with colored git when `color.ui=always` is set in git config.

Core enhancements:

  - [#107](https://github.com/Twenga/twgit/issues/107): Now have a cache file of feature's subject per repository
    and remove `.features_subject` central file from install directory ⇒ new parameter in `conf/twgit.sh`:

    ```bash
    TWGIT_FEATURES_SUBJECT_FILENAME='.twgit_features_subject'
    ```

  - [#97](https://github.com/Twenga/twgit/issues/97): Add a `.twgit` configuration file for github.

Unit tests:

  - estimated code coverage: 34% (642 of 1891 lines).

## Version 1.11.0 (2013-03-04)

Features:

  - [#92](https://github.com/Twenga/twgit/issues/92): Add parameter in config file to control tag list size
  - [#88](https://github.com/Twenga/twgit/issues/88): Allow config files per repository
  - [#71](https://github.com/Twenga/twgit/issues/71): Add demo/test branches for marketing teams or other needs

UI:

  - [#90](https://github.com/Twenga/twgit/issues/90): Add source tag on branch description
  - [#89](https://github.com/Twenga/twgit/issues/89): Add commit description of hotfixes on `twgit tag list`
  - [#84](https://github.com/Twenga/twgit/issues/84): Allow to parameter the default rendering of `twgit feature list`

Core enhancements:

  - [#74](https://github.com/Twenga/twgit/issues/74): Update of twgit cancels the first called functionality

Unit tests:

  - estimated code coverage: 34% (618 of 1797 lines)

## Version 1.10.2 (2013-01-07)

Fixes:

  - [#83](https://github.com/Twenga/twgit/issues/83): Fix Interrupted system call from time to time in `inc/common.inc::get_dissident_remote_branches()`

## Version 1.10.1 (2012-12-28)

Fixes:

  - Python version of Github connector doesn't handle unicode characters

## Version 1.10.0 (2012-12-18)

Features:

  - [#82](https://github.com/Twenga/twgit/issues/82): `twgit feature show-modified-files` is renamed `twgit feature what-changed` and now handles opened as well as closed features.
    Display initial commit and final commit if exists. List created, modified and deleted files in the specified feature branch since its creation.
    If no <featurename> is specified, then use current feature.

Fixes:

  - [#63](https://github.com/Twenga/twgit/issues/63): Bug when `twgit feature merge-into-release` and release not yet fetched
  - [#17](https://github.com/Twenga/twgit/issues/17): Remove release fails if release name is not tag-compatible. Now `twgit release start <releasename>` must use major.minor.revision

UI:

  - [#80](https://github.com/Twenga/twgit/issues/80): Tip displayed when `release finish` is blocked by tag's hotfix is now more helpful

Core enhancements:

  - [#81](https://github.com/Twenga/twgit/issues/81): Bash redirection with process substitution causes problem on VM (2nd)
  - [#78](https://github.com/Twenga/twgit/issues/78): `grep -P` doesn't work with Mac OS Mountain Lion...
  - [#73](https://github.com/Twenga/twgit/issues/73): Listing of comitters not enough robust: if configuration variable `TWGIT_EMAIL_DOMAIN_NAME` is not defined, then `twgit feature comitters <feature>` display a wrong result.
  - [#68](https://github.com/Twenga/twgit/issues/68): Check wget is installed if connectors (Redmine, Github) are activated

Unit tests:

  - [#79](https://github.com/Twenga/twgit/issues/79): Unit tests are now executable on OS X
  - estimated code coverage: 34% (575 of 1698 lines)

## Version 1.9.1 (2012-11-12)

Fixes:

  - [#75](https://github.com/Twenga/twgit/issues/75): Python version of Redmine connector doesn't handle unicode characters

Doc:

  - Add logo and homepage link to README.md

## Version 1.9.0 (2012-11-05)

Core enhancements:

  - [#60](https://github.com/Twenga/twgit/issues/60): Prevent abusive commit into stable branch
  - [#59](https://github.com/Twenga/twgit/issues/59): Allow to choose between http:// and https:// for Redmine URL
  - [#58](https://github.com/Twenga/twgit/issues/58): Add Python implementation of Github and Redmine connectors
  - [#57](https://github.com/Twenga/twgit/issues/57): Slowdowns due to highlighting of text

Fixes:

  - [#61](https://github.com/Twenga/twgit/issues/61): Abusive branches out of process

Unit tests:

  - estimated code coverage: 29% (471 of 1629 lines)

## Version 1.8.0 (2012-07-03)

Note:

  - Due to update system's enhancement, the following message will appear during update. ***Ignore it***:

    ```bash
    /!\ New autocompletion update system request you execute just once this line (to adapt):
        sudo rm /etc/bash_completion.d/twgit && sudo ln -s ~/twgit/install/.bash_completion /etc/bash_completion.d/twgit && source ~/.bashrc
    ```

Features:

  - [#54](https://github.com/Twenga/twgit/issues/54): Allow to define colors and decorations from config file
  - [#53](https://github.com/Twenga/twgit/issues/53): Make twgit compatible with Mac OS X
  - [#50](https://github.com/Twenga/twgit/issues/50): Display features included in a tag: shows features merged into the release when the tag was created. Add `twgit tag list [<tagname>] [-F]`.

Fixes:

  - [#52](https://github.com/Twenga/twgit/issues/52): Bad option for grep in `assert_git_repository()` (thanks to Jérémie Havret)

Core enhancements:

  - [#56](https://github.com/Twenga/twgit/issues/56): bash redirection with process substitution causes problem on VM
  - [#55](https://github.com/Twenga/twgit/issues/55): Adapt github connector to Github API v3

Unit tests:

  - estimated code coverage: 25% (401 of 1610 lines)

Quality code:

  - [#13](https://github.com/Twenga/twgit/issues/13): Risk of name collision with functions of ui.inc.sh library

## Version 1.7.0 (2012-04-29)

Features:

  - [#48](https://github.com/Twenga/twgit/issues/48): Enhance update procedure: display news of CHANGELOG, Bash autocompletion update, and evolution of config file.
  - [#18](https://github.com/Twenga/twgit/issues/18): Fetch title of Redmine (sub)project for (sub)project feature

Fixes:

  - [#49](https://github.com/Twenga/twgit/issues/49): Two init commit nodes are created when starting a new feature

Doc:

  - [#47](https://github.com/Twenga/twgit/issues/47): Contextual help for twgit init need more precision on tag format
  - [#46](https://github.com/Twenga/twgit/issues/46): Fix "Getting started" graph

Core enhancements:

  - [#45](https://github.com/Twenga/twgit/issues/45): Change license to Apache 2.0

## Version 1.6.0 (2012-04-02)

Features:

  - [#41](https://github.com/Twenga/twgit/issues/41): Add subject in commit messages of `twgit feature start` when a connector (github, redmine) is set.
**Must update** `TWGIT_FIRST_COMMIT_MSG` parameter of `conf/twgit.sh`:

    ```bash
    TWGIT_FIRST_COMMIT_MSG="${TWGIT_PREFIX_COMMIT_MSG}Init %s '%s'%s."
    ```

  - [#38](https://github.com/Twenga/twgit/issues/38): Add `twgit feature status [<featurename>]`

Fixes:

  - [#44](https://github.com/Twenga/twgit/issues/44): Installer creates conf/twgit.sh with root permissions
  - [#43](https://github.com/Twenga/twgit/issues/43): Help on command prompt is not accessible if not in a git repository
  - [#39](https://github.com/Twenga/twgit/issues/39): Error message when twgit release reset: `/!\ Tag 'vx.y.z' already exists!`

Doc:

  - [#42](https://github.com/Twenga/twgit/issues/42): Add some doc to README: Getting started, help on command prompt, ...

Core enhancements:

  - [#40](https://github.com/Twenga/twgit/issues/40): Make scripts more secure if a bad branch is created with the same name of a tag.
  - [#37](https://github.com/Twenga/twgit/issues/37): Check not exists branches with same name as tag

Unit tests:

  - [#34](https://github.com/Twenga/twgit/issues/34): Add unit tests on `get_features()` and other similar functions
  - estimated code coverage: 22% (327 of 1465 lines)

## Version 1.5.1 (2012-03-05)

Fixes:

  - [#33](https://github.com/Twenga/twgit/issues/33): auto-update remove 755 on twgit

## Version 1.5.0 (2012-03-04)

Features:

  - [#31](https://github.com/Twenga/twgit/issues/31): Simplify installation

## Version 1.4.0 (2012-03-03)

Features:

  - [#30](https://github.com/Twenga/twgit/issues/30): Add a connector displaying subject of Github features
  - [#11](https://github.com/Twenga/twgit/issues/11): Allow custom config files
  - [#1](https://github.com/Twenga/twgit/issues/1): Add command: twgit init

Fixes:

  - [#27](https://github.com/Twenga/twgit/issues/27): Main help finish with an error code not null

Core enhancements:

  - [#26](https://github.com/Twenga/twgit/issues/26): Check that local repository has a remote repository

Unit tests:

  - [#25](https://github.com/Twenga/twgit/issues/25): Compute estimated Bash code coverage in Travis-ci
  - Estimated code coverage: 16% (231 of 1400 lines)

Quality code:

  - [#24](https://github.com/Twenga/twgit/issues/24): Now Redmine PHP code uses main config file
  - [#19](https://github.com/Twenga/twgit/issues/19): Reduce coupling with Redmine

## Version 1.3.0 (2012-02-24)

Fixes:

  - [#21](https://github.com/Twenga/twgit/issues/21): Bad twgit version displayed in about section.

Doc:

  - [#22](https://github.com/Twenga/twgit/issues/22): Add a CHANGELOG.MD
  - [#8](https://github.com/Twenga/twgit/issues/8): Missing description in README.MD

Unit tests:

  - [#23](https://github.com/Twenga/twgit/issues/23): Add a first unit test using Travis-ci.org
  - estimated code coverage: 4%

## Version 1.2.0 (2012-02-13)

Doc:

  - [#20](https://github.com/Twenga/twgit/issues/20): Upload french documentation waiting english translation

## Version 1.1.0 (2012-01-31)

UI:

  - [#7](https://github.com/Twenga/twgit/issues/7): Add twgit version to about screen

Core enhancements:

  - [#5](https://github.com/Twenga/twgit/issues/5): Update `autoupdate()` to observe tags on stable branch

## Version 1.0.0 (2012-01-11)

First release on Github.
