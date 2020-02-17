---------- Server-wide settings ----------
-- Settings in this section apply to the whole server and are the default settings
-- for any virtual hosts

network_backend = "${PROSODY_NETWORK_BACKEND:-select}"

daemonize = false

certificates = "certs"

Include "conf.d/modules.cfg.lua"
Include "conf.d/logging.cfg.lua"

if ${PROSODY_EXTRA_CFG:-0} == 1 then
        Include "conf.d/extra.cfg.lua"
end

-- Disable account creation by default, for security
-- For more information see https://prosody.im/doc/creating_accounts

allow_registration = ${PROSODY_ALLOW_REGISTRATION:-false}

-- Force clients to use encrypted connections? This option will
-- prevent clients from authenticating unless they are using encryption.

c2s_require_encryption = ${PROSODY_C2S_REQUIRE_ENCRYPTION:-true}

-- Force servers to use encrypted connections? This option will
-- prevent servers from authenticating unless they are using encryption.
-- Note that this is different from authentication

s2s_require_encryption = ${PROSODY_S2S_REQUIRE_ENCRYPTION:-true}

-- Force certificate authentication for server-to-server connections?
-- This provides ideal security, but requires servers you communicate
-- with to support encryption AND present valid, trusted certificates.
-- NOTE: Your version of LuaSec must support certificate verification!
-- For more information see https://prosody.im/doc/s2s#security

s2s_secure_auth = ${PROSODY_S2S_SECURE_AUTH:-false}

-- Some servers have invalid or self-signed certificates. You can list
-- remote domains here that will not be required to authenticate using
-- certificates. They will be authenticated using DNS instead, even
-- when s2s_secure_auth is enabled.

s2s_insecure_domains = { ${PROSODY_S2S_INSECURE_DOMAINS} }

-- Even if you leave s2s_secure_auth disabled, you can still require valid
-- certificates for some domains by specifying a list here.

s2s_secure_domains = { ${PROSODY_S2S_SECURE_DOMAINS} }

-- Select the authentication backend to use. The 'internal' providers
-- use Prosody's configured data storage to store the authentication data.
-- To allow Prosody to offer secure authentication mechanisms to clients, the
-- default provider stores passwords in plaintext. If you do not trust your
-- server please see https://prosody.im/doc/modules/mod_auth_internal_hashed
-- for information about using the hashed backend.

authentication = "${PROSODY_AUTHENTICATION:-internal_hashed}"

-- Select the storage backend to use. By default Prosody uses flat files
-- in its configured data directory, but it also supports more backends
-- through modules. An "sql" backend is included by default, but requires
-- additional dependencies. See https://prosody.im/doc/storage for more info.

default_storage = "${PROSODY_DEFAULT_STORAGE:-internal}"
storage = {
    ${PROSODY_STORAGE_KVP}
}
sql = ${PROSODY_SQL_CONNECTION:-""}

-- Archiving configuration
-- If mod_mam is enabled, Prosody will store a copy of every message. This
-- is used to synchronize conversations between multiple clients, even if
-- they are offline. This setting controls how long Prosody will keep
-- messages in the archive before removing them.

archive_expires_after = "1w" -- Remove archived messages after 1 week

-- You can also configure messages to be stored in-memory only. For more
-- archiving options, see https://prosody.im/doc/modules/mod_mam

-- Uncomment to enable statistics
-- For more info see https://prosody.im/doc/statistics
-- statistics = "internal"

----------- Virtual hosts -----------
-- You need to add a VirtualHost entry for each domain you wish Prosody to serve.
-- Settings under each VirtualHost entry apply *only* to that host.

VirtualHost "${PROSODY_DEFAULT_VIRTUALHOST:-localhost}"

Include "vhost.d/*.cfg.lua"

------ Components ------
-- You can specify components to add hosts that provide special services,
-- like multi-user conferences, and transports.
-- For more information on components, see https://prosody.im/doc/components

Include "cmpt.d/*.cfg.lua"
