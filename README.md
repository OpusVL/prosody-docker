# prosody-docker
Dockerfile to build a Prosody XMPP server container image.

# Configuration

The base Prosody image does not come with any preconfigured virtual hosts other than `localhost`. Users are expected to write their own virtual host and component configuration files and then mount them into the container at `/etc/prosody/vhost.d/` and `/etc/prosody/cmpt.d/` respectively. There are however a number of environment variables available to modify the global configuration as desired, these are documented below.

## Environment

### `PROSODY_LOG_LEVEL`
Default value: `info`

Determines which log level to use for the console output, possible values are `info`, `warn`, `error` and `debug`.

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

## Bootstrap Mode

This Docker image has the option to bootstrap a very basic VirtualHost based on a few environment variables.

### `PROSODY_BOOTSTRAP`
Default value: `0`

Enables the bootstrap mode if set to `1`.

### `PROSODY_BOOTSTRAP_VIRTUALHOST`
Default value: `none`

The value to be substituted for use as the bootstrapped VirtualHost.

### `PROSODY_BOOTSTRAP_ADMIN_XIDS`
Default value: `none`  
Example: `-e PROSODY_BOOTSTRAP_ADMIN_XIDS='example@localhost.dev user2@localhost.dev'`

A space-separated list of administrators for the bootstrapped VirtualHost. These users are not created automatically however, you must manually do that once the server is online.

### `PROSODY_BOOTSTRAP_AUTHENTICATION`
Default value: `internal_hashed`

The authentication mode for the bootstrapped VirtualHost, defaults to hashed password.
