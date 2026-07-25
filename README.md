# terraform-google-load-balancer

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
global external HTTP(S) load balancer. It wires together a health check, backend
service, URL map, target proxy and global forwarding rule
(`google_compute_global_forwarding_rule`).

Supply `ssl_certificates` and the module additionally creates a target HTTPS
proxy, a second global forwarding rule on 443, and an SSL policy that refuses
TLS below 1.2 — GCP's implicit default policy is the `COMPATIBLE` profile, which
still negotiates TLS 1.0. The plain HTTP front end is then turned into a 301
redirect to HTTPS.

## Usage

Plain HTTP:

```hcl
module "load_balancer" {
  source = "github.com/moveeeax/terraform-google-load-balancer"

  project_id     = var.project_id
  name           = "web-lb"
  backend_groups = [module.mig.instance_group]
}
```

HTTPS with a redirect, a hardened SSL policy and Cloud Armor:

```hcl
module "load_balancer" {
  source = "github.com/moveeeax/terraform-google-load-balancer"

  project_id     = var.project_id
  name           = "web-lb"
  backend_groups = [module.mig.instance_group]

  # One reserved address so HTTP and HTTPS answer on the same IP.
  ip_address       = google_compute_global_address.lb.address
  ssl_certificates = [google_compute_managed_ssl_certificate.lb.id]
  security_policy  = google_compute_security_policy.lb.id
}
```

Runnable examples live in [`examples/basic`](examples/basic) and
[`examples/https`](examples/https).

### Defaults worth knowing about

| Behaviour | Module default | GCP default without this module |
|---|---|---|
| Minimum TLS version | `TLS_1_2` (`MODERN` profile) | TLS 1.0 (`COMPATIBLE` profile) |
| HTTP → HTTPS redirect | on, once certificates are supplied | none |
| Backend service request logging | on, 100% sample | off |
| Health check port | the backends' serving port | n/a |
| Health check protocol | follows `backend_protocol` | n/a |
| Cloud Armor | none unless `security_policy` is set | none |

`port_range` is the **plain HTTP** listener. Pointing it at 443 does not give
you TLS — it gives you cleartext HTTP on port 443. Use `ssl_certificates` and
`https_port_range` instead.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

Running the test suite in [`tests/`](tests) additionally needs Terraform or
OpenTofu >= 1.7 for `mock_provider`. The module itself does not.

## Inputs

| Name                            | Description                                                                                                   | Type           | Default     | Required |
|---------------------------------|---------------------------------------------------------------------------------------------------------------|----------------|-------------|:--------:|
| `project_id`                    | ID of the project in which to create the load balancer.                                                       | `string`       | n/a         |   yes    |
| `name`                          | Base name used for the load balancer resources.                                                               | `string`       | n/a         |   yes    |
| `port_range`                    | Port range the plain HTTP forwarding rule listens on. Never TLS-terminated.                                   | `string`       | `"80"`      |    no    |
| `ip_address`                    | Reserved global external IP to serve from. Null gives each forwarding rule its own ephemeral address.         | `string`       | `null`      |    no    |
| `backend_protocol`              | Protocol used by the backend service. The health check protocol follows it.                                   | `string`       | `"HTTP"`    |    no    |
| `backend_port_name`             | Named port the backend service forwards to.                                                                   | `string`       | `"http"`    |    no    |
| `backend_groups`                | Self links of instance groups to attach as backends.                                                          | `list(string)` | `[]`        |    no    |
| `timeout_sec`                   | Backend service request timeout in seconds.                                                                   | `number`       | `30`        |    no    |
| `health_check_port`             | Fixed port to health check. Null uses the backends' serving port.                                             | `number`       | `null`      |    no    |
| `health_check_request_path`     | Path requested by the health check.                                                                           | `string`       | `"/"`       |    no    |
| `enable_health_check_logging`   | Emit health check state-change logs to Cloud Logging.                                                         | `bool`         | `true`      |    no    |
| `ssl_certificates`              | Self links of SSL certificates to serve. Non-empty enables the HTTPS front end.                               | `list(string)` | `[]`        |    no    |
| `https_port_range`              | Port range the HTTPS forwarding rule listens on.                                                              | `string`       | `"443"`     |    no    |
| `enable_http_to_https_redirect` | 301 the plain HTTP front end to HTTPS. Only applies when `ssl_certificates` is non-empty.                     | `bool`         | `true`      |    no    |
| `ssl_policy`                    | Self link of an existing SSL policy to attach. Null makes the module manage one.                              | `string`       | `null`      |    no    |
| `ssl_policy_profile`            | Profile of the module-managed SSL policy: `COMPATIBLE`, `MODERN` or `RESTRICTED`.                             | `string`       | `"MODERN"`  |    no    |
| `ssl_policy_min_tls_version`    | Minimum TLS version of the module-managed SSL policy: `TLS_1_0`, `TLS_1_1` or `TLS_1_2`.                      | `string`       | `"TLS_1_2"` |    no    |
| `security_policy`               | Self link of a Cloud Armor security policy to attach to the backend service.                                  | `string`       | `null`      |    no    |
| `enable_logging`                | Enable request logging on the backend service.                                                                | `bool`         | `true`      |    no    |
| `logging_sample_rate`           | Fraction of requests logged when `enable_logging` is true.                                                    | `number`       | `1.0`       |    no    |

## Outputs

| Name                 | Description                                                                     |
|----------------------|---------------------------------------------------------------------------------|
| `id`                 | Identifier of the HTTP global forwarding rule.                                  |
| `self_link`          | URI of the HTTP global forwarding rule.                                         |
| `ip_address`         | External IP address served by the HTTP forwarding rule.                         |
| `https_id`           | Identifier of the HTTPS global forwarding rule, or null when HTTPS is off.      |
| `https_ip_address`   | External IP address served by the HTTPS forwarding rule, or null when off.      |
| `backend_service_id` | Identifier of the backend service.                                              |
| `health_check_id`    | Identifier of the health check.                                                 |
| `ssl_policy_id`      | SSL policy attached to the HTTPS proxy, or null when HTTPS is off.              |

## Development

```sh
terraform fmt -recursive
terraform init -backend=false && terraform validate
terraform test
```

## License

[MIT](LICENSE)
