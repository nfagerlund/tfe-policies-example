variable "tfe_token" {}

variable "tfe_hostname" {
  description = "The domain where your TFE is hosted."
  default     = "app.terraform.io"
}

variable "tfe_organization" {
  description = "The TFE organization to apply your changes to."
  default     = "nicktech"
}

variable "tfe_workspace_ids" {
  description = "Mapping of workspace names to IDs, for easier use in policy sets."
  type        = "map"

}

provider "tfe" {
  hostname = "${var.tfe_hostname}"
  token    = "${var.tfe_token}"
  version  = "~> 0.4"
}

resource "tfe_policy_set" "global" {
  name         = "global"
  description  = "Policies that should be enforced on ALL infrastructure."
  organization = "${var.tfe_organization}"
  global       = true

  policy_ids = [
    "${tfe_sentinel_policy.placeholder-true.id}",
    "${tfe_sentinel_policy.aws-block-allow-all-cidr.id}",
    "${tfe_sentinel_policy.azurerm-block-allow-all-cidr.id}",
    "${tfe_sentinel_policy.gcp-block-allow-all-cidr.id}",
    "${tfe_sentinel_policy.aws-restrict-instance-type-default.id}",
    "${tfe_sentinel_policy.azurerm-restrict-vm-size.id}",
    "${tfe_sentinel_policy.gcp-restrict-machine-type.id}",
  ]
}

resource "tfe_policy_set" "production" {
  name         = "production"
  description  = "Policies that should be enforced on production infrastructure."
  organization = "${var.tfe_organization}"

  policy_ids = [
    "${tfe_sentinel_policy.aws-restrict-instance-type-prod.id}",
    "${tfe_sentinel_policy.abstract_test.id}",
  ]

  workspace_external_ids = [
    "${var.tfe_workspace_ids["minimum-gitlab"]}",
    "${var.tfe_workspace_ids["minimum-prod"]}",
  ]
}

resource "tfe_policy_set" "development" {
  name         = "development"
  description  = "Policies that should be enforced on development or scratch infrastructure."
  organization = "${var.tfe_organization}"

  policy_ids = [
    "${tfe_sentinel_policy.aws-restrict-instance-type-dev.id}",
  ]

  workspace_external_ids = [
    "${var.tfe_workspace_ids["filetest-dev"]}",
    "${var.tfe_workspace_ids["minimum-dev"]}",
  ]
}

resource "tfe_policy_set" "sentinel" {
  name         = "sentinel"
  description  = "Policies that watch the watchman. Enforced only on the workspace that manages policies."
  organization = "${var.tfe_organization}"

  policy_ids = [
    "${tfe_sentinel_policy.tfe_policies_only.id}",
  ]

  workspace_external_ids = [
    "${var.tfe_workspace_ids["tfe-policies"]}",
  ]
}

# Test/experimental policies:

resource "tfe_sentinel_policy" "placeholder-true" {
  name         = "placeholder-true"
  description  = "Just passing through! Always returns 'true'."
  organization = "${var.tfe_organization}"
  policy       = "${file("./placeholder-true.sentinel")}"
  enforce_mode = "advisory"
}

resource "tfe_sentinel_policy" "placeholder-false" {
  name = "placeholder-false"
  description = "always fails"
  organization = "${var.tfe_organization}"
  policy       = "${file("./placeholder-false.sentinel")}"
  enforce_mode = "soft-mandatory"
}

resource "tfe_sentinel_policy" "abstract_test" {
  name = "abstract_test"
  description = "Forbid the triggers.username of a null_resource to be a plural noun. Implemented w/ re-usable all-resources fetcher. "
  organization = "${var.tfe_organization}"
  policy       = "${file("./abstract_test.sentinel")}"
  enforce_mode = "soft-mandatory"
}


# Sentinel management policies:

resource "tfe_sentinel_policy" "tfe_policies_only" {
  name         = "tfe_policies_only"
  description  = "The Terraform config that manages Sentinel policies must not use the authenticated tfe provider to manage non-Sentinel resources."
  organization = "${var.tfe_organization}"
  policy       = "${file("./tfe_policies_only.sentinel")}"
  enforce_mode = "hard-mandatory"
}

# Networking policies:

resource "tfe_sentinel_policy" "aws-block-allow-all-cidr" {
  name         = "aws-block-allow-all-cidr"
  description  = "Avoid nasty firewall mistakes (AWS version)"
  organization = "${var.tfe_organization}"
  policy       = "${file("./aws-block-allow-all-cidr.sentinel")}"
  enforce_mode = "hard-mandatory"
}

resource "tfe_sentinel_policy" "azurerm-block-allow-all-cidr" {
  name         = "azurerm-block-allow-all-cidr"
  description  = "Avoid nasty firewall mistakes (Azure version)"
  organization = "${var.tfe_organization}"
  policy       = "${file("./azurerm-block-allow-all-cidr.sentinel")}"
  enforce_mode = "hard-mandatory"
}

resource "tfe_sentinel_policy" "gcp-block-allow-all-cidr" {
  name         = "gcp-block-allow-all-cidr"
  description  = "Avoid nasty firewall mistakes (GCP version)"
  organization = "${var.tfe_organization}"
  policy       = "${file("./gcp-block-allow-all-cidr.sentinel")}"
  enforce_mode = "hard-mandatory"
}

# Compute instance policies:

resource "tfe_sentinel_policy" "aws-restrict-instance-type-dev" {
  name         = "aws-restrict-instance-type-dev"
  description  = "Limit AWS instances to approved list (for dev infrastructure)"
  organization = "${var.tfe_organization}"
  policy       = "${file("./aws-restrict-instance-type-dev.sentinel")}"
  enforce_mode = "soft-mandatory"
}

resource "tfe_sentinel_policy" "aws-restrict-instance-type-prod" {
  name         = "aws-restrict-instance-type-prod"
  description  = "Limit AWS instances to approved list (for prod infrastructure)"
  organization = "${var.tfe_organization}"
  policy       = "${file("./aws-restrict-instance-type-prod.sentinel")}"
  enforce_mode = "soft-mandatory"
}

resource "tfe_sentinel_policy" "aws-restrict-instance-type-default" {
  name         = "aws-restrict-instance-type-default"
  description  = "Limit AWS instances to approved list"
  organization = "${var.tfe_organization}"
  policy       = "${file("./aws-restrict-instance-type-default.sentinel")}"
  enforce_mode = "soft-mandatory"
}

resource "tfe_sentinel_policy" "azurerm-restrict-vm-size" {
  name         = "azurerm-restrict-vm-size"
  description  = "Limit Azure instances to approved list"
  organization = "${var.tfe_organization}"
  policy       = "${file("./azurerm-restrict-vm-size.sentinel")}"
  enforce_mode = "soft-mandatory"
}

resource "tfe_sentinel_policy" "gcp-restrict-machine-type" {
  name         = "gcp-restrict-machine-type"
  description  = "Limit GCP instances to approved list"
  organization = "${var.tfe_organization}"
  policy       = "${file("./gcp-restrict-machine-type.sentinel")}"
  enforce_mode = "soft-mandatory"
}
