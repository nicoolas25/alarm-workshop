## Setup

### PHP

I assume you installed a version of PHP on your system. If you have one,
you should be able to run: `php -v`. On my end it returns:

```
PHP 7.4.3 (cli) (built: May 26 2020 12:24:22) ( NTS )
Copyright (c) The PHP Group
Zend Engine v3.4.0, Copyright (c) Zend Technologies
    with Zend OPcache v7.4.3, Copyright (c), by Zend Technologies
```

To get there I installed the package `php7.4-cli` from my package manager.
I was on an Ubuntu-like Linux distribution. Chances are that you already
have PHP installed.

### Composer

It is entirely possible that you already have composer on your machine.
If you do, running `composer -V` should return you something like:

```
Composer version 1.10.10 2020-08-03 11:35:19
```

If that's not the case, you can build yourself your own version of composer
just for this project by running the following command:

```
php setup/composer-setup.php --install-dir=bin --filename=composer
```

If you installed composer this way, you'll have to call `bin/composer` or
temporarily add the `./bin` directory to you path.

### PHP packages

Install the required packages with: `composer install`.
This should create and fill a `./vendor` directory.

### PHP config

The tests rely on `assert` to raise errors. It need to be configured in a way
that the code is executed and when the assertion fails and error is thrown.

In my case, I needed to update the `php.ini` config file in: `/etc/php/7.4/cli/php.ini`
in order to make sure the [configuration][assert-config] matched:

* `zend.assertions = 1`
* `assert.exception	= On`

## Running the tests

The following command should run the tests:

```
vendor/bin/peridot alarm.spec.php
```

Here we use the [peridot][peridot] PHP package to write and execute our tests.


[peridot]: https://peridot-php.github.io/
[assert-config]: https://www.php.net/manual/en/function.assert.php
