# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `managed_ssl_certificate_domains` input: creates a
  `google_compute_managed_ssl_certificate` for the listed domains and serves it
  on the HTTPS proxy next to any `ssl_certificates`. A non-empty list on its own
  enables the HTTPS front end. The certificate name carries a hash of the domain
  list and uses `create_before_destroy`, so changing domains does not collide
  with the certificate in use. Validation rejects wildcards, duplicates and
  more than 100 domains; a precondition caps the proxy at 15 certificates.
- `managed_ssl_certificate_id` output.
- `examples/https` now uses `managed_ssl_certificate_domains` instead of its own
  certificate resource.

### Changed

- CI: bump actions to their current majors, pin tool versions, and restrict the
  workflow token to `contents: read`.
- CI: add Dependabot for GitHub Actions and the Terraform provider.
- Docs: pin the README usage `source` to a release tag; fix the LICENSE year.

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-google-load-balancer/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/moveeeax/terraform-google-load-balancer/releases/tag/v1.0.0
