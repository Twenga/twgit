[![TwGit logo](https://github.com/Twenga/twgit/raw/stable/doc/logo-med.png)](http://twgit.twenga.com/) TwGit
==========

#### [Homepage](http://twgit.twenga.com/)

#### Continuous integration [![travis-ci.org](https://github.com/Twenga/twgit/raw/stable/doc/travis-favicon.png)](http://travis-ci.org/Twenga/twgit)&nbsp;[![Build Status](https://secure.travis-ci.org/Twenga/twgit.png?branch=stable)](http://travis-ci.org/Twenga/twgit)
To run the test suite, simply:

```bash
$ cp conf/twgit-dist.sh conf/twgit.sh          # and adapt, if necessary
$ cp conf/phpunit-dist.php conf/phpunit.php    # and adapt, if necessary
$ phpunit -c conf/phpunit-dist.xml
```

## Description
Twgit is a free and open source assisting tools for managing features, hotfixes and releases on Git repositories.
It provides simple, high-level commands to adopt the branching model describes in our documentation (see below).

This tools is largely inspired by [GitFlow](https://github.com/nvie/gitflow), but the workflow is different.

Feel free to contribute to it if you like.

## Requirements

  - Bash v4 _(2009)_ and above
  - Git v1.7.2 _(2010)_ and above
  - php5-cli or Python 2.x for Redmine and Github connectors (can be switched off): allow to display issue's title/subject into twgit
  - Supported operating systems: Debian/Ubuntu Linux, FreeBSD, Mac OS X

## Installing twgit
In the directory of your choice, e.g. `~/twgit`:

```bash
$ git clone git@github.com:Twenga/twgit.git .
$ sudo make install
```

More [Installation instructions](https://github.com/Twenga/twgit/wiki/Twgit#wiki-2.installation) are available in French wiki, waiting English translation...

## Getting started

![Getting started](https://github.com/Twenga/twgit/raw/stable/doc/getting-started.png)

## Documentation
[French documentation](https://github.com/Twenga/twgit/wiki) is available in wiki, waiting English translation...

### Help on command prompt

![twgit](https://github.com/Twenga/twgit/raw/stable/doc/screenshot-twgit.png)

![twgit feature](https://github.com/Twenga/twgit/raw/stable/doc/screenshot-twgit-feature.png)

![twgit hotfix](https://github.com/Twenga/twgit/raw/stable/doc/screenshot-twgit-hotfix.png)

![twgit release](https://github.com/Twenga/twgit/raw/stable/doc/screenshot-twgit-release.png)

![twgit demo](https://github.com/Twenga/twgit/raw/stable/doc/screenshot-twgit-demo.png)

![twgit tag](https://github.com/Twenga/twgit/raw/stable/doc/screenshot-twgit-tag.png)

## Copyrights & licensing
Licensed under the Apache License 2.0.
See [LICENSE](https://github.com/Twenga/twgit/blob/stable/LICENSE) file for details.

## ChangeLog
See [CHANGELOG](https://github.com/Twenga/twgit/blob/stable/CHANGELOG.md) file for details.
