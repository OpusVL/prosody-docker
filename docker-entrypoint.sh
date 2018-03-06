#!/usr/bin/env bash
set -euo pipefail

perl -e'system "ln", "-s", "/opt/prosody-modules-available/mod_$_", "/opt/prosody-modules-enabled/mod_$_" for map s/"//gr, split /[,;]\s*/, $ENV{PROSODY_COMM_MODULES}'

exec "$@"
