locals {
  # Map product_code to special github admin string for certain codes, else use var.product_code
  product_code_github_admin_exceptions = {
    dops = "DATA"
    daap = "GDAP"
    desg = "ESGD"
  }

  product_code_for_github_admin = lookup(
    local.product_code_github_admin_exceptions, 
    var.product_code, 
    upper(var.product_code))

  default_codeowner = "${local.product_code_for_github_admin}-Github_Admin"

  # Determines the effective list of code owners for the CODEOWNERS file:
  # - If codeowners_list is empty, default to local.default_codeowner
  # - If codeowners_list is set, use its value as-is
  codeowners_list_effective = (
    length(var.codeowners_list) == 0 ? [local.default_codeowner] : var.codeowners_list
  )

  # constructs codeowners content based on local.codeowners_list_effective if non-empty
  codeowners_content_from_codeowners_list = templatefile("${path.module}/templates/CODEOWNERS.tftpl", {
    codeowners_list = local.codeowners_list_effective,
    custom_codeowners_lines = var.custom_codeowners_lines
  })

  # Accept the product-domain map as a variable input (should be a map)
  initial_product_domain_map = var.product_domain_map

  # Attempt coercion; use null for values that can't be converted
  product_domain_map_coerced = {
    for k, v in local.initial_product_domain_map :
    tostring(k) => try(tostring(v), null)
  }

  # Final normalized map (filter out invalid entries if you want to proceed)
  # Note: This silently filters out bad entries like lists in the YAML file
  product_domain_map = tomap({
    for k, v in local.product_domain_map_coerced :
    k => v
    if v != null
  })

  template_full_name = var.template_details != null ? try(data.github_repository.template_repository[0].full_name, null) : null
  template_repo_is_template = var.template_details != null ? try(data.github_repository.template_repository[0].is_template, null) : null
  template_owner       = local.template_full_name != null ? split("/", local.template_full_name)[0] : null
  template_repository  = local.template_full_name != null ? split("/", local.template_full_name)[1] : null

  # Generate autolink objects from each JIRA project key
  generated_autolinks = [
    for key in var.jira_project_keys : {
      key_prefix      = "${key}-"
      url_template    = "${var.jira_base_url}${key}-<num>"
      is_alphanumeric = false
    }
  ]

  # Use user-supplied autolinks if provided, otherwise an empty list
  combined_autolinks = var.autolinks != [] ? var.autolinks : []

  # Combine user-supplied autolinks and generated autolinks
  all_autolinks = concat(local.combined_autolinks, local.generated_autolinks)

  # Deduplicate autolinks by encoding each object to a string, applying distinct, then decoding back to objects
  deduped_autolinks = [
    for obj in distinct([for a in local.all_autolinks : jsonencode(a)]) : jsondecode(obj)
  ]
}
