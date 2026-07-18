# terraform-google-load-balancer

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
global external HTTP load balancer. It wires together a health check, backend
service, URL map, target HTTP proxy and global forwarding rule
(`google_compute_global_forwarding_rule`).

## Usage

```hcl
module "load_balancer" {
  source = "github.com/cybercapybara/terraform-google-load-balancer"

  project_id     = var.project_id
  name           = "web-lb"
  port_range     = "80"
  backend_groups = [module.mig.instance_group]
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

## Inputs

| Name                | Description                                              | Type           | Default   | Required |
|---------------------|----------------------------------------------------------|----------------|-----------|:--------:|
| `project_id`        | ID of the project in which to create the load balancer.  | `string`       | n/a       |   yes    |
| `name`              | Base name used for the load balancer resources.          | `string`       | n/a       |   yes    |
| `port_range`        | Port range the global forwarding rule listens on.        | `string`       | `"80"`    |    no    |
| `backend_protocol`  | Protocol used by the backend service.                    | `string`       | `"HTTP"`  |    no    |
| `backend_port_name` | Named port the backend service forwards to.              | `string`       | `"http"`  |    no    |
| `backend_groups`    | Self links of instance groups to attach as backends.     | `list(string)` | `[]`      |    no    |
| `timeout_sec`       | Backend service request timeout in seconds.              | `number`       | `30`      |    no    |

## Outputs

| Name                 | Description                                    |
|----------------------|------------------------------------------------|
| `id`                 | Identifier of the global forwarding rule.     |
| `self_link`          | URI of the global forwarding rule.            |
| `ip_address`         | External IP address served by the LB.         |
| `backend_service_id` | Identifier of the backend service.            |

## License

[MIT](LICENSE)
