locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "infrastructure-team"
  }

  name_prefix = "${var.prefix}-${var.environment}"
}
