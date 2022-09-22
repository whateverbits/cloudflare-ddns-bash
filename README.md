# Cloudflare DDNS Bash
Cloudflare Dynamic DNS Bash script for keeping a DNS record up-to-date with the system IP address. Supports IPv4 and/or IPv6, only modifies the record if necessary, and does not modify any record configurations besides IP address. Record must already exist on Cloudflare for script to function.

## Configure
Open the `cloudflare-ddns.sh` file in your editor of choice to modify the configuration options.

### API Token
A Cloudflare API token is required. Required zone permissions: `#dns_records:edit`.

+ Navigate to the [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens) page.
+ Select `Create Token` and use the `Edit zone DNS` template.
+ The `Permissions` fields will be populated with: `Zone` - `DNS` - `Edit`.
+ Under `Zone Resources` select the domain: `Include` - `Specific zone` - `example.com`.
+ Verify the settings and select `Continue to summary` followed by `Create Token`.
+ Copy the generated API token to the `cloudfare-ddns.sh` variable `APITOKEN`.

```bash
declare APITOKEN="generated-api-token"
```

Cloudflare Docs: [Creating API Tokens](https://developers.cloudflare.com/api/tokens/create/)

### Zone ID
The Cloudflare Zone ID of your domain is required.

+ Navigate to the [Cloudflare Dashboard](https://dash.cloudflare.com/) and select the domain.
+ On the domain `Overview` page, locate the `API` section.
+ Copy the `Zone ID` to the `cloudflare-ddns.sh` variable `ZONEID`.

```bash
declare ZONEID="cloudflare-zone-id"
```

### Domain
The root domain or a subdomain can be used for the dynamic DNS record.

```bash
declare -l DOMAIN="ddns.example.com"
```

### Records
Toggle A (IPv4) and/or AAAA (IPv6) record updates.

```bash
declare -l A_RECORD="true"
declare -l AAAA_RECORD="false"
```

### Example

```bash
# Configuration
# =============
# Cloudflare API Auth Token
declare APITOKEN="generated-api-token"
# Cloudflare Zone ID
declare ZONEID="cloudflare-zone-id"
# Domain: "example.com" || "www.example.com"
declare -l DOMAIN="ddns.example.com"
# IPv4 A Record: "true" || "false"
declare -l A_RECORD="true"
# IPv6 AAAA Record: "true" || "false"
declare -l AAAA_RECORD="false"
```

## Cronjob
Setup a CronJob to keep the DNS record accurate. Use `crontab -e` to add job.
Verify the `cloudflare-ddns.sh` file has execute permissions: `chmod 750 cloudflare-ddns.sh`.

```bash
# Every 10 minutes
*/10 * * * * /path/to/cloudflare-ddns.sh
```

## Issues
Open new issues in the [GitLab Issue Tracker](https://gitlab.com/whateverbits/cloudflare-ddns-bash/-/issues).

## License
Cloudflare DDNS Bash is distributed under the [ISC License](https://gitlab.com/whateverbits/cloudflare-ddns-bash/-/blob/main/LICENSE).

Cloudflare is a registered trademark of [Cloudflare Inc.](https://cloudflare.com/).
