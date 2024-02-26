# Platform.sh recipes

A collection of scripts, commands, recipes and notes for platform.sh

<!-- toc -->

- [Platform.sh setup](#platformsh-setup)
  * [Tools](#tools)
- [Performance troubleshooting](#performance-troubleshooting)
  * [ahoy commans](#ahoy-commans)
  * [Time/memory used](#timememory-used)
  * [404s](#404s)
  * [User-Agents](#user-agents)
  * [IP addresses](#ip-addresses)
  * [RPMs](#rpms)
    + [php.access.log](#phpaccesslog)
    + [access.log](#accesslog)

<!-- tocstop -->

## Platform.sh setup

The following needs you to get the scripts and any other necessary bits on your
app on platform.sh, to do that you can add something like the following to your
build hook:

**Notes**:

- update `COMMIT-SHA1` with the commit you want to pull.
- Review the `cp` lines below and adapt as necessary to fit your projects,
  basically copy over whatever you need from the repo based on your needs.
- [ahoy](#tools) needs to be installed in the app container if you are going to
  use ahoy commands.

```yml
hooks:
  build: |
    ##
    # Get the content of https://github.com/hanoii/platformsh-recipes.
    ###
    echo -e "\033[0;36m[$(date -u "+%Y-%m-%d %T.%3N")] Installing hanoii/platformsh-recipes...\033[0m"
    mkdir -p /tmp/platformsh-recipes
    cd /tmp/platformsh-recipes
    wget -qO- https://github.com/hanoii/platformsh-recipes/archive/COMMIT-SHA1.tar.gz | tar -zxf - --strip-component=1 -C /tmp/platformsh-recipes
    # Install tools
    # ./scripts/platformsh-recipes/platformsh/build.sh
    cp -R /tmp/platformsh-recipes/scripts $PLATFORM_APP_DIR
    # cp /tmp/platformsh-recipes/.ahoy.platformsh-recipes.yml $PLATFORM_APP_DIR/.ahoy.yml
    rm -fr /tmp/platformsh-recipes
    echo -e "\033[0;32m[$(date -u "+%Y-%m-%d %T.%3N")] Done installing hanoii/platformsh-recipes!\n\033[0m"
```

For the php logs commands, we need to alter php.access.log format so that in
includes more data, to do that add/amend the following on your
`.platform.app.yml`:

```yml
web:
  commands:
    pre_start: $PLATFORM_APP_DIR/scripts/platformsh-recipes/platformsh/php-pre-start.sh
    start: /usr/bin/start-php-app -y "$PLATFORM_APP_DIR/.deploy/php-fpm.conf"
```

And the following to your mounts

```yml
mounts:
  "/.deploy":
    source: local
    source_path: "deploy"
```

And if your production environment is other than master, some scripts reference
the main environment through `PLATFORMSH_RECIPES_MAIN_BRANCH` environment
variable:

```yml
variables:
  PLATFORMSH_RECIPES_MAIN_BRANCH: main
```

### Tools

There are different tools that I usually add to platform, some of them are
required by the commands referenced below.

You can take what you want from
[this repo's build.sh](scripts/platformsh-recipes/platformsh/build.sh) or
install them all by uncomment the following line in the build recipe above.

```yml
hooks:
  build: |
    # Install tools
    # ./scripts/platformsh-recipes/platformsh/build.sh
```

Some of this tools also needs additions to [Platform.sh's .environment
file][platformsh-environment]. You can also take what you need from
[this repo's .environment](scripts/platformsh-recipes/platformsh/.environment)
or source it directly by adding the following to your `.environment` file (**if
you are executing the biuld.sh, doing this is also necessary**):

```
source $PLATFORM_APP_DIR/scripts/platformsh-recipes/platformsh/.environment
```

[platformsh-environment]:
  https://docs.platform.sh/development/variables/set-variables.html#testing-environment-scripts

## Performance troubleshooting

The commands here can also be used to test and access platform projects locally,
to do that you need to make available the following environment variables:

- `PLATFORMSH_CLI_TOKEN`
- `PLATFORM_PROJECT`
- `PLATFORMSH_RECIPES_MAIN_BRANCH=main` (optional, defaults to `master`)

### ahoy commans

All of the ahoy commands below have the following flags

- `--days=N`, display logs of N days ago.
- `--all`, display logs without filtering by date
- `--404`, show only 404s
- `--not-404`, exclude 404s

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

Another command can only filter out accesses by IP, that can be then combined
with the above to gather more information.

```
ahoy log:access --ip
ahoy log:access --ip --404
ahoy log:access --ip --not-404
```

If you want to see more details about what was accessed by a single ip:

```
ahoy log:access --ip=w.x.y.z
```

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
