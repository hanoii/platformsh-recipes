# Platform.sh recipes

A collection of scripts, commands, recipes and notes for platform.sh

<!-- toc -->

- [ddev](#ddev)
- [Platform.sh setup](#platformsh-setup)
  * [`.platform.app.yaml` tweaks](#platformappyaml-tweaks)
  * [Build](#build)
  * [Tools](#tools)
  * [`.environment`](#environment)
  * [`.bashrc`](#bashrc)
- [Performance troubleshooting](#performance-troubleshooting)
  * [Automatic ipblocking](#automatic-ipblocking)
  * [ahoy commands](#ahoy-commands)
  * [Time/memory used](#timememory-used)
  * [404s](#404s)
  * [User-Agents](#user-agents)
  * [IP addresses](#ip-addresses)
  * [URIs and Paths](#uris-and-paths)
  * [HTTP status filter](#http-status-filter)
  * [RPMs](#rpms)
    + [php.access.log](#phpaccesslog)
    + [access.log](#accesslog)

<!-- tocstop -->

## ddev

This is also a ddev add-on that you can install with:

```sh
ddev get https://github.com/hanoii/platformsh-recipes/tarball/main
```

It installs most of the locally necesary scripts to run against platform.

## Platform.sh setup

### `.platform.app.yaml` tweaks

For the php logs commands, we need to alter php.access.log format so that in
includes more data, to do that add/amend the following on your
`.platform.app.yml`:

```yml
web:
  commands:
    pre_start: $PLATFORMSH_RECIPES_INSTALLDIR/platformsh-recipes/assets/platformsh/php-pre-start.sh
    start: /usr/bin/start-php-app -y "$PLATFORM_APP_DIR/.deploy/php-fpm.conf"
```

And the following to your mounts

```yml
mounts:
  "/.deploy":
    source: local
    source_path: "deploy"
```

You also need to configure the `PLATFORMSH_RECIPES_VERSION` on the variables
section:

```yml
variables:
  ...
  PLATFORMSH_RECIPES_VERSION: 6be82fe

```

The version is the SHA1 commit hash you wish to install. It can be of any
length.

### Build

First of all, you should get the files on this repo onto a platform.sh
container.

To do so, you can add the following to your build hook (**please provide the
commit sha of the repo for `PLATFORMSH_RECIPES_VERSION`**) :

```yml
hooks:
  build: |
    source /dev/stdin  <<< "$(curl -fsSL "https://raw.githubusercontent.com/hanoii/platformsh-recipes/${PLATFORMSH_RECIPES_VERSION}/installer.sh")"
```

If you wish to automatically install and setup most of what this repo provides,
you can append `-f` to the `installer.sh` script above:

```yml
hooks:
  build: |
    source /dev/stdin  <<< "$(curl -fsSL "https://raw.githubusercontent.com/hanoii/platformsh-recipes/${PLATFORMSH_RECIPES_VERSION}/installer.sh")" -f
```

### Tools

There are different tools that I usually add to platform, some of them are
required by the commands referenced below.

If you haven't used the `-f` version of the installer, you can take what you
want from [this repo's build.sh](platformsh-recipes/assets/platformsh/build.sh).

### `.environment`

Some of this tools also needs additions to [Platform.sh's .environment
file][platformsh-environment]. If you haven't used the `-f` version of the
installer, you can take what you want from
[this repo's .environment](platformsh-recipes/assets/platformsh/.environment).

[platformsh-environment]:
  https://docs.platform.sh/development/variables/set-variables.html#testing-environment-scripts

### `.bashrc`

Finally, it also requires things to be added to a project's own .bashrc. If you
haven't used the `-f` version of the installer, you can take what you want from
[this repo's .bashrc](platformsh-recipes/assets/platformsh/.bashrc).

## Performance troubleshooting

The commands here can also be used to test and access platform projects locally,
to do that you need to make available the following environment variables:

- `PLATFORMSH_CLI_TOKEN`
- `PLATFORM_PROJECT`
- `PLATFORMSH_RECIPES_MAIN_BRANCH=main` (optional, defaults to `master`)

### Automatic ipblocking

This ships with a [script](platformsh-recipes/scripts/logs/ipblock.sh) that can
be configured to search for certain patterns on the access.log and, if run
within platform, it will automatically block what it consideres an IP with a bad
behavior.

With ahoy, you can run it with `ahoy log:ipblock`

> [!TIP]
>
> The script can be run from a platform environment in which it will
> automatically block the IPs or from ddev if this is added as an addon in which
> it will do the same chack but only giving you the platform command to run from
> ddev instead of doing it automatically.

As an exampe and a starting point, this is a real configuration that is in use:

<!-- prettier-ignore -->
```yml
    env:
        # Both blacklist and whitelist are Perl regex patterns used in the 
        # automatic IP blocking process.
        # The whitelist patterns are filtered out first before, and then the
        # blacklist patterns are used to find missbehaving IPs
        # i.e. wp-content in a path is blacklisted, but wp-content/uploads is
        # whitelisted allowing wp-content/uploads to be OK but any other
        # wp-content/* to be considerd bad
        PLATFORMSH_RECIPES_IPBLOCK_BLACKLIST: 'select[^a-zA-Z0-9_\-\/\s]|\.env|sysgmdate(\(|%28)|wp-content|wp-admin|go-http-client|(?<!/index)\.php|\.jsp HTTP|\.html HTTP'
        PLATFORMSH_RECIPES_IPBLOCK_WHITELIST: 'wp-content/plugins/download-manager/assets/file-type-icons/_blank.png|wp-content/uploads'
```

And I have an accompanying cron entry:

<!-- prettier-ignore -->
```yml
    ipblock:
        spec: 'H/5 * * * *'
        commands:
            start: |
                if [ "$PLATFORM_ENVIRONMENT_TYPE" = "production" ]; then
                    ahoy log:ipblock
                fi
```

The two configurations entries are case insensitive regex patterns. Different
patterns can be OR'ed as per the Perl Regular Expression syntax, which are used
by `grep -P`.

- `PLATFORMSH_RECIPES_IPBLOCK_WHITELIST`: The pattern that will be used to
  filter out any entry that maches the pattern.
- `PLATFORMSH_RECIPES_IPBLOCK_BLACKLIST`: The pattern that will be used to get
  the IPs that matches the pattern.

The whitelist is run first, so you can use the whitelist to make sure that
certain patterns that would otherwise be blocked by the blacklist pattern are
excluded from it.

In the example above, for example, `wp-content` is looked for blocking IPs, but
with the configured whitelist, both
`wp-content/plugins/download-manager/assets/file-type-icons/_blank.png` and
`wp-content/uploads` are considered valid requests and excluded before looking
for the blocklist pattern.

### ahoy commands

All of the ahoy commands below have the following flags

- `--days=N`, display logs of N days ago.
- `--all`, display logs without filtering by date
- `--404`, show only 404s
- `--not-404`, exclude 404s
- `--raw`, will show the output of the log as is, it should be used last after
  any other flag.

Some comamnds have extra arguments that are noted below.

While these commands are meant to be run from within the platform environment,
they also work from ddev why prepending `platform` to every command.

i.e. `ahoy log:php:top` will work on a platform environment and
`ahoy platform log:php:top` will work on ddev and it will always query the
production environment.

### Time/memory used

Here there are some notes documented as well as usefull commands that can
continue to be used for monitoring the server.

The following command can be used to list entries of the current day of the php
access log sorted by time spent.

```
ahoy log:php:top
```

The same approach lists entries of the php access log sorted by memory spent. It
also shows the time and the date.

```
ahoy log:php:top --mem
```

### 404s

404s, as they are normally routed through Drupal, are unecessarilly heavy on
performance, and was quite a bit.

- I installed the [fast_404][fast_404] module with some sensible settings
  enabled on [settings.php](settings/settings.php). This can be further tweaks
  but I think this should be OK for now.
- The above, still goes through quite a bit of php processing, so for those 404
  that were considerably higher for the rest, I implemented them on
  [.platform.app.yaml](.platform.app.yaml). These gives a 404 on the platform's
  edge, never reaching PHP. This can continue to be monitored and add to this
  list as necessary.
- Because the rules on `.platform.app.yaml` doesn't work on query strings, I
  also added some early blocking in [settings.php][settings-php-block].

[fast_404]: https://www.drupal.org/project/fast_404
[settings-php-block]:
  https://gitlab.com/confcats/catalyze/-/blob/master/settings/settings.php#L7-24

One curious snippet is:

```yaml
# Avoid passthru on any php file but /index.php
# This throws a platform 404, this is to avoid odd
# bots attacks against php taking up resources
'^/[^i].*\.php$':
  passthru: false
  scripts: false
'^/i[^n]*\.php$':
  passthru: false
  scripts: false
'^/in[^d]*\.php$':
  passthru: false
  scripts: false
'^/ind[^e]*\.php$':
  passthru: false
  scripts: false
'^/inde[^x]*\.php$':
  passthru: false
  scripts: false
```

Which is a poorman's way of doing a lookbehind, it basically means it blocks any
php script except for `index.php`.

In further tests, I found a way to do the lookbehind properly using regex with
(leaving the above as a reference just in case):

```yaml
# Avoid passthru on any php file but /index.php
'(?<!^/index)\.php$':
  passthru: false
  scripts: false
```

Running the following on a platform environment will list all php 404s:

```
ahoy log:php --404
```

Another addition was to check for file extensions that were hitting 404 as those
were also causing unnecessary hits to php.

```
ahoy log:php --404 --extension
```

For some of the above I wanted to see what kind of files were accessed:

i.e. showing all `.htm` files that were giving 404

```
ahoy log:php --404 --extension=htm
```

### User-Agents

Another thing that I looked for was user agents, the following command groups
them:

```
ahoy log:access --ua
```

This can help assess if all bot traffic is legit, useful, and block them either
on robots.txt and then check if they respected it or by a similar technique of
the settings.php file above if needed.

In particular, if a lot of 404s are coming from the bots, we should probably try
to avoid them either blocking the bot or some of the techniques explained above.

The same command can be used but also filtering by 404 or not 404:

```
ahoy log:access --ua --404
ahoy log:access --ua --not-404
```

Youu can also filter for a specific case insensitive string on the UA:

```
ahoy log:access --ua=amazon
```

### IP addresses

You can filter out accesses by IP, that can be then combined with the above to
gather more information.

```
ahoy log:access --ip
ahoy log:access --ip --404
ahoy log:access --ip --not-404
```

If you want to see more details about what was accessed by a single ip:

```
ahoy log:access --ip=w.x.y.z
```

### URIs and Paths

You can also group by URI and or path, using `--uri`, `--uri=/something`,
`--path` and `--path=/something`. The difference between the two is that uri is
the path excludes the query string.

i.e.

```
ahoy log:access --uri
ahoy log:access --uri=/presentation-library
ahoy log:access --path
ahoy log:access --path=/presentation-library

```

As with most commands, some of the flags can be combined, knowing that the order
of the flags is important.

### HTTP status filter

You can add `--status=HTTP_STATUS` to any of the `ahoy log:access` command
explained above.

i.e.: `ahoy log:access --uri --status=400`

### RPMs

Another flavour of commands is to show RPMs, both from the PHP side of things as
the accesslog side of things:

All of the commands below accepts these additional flags:

- `--per-hours` shows RPHs (requests per hours) of the current day
- `--per-hours --days=N` same as above going back N days

#### php.access.log

- `ahoy log:php:rpm` shows RPMs of the last 3 hours
- `ahoy log:php:rpm --ip=IP` filter by IP
- `ahoy log:php:rpm --ua=UA` filter by UA

#### access.log

- `ahoy log:access:rpm` shows RPMs of the last 3 hours
- `ahoy log:access:rpm --ip=IP` filter by IP
- `ahoy log:access:rpm --ua=UA` filter by UA
