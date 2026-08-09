#!/usr/bin/env bash
set -euo pipefail

local_auth_secret="$(gcloud secrets versions access latest \
  --secret=darjar-local-development-auth-secret \
  --project=raq-darjar)"
if [ "${#local_auth_secret}" -lt 32 ]; then
  printf '%s\n' 'Local authentication secret is missing or invalid.' >&2
  exit 1
fi

flutter run -d chrome \
  --dart-define="DARJAR_LOCAL_AUTH_SECRET=${local_auth_secret}" \
  "$@"
