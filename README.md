# prosody-docker
Dockerfile to build a Prosody XMPP server container image.

# Configuration

The base Prosody image does not come with any preconfigured virtual hosts other than `localhost`. Users are expected to write their own virtual host and component configuration files and then mount them into the container at `/etc/prosody/vhost.d/` and `/etc/prosody/cmpt.d/` respectively. There are however a number of environment variables available to modify the global configuration as desired, these are documented below.

## Environment

### `PROSODY_LOG_LEVEL`
Default value: `info`

Determines which log level to use for the console output, possible values are `info`, `warn`, `error` and `debug`.

### `PROSODY_MODULES_AVAILABLE`
Default value: `none`  
Example: `-e PROSODY_MODULES_AVAILABLE='lastlog firewall swedishchef'`

A space-separated list of modules to symlink from `/opt/prosody-modules-available/`
to `/opt/prosody-modules-enabled/`, does not enable them by default however. You then
need to specify within `PROSODY_MODULES_ENABLED` if you'd like them loaded globally.

### `PROSODY_MODULES_ENABLED`
Default value: `none`  
Example: `-e PROSODY_MODULES_ENABLED='websocket server_contact_info'`

A space-separated list of modules to enable within the global modules_enabled configurartion
block. This variable will also attempt to deduplicate any modules passed through.

### `PROSODY_MODULES_DISABLED`
Default value: `none`  
Example: `-e PROSODY_MODULES_DISABLED='s2s carbons'`

A space-separated list of modules to disable, if they would be loaded
automatically by Prosody.

### `PROSODY_DEFAULT_STORAGE`
Default value: `internal`  
Example: `-e PROSODY_DEFAULT_STORAGE='sql'`

### `PROSODY_STORAGE_<store>`
Default value: `none`  
Example: `-e PROSODY_STORAGE_ACCOUNTS='sql' -e PROSODY_STORAGE_ARCHIVE='sql'`

A dynamic variable used to construct the `storage` array within the main
Prosody configuration file. Allows for extremely granular control of your Prosody
data stores.

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

### `PROSODY_S2S_INSECURE_DOMAINS`
Default value: `none`

A space-separated list of that will not be required to authenticate
using certificates.

### `PROSODY_S2S_SECURE_DOMAINS`
Default value: `none`

A space-separated list of domains which still require valid certificates
even if you leave `s2s_secure_auth` disabled.

## Database Storage Mode

If either `PROSODY_DEFAULT_STORAGE` or any of the `PROSODY_STORAGE_<store>` variables are set to `sql`, the [entrypoint script](https://github.com/OpusVL/prosody-docker/blob/master/entrypoint.pl#L131) will automatically detect this and make available the configuration options to allow for database connections as environment variables. The base image contains all three drivers needed to connect to PostgreSQL, MySQL or SQLite3 databases.

### `PROSODY_DB_DRIVER`
Default value: `PostgreSQL`

### `PROSODY_DB_NAME`
Default value: `prosody`

### `PROSODY_DB_HOST`
Default value: `postgresql`

### `PROSODY_DB_PORT`
Default value: `5432`

### `PROSODY_DB_USERNAME`
Default value: `prosody`

### `PROSODY_DB_PASSWORD`
Default value: `none` (will `die` if not set)

## Bootstrap Mode

This Docker image has the option to bootstrap a very basic VirtualHost based on a few environment variables. The bootstrap host will inherit any settings from the global configuration. If the `PROSODY_S2S_REQUIRE_ENCRYPTION` setting is set to `true` then you'll need to bind mount TLS certificates into the `/etc/prosody/certs` directory.

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
