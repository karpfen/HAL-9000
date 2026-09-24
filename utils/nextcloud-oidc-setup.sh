#!/bin/bash
# One-time Pocket ID OIDC setup for Nextcloud. user_oidc has no declarative
# config-file mechanism (Nextcloud apps/config live in the running
# container's database), so this scripts the `occ` commands instead of
# leaving them as manual steps.
#
# IMPORTANT: --unique-uid=0 plus the three occ config:system:set calls below
# are what make this LINK to an existing Nextcloud account by matching
# username, rather than creating a new one. Do not change these without
# re-reading nextcloud/user_oidc's README "Provisioning scenarios" section -
# getting this wrong risks silently creating duplicate accounts.
#
# Usage: utils/nextcloud-oidc-setup.sh <client-id> <client-secret>
set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <client-id> <client-secret>" >&2
	echo "(client-id/secret come from the OIDC client you create in Pocket ID for Nextcloud - see docs/pocket-id-user-guide.md)" >&2
	exit 1
fi

CLIENT_ID="$1"
CLIENT_SECRET="$2"
DISCOVERY_URI="https://hal9000.lan:8443/.well-known/openid-configuration"

occ() {
	docker exec -u www-data nextcloud php occ "$@"
}

# Nextcloud refuses any request whose Host header isn't in trusted_domains -
# without this, visiting it via hal9000.lan shows an "untrusted domain" block
# page instead of ever reaching login. Appends rather than overwriting, so
# the existing IP-based trusted domain (and direct access via it) is kept.
if ! occ config:system:get trusted_domains 2>/dev/null | grep -qx "hal9000.lan"; then
	next_domain_index=$(occ config:system:get trusted_domains 2>/dev/null | wc -l)
	occ config:system:set trusted_domains "$next_domain_index" --value="hal9000.lan"
fi

# Caddy terminates TLS and forwards plain HTTP to this container. Same-host
# connections that hit a published port (i.e. Caddy -> localhost:8080) are
# NATed by Docker to appear as coming from the container's own bridge
# network, not the real external client - so scoping the override to that
# private range (rather than trusting X-Forwarded-Proto unconditionally)
# means direct LAN access to :8080 is completely unaffected and still
# correctly treated as plain HTTP.
occ config:system:set overwriteprotocol --value="https"
occ config:system:set overwritecondaddr --value='^172\.(1[6-9]|2[0-9]|3[0-1])\.'
if ! occ config:system:get trusted_proxies 2>/dev/null | grep -qx "172.16.0.0/12"; then
	next_proxy_index=$(occ config:system:get trusted_proxies 2>/dev/null | wc -l)
	occ config:system:set trusted_proxies "$next_proxy_index" --value="172.16.0.0/12"
fi

occ app:install user_oidc || occ app:enable user_oidc

occ user_oidc:provider PocketID \
	--clientid="$CLIENT_ID" \
	--clientsecret="$CLIENT_SECRET" \
	--discoveryuri="$DISCOVERY_URI" \
	--mapping-uid="preferred_username" \
	--unique-uid=0 \
	--send-id-token-hint=0

# Link to existing accounts (by the preferred_username claim matching an
# existing Nextcloud username exactly), update their attributes on login,
# but never create a brand-new account for an unmatched login.
occ config:system:set user_oidc auto_provision --value=true --type=boolean
occ config:system:set user_oidc soft_auto_provision --value=true --type=boolean
occ config:system:set user_oidc disable_account_creation --value=true --type=boolean

echo "Done. Verify with one real existing account before relying on this:"
echo "  - Confirm 'Enable Self-Account Editing' is off for that user in Pocket ID,"
echo "    so their username claim can't drift out of sync."
echo "  - Log in via Pocket ID and confirm it lands on the EXISTING Nextcloud"
echo "    account (same files visible), not a newly created one."
