variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "rules" {
  type = list(object({
    action      = string
    priority    = number
    description = string
    preview     = optional(bool, false)
    match = object({
      expr = optional(object({
        expression = string
      }))
      versioned_expr = optional(string)
      config = optional(object({
        src_ip_ranges = list(string)
      }))
    })
    rate_limit_options = optional(object({
      conform_action   = optional(string, "allow")
      exceed_action    = string
      ban_duration_sec = number
      enforce_on_key   = string
      rate_limit_threshold = object({
        count        = number
        interval_sec = number
      })
    }))
  }))
}

resource "google_compute_security_policy" "security_policy" {
  name        = var.name
  description = var.description

  dynamic "rule" {
    for_each = var.rules
    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      preview     = rule.value.preview

      match {
        dynamic "expr" {
          for_each = rule.value.match.expr != null ? [1] : []
          content {
            expression = rule.value.match.expr.expression
          }
        }
        versioned_expr = rule.value.match.versioned_expr
        dynamic "config" {
          for_each = rule.value.match.config != null ? [1] : []
          content {
            src_ip_ranges = rule.value.match.config.src_ip_ranges
          }
        }
      }

      dynamic "rate_limit_options" {
        for_each = rule.value.rate_limit_options != null ? [1] : []
        content {
          conform_action   = rule.value.rate_limit_options.conform_action
          exceed_action    = rule.value.rate_limit_options.exceed_action
          ban_duration_sec = rule.value.rate_limit_options.ban_duration_sec
          enforce_on_key   = rule.value.rate_limit_options.enforce_on_key
          rate_limit_threshold {
            count        = rule.value.rate_limit_options.rate_limit_threshold.count
            interval_sec = rule.value.rate_limit_options.rate_limit_threshold.interval_sec
          }
        }
      }
    }
  }
}


