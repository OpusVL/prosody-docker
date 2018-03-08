# prosody-docker
Dockerfile to build a Prosody XMPP server container image.

# Configuration

The base Prosody image does not come with any preconfigured virtual hosts other than `localhost`. Users are expected to write their own virtual host and component configuration files and then mount them into the container at `/etc/prosody/vhost.d/` and `/etc/prosody/cmpt.d/` respectively. There are however a number of environment variables available to modify the global configuration as desired, these are documented below.

## Environment

### `PROSODY_LOG_LEVEL`
Default value: `info`

Determines which log level to use for the console output, possible values are `info`, `warn`, `error` and `debug`.

### `PROSODY_CORE_MODULES`
Default value: `none`  
Example: `-e PROSODY_CORE_MODULES='mam admin_telnet'`

A space-separated list of core module names to load.  See
`configuration/conf.d/modules.cfg.lua` for a list and whether they're enabled by
default or not.

### `PROSODY_COMM_MODULES`
Default value: `none`  
Example: `-e PROSODY_COMM_MODULES='lastlog firewall'`

A space-separated list of community modules to load. See
(https://hg.prosody.im/prosody-modules/).

### `PROSODY_MODULES_DISABLED`
Default value: `none`  
Example: `-e PROSODY_MODULES_DISABLED='ping carbons'`

A space-separated list of modules to disable, if they would be loaded
automatically by Prosody.

### `PROSODY_USE_LIBEVENT`
Default value: `false`

### `PROSODY_ALLOW_REGISTRATION`
Default value: `false`

### `PROSODY_C2S_REQUIRE_ENCRYPTION`
Default value: `true`

### `PROSODY_S2S_REQUIRE_ENCRYPTION`
Default value: `true`

### `PROSODY_S2S_SECURE_AUTH`
Default value: `false`
