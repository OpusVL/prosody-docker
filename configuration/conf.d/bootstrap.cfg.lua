VirtualHost "${PROSODY_BOOTSTRAP_VIRTUALHOST}"

admins = { ${PROSODY_BOOTSTRAP_ADMIN_XIDS_QUOTED} }

authentication = "${PROSODY_BOOTSTRAP_AUTHENTICATION:-internal_hashed}"

storage = "${PROSODY_BOOTSTRAP_STORAGE:-internal}"

if storage == "sql" then
  sql = ${PROSODY_BOOTSTRAP_SQL_CONNECTION:-""}
end
