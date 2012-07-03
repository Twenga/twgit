ChangeLog
=========

## Version 1.8.0 (2012-07-03)

Features:

  - #54: Allow to define colors and decorations from config file
  - #53: Make twgit compatible with Mac OS X
  - #50: Display features included in a tag: shows features merged into the release when the tag was created.

Fixes:

  - #52: Bad option for grep in `assert_git_repository()` (thanks to #jaysus)

Unit tests:

  - estimated code coverage: 25%

Quality code:

  - #13: Risk of name collision with functions of ui.inc.sh library

## Version 1.7.0 (2012-04-29)

Features:

  - #48: Enhance update procedure: display news of CHANGELOG, Bash autocompletion update, and evolution of config file.
  - #18: Fetch title of Redmine (sub)project for (sub)project feature

Other:

  - #45: Change license to Apache 2.0

Doc:

  - #47: Contextual help for twgit init need more precision on tag format
  - #46: Fix "Getting started" graph

Fixes:

  - #49: Two init commit nodes are created when starting a new feature

## Version 1.6.0 (2012-04-02)

Features:

  - #41: Add subject in commit messages of `twgit feature start` when a connector (github, redmine) is setted.
**Must update** `TWGIT_FIRST_COMMIT_MSG` parameter of `conf/twgit.sh`:

```bash
TWGIT_FIRST_COMMIT_MSG="${TWGIT_PREFIX_COMMIT_MSG}Init %s '%s'%s."
```

  - #40: Make scripts more secure if a bad branch is created with the same name of a tag.
  - #38: Add `twgit feature status [<featurename>]`
  - #37: Check not exists branches with same name as tag

Unit tests:

  - #34: Add unit tests on `get_features()` and other similar functions
  - estimated code coverage: 22%

Doc:

  - #42: Add some doc to README: Getting started, help on command prompt, ...

Fixes:

  - #44: Installer creates conf/twgit.sh with root permissions
  - #43: Help on command prompt is not accessible if not in a git repository
  - #39: Error message when twgit release reset: `/!\ Tag 'vx.y.z' already exists!`

## Version 1.5.1 (2012-03-05)

Fixes:

  - #33: auto-update remove 755 on twgit

## Version 1.5.0 (2012-03-04)

Features:

  - #31: Simplify installation

## Version 1.4.0 (2012-03-03)

Features:

  - #30: Add a connector displaying subject of Github features
  - #26: Check local repository has a remote repository
  - #11: Allow custom config files
  - #1: Add command: twgit init

Unit tests:

  - #25: Compute estimated Bash code coverage in Travis-ci
  - Estimated code coverage: 16%

Quality code:

  - #24: Now Redmine PHP code uses main config file
  - #19: Reduce coupling with Redmine

Fixes:

  - #27: Main help finish with an error code not null

## Version 1.3.0 (2012-02-24)

Fixes:

  - #21: Bad twgit version displayed in about section.

Doc:

  - #22: Add a CHANGELOG.MD
  - #8: Missing description in README.MD

Unit tests:

  - #23: Add a first unit test using Travis-ci.org
  - estimated code coverage: 4%

## Version 1.2.0 (2012-02-13)

Doc:

  - #20: Upload french documentation waiting english translation

## Version 1.1.0 (2012-01-31)

Features:

  - #5: Update `autoupdate()` to observe tags on stable branch

UI:

  - #7: Add twgit version to about screen

## Version 1.0.0 (2012-01-11)

First release on Github.
