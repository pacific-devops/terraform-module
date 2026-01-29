# The ordering of variables is the same as in the resource definition for easier reference
# Link: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository 

variable "name" {
  description = "The name of the GitHub repository."
  type        = string
}

variable "description" {
  description = "The description of the GitHub repository."
  type        = string
}

variable "homepage_url" {
  description = "The URL of the homepage."
  type        = string
  default     = ""
}

variable "visibility" {
  description = "The visibility of the GitHub repository (internal or private)"
  type        = string
  default     = "internal"
}

variable "archived" {
  description = "Whether the repository should be archived"
  type        = bool
  default     = false
}

variable "has_issues" {
  description = "Whether the repository has issues enabled"
  type        = bool
  default     = false
}

variable "has_discussions" {
  description = "Whether the repository has discussions enabled"
  type        = bool
  default     = false
}

variable "has_projects" {
  description = "Whether the repository has projects enabled"
  type        = bool
  default     = false
}

variable "has_wiki" {
  description = "Whether the repository has a wiki"
  type        = bool
  default     = false
}

variable "is_template" {
  description = "Whether the repository is a template repository"
  type        = bool
  default     = false
}

variable "allow_merge_commit" {
  description = "Whether to allow merge commits"
  type        = bool
  default     = false
}

variable "allow_squash_merge" {
  description = "Whether to allow squash merges"
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Whether to allow rebase merges"
  type        = bool
  default     = false
}

variable "allow_auto_merge" {
  description = "Whether to allow auto merging of pull requests in a repository"
  type        = bool
  default     = true
}

variable "squash_merge_commit_title" {
  description = "The default title for a squash merge commit"
  type        = string
  default     = "PR_TITLE"     # change Pr title to PR_TITLE
}

variable "squash_merge_commit_message" {
  description = "The default message for a squash merge commit"
  type        = string
  default     = "PR_BODY"
}

variable "merge_commit_title" {
  description = "The default title for a merge commit"
  type        = string
  default     = "PR_TITLE"
}

variable "merge_commit_message" {
  description = "The default message for a merge commit"
  type        = string
  default     = "PR_BODY"
}

variable "delete_branch_on_merge" {
  description = "Whether to delete the branch on merge"
  type        = bool
  default     = true
}

variable "web_commit_signoff_required" {
  description = "Whether web-based commits to this repository will be required to sign off"
  type        = bool
  default     = false
}

variable "auto_init" {
  description = "Flag to create an initial commit with empty README"
  type        = bool
  default     = false    # true
}

variable "gitignore_template" {
  description = "The gitignore template to use"
  type        = string
  default     = ""
}

variable "topics" {
  description = "A list of topics to set on the repository"
  type        = list(string)
  default     = []
}

variable "vulnerability_alerts" {
  description = "Whether to enable vulnerability alerts"
  type        = bool
  default     = false
}

variable "allow_update_branch" {
  description = "Suggest updating pull request branches to latest version of default branch"
  type        = bool
  default     = true
}

variable "template_details" {
  description = "Details about the template repository"
  type = object({
    owner                = string
    repository           = string
    include_all_branches = optional(bool, false)
  })
  default = null
}

# END of github_repository variables

variable "default_branch" {
  description = "The default branch of the repository"
  type        = string
  default     = "main"
}


variable "github_organization" {
  description = "organization owning this repository"
  type        = string
  default     = "global-data-analytics"
}

# metadata custom properties for the repository

variable "product_code" {

  description = "product code for the repository"
  type        = string
  default     = "none"

  validation {
    condition = can(regex("^[a-z0-9]+$", var.product_code)) && regex("^[a-z0-9]+$", var.product_code) != null
    error_message = "Error: product_code '${var.product_code}' must be all lowercase letters (a-z) or numbers (0-9), with no uppercase, spaces, or special characters."
  }

  validation {
    condition = contains(keys(local.product_domain_map), var.product_code)
    error_message = "Error: product_code '${var.product_code}' is an invalid product code. It does not exist in the product:domain mapping file (product_domain_mapping.yaml) in global-data-analytics/dops-infra repo."
  }

}

variable "owner" {
  description = "owner for the repository"
  type        = string
  default     = "none"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}$", var.owner))
    error_message = "Invalid value for owner: ${var.owner}. Expected a valid email address."
  }

  validation {
    condition     = can(regex("mcd\\.com$", var.owner))
    error_message = "Invalid value for owner: ${var.owner}. Email must end with 'mcd.com'."
  }

}

variable "product_domain" {
  description = "product domain for the repository"
  type        = string

  validation {
    condition = contains(values(local.product_domain_map), var.product_domain)
    error_message = <<EOT
Error: product_domain '${var.product_domain}' is an invalid domain code.
It does not exist in the product:domain mapping file at modules/gh-repo/product_domain_mapping.yaml.
Valid domains include:
${join(", ", [for v in toset(values(local.product_domain_map)) : v])}
EOT
  }

  validation {
    condition = lookup(local.product_domain_map, var.product_code, null) == var.product_domain
    error_message = "Error: The product_code '${var.product_code}' must be associated with the domain '${local.product_domain_map[var.product_code]}' as defined in modules/gh-repo/product_domain_mapping.yaml, but received '${var.product_domain}'."
  }

  validation {
    condition = can(regex("^[a-z]+$", var.product_domain)) && regex("^[a-z]+$", var.product_domain) != null
    error_message = "Error: product_domain '${var.product_domain}' must be all lowercase letters (a-z) with no numbers, spaces, or special characters."
  }
}

variable "product_domain_map" {
  description = "A map of product to domain, parsed from YAML outside the module."
  type        = map(string)
  default     = {}

  validation {
    condition     = length(keys(var.product_domain_map)) > 0
    error_message = "Error: product_domain_map cannot be empty. Please provide a valid product to domain mapping."
  }
}

variable "security_and_analysis" {
  description = "Security and analysis configuration for the repository, including advanced security, secret scanning, and push protection."
  type = object({
    advanced_security = optional(object({
      status = string
    }))
    secret_scanning = optional(object({
      status = string
    }))
    secret_scanning_push_protection = optional(object({
      status = string
    }))
  })
  default = null
  
  validation {
    condition = var.security_and_analysis == null ? true : alltrue([
      for k, v in var.security_and_analysis : v == null ? true : contains(["enabled", "disabled"], v.status)
      if v != null
    ])
    error_message = "All security_and_analysis status values must be either 'enabled' or 'disabled'."
  }
  
  validation {
    condition = (
      var.security_and_analysis == null ||
      var.security_and_analysis.secret_scanning == null ||
      var.security_and_analysis.secret_scanning.status == "disabled" ||
      (var.security_and_analysis.advanced_security != null && var.security_and_analysis.advanced_security.status == "enabled")
    )
    error_message = "When secret_scanning is enabled, advanced_security must also be enabled."
  }
  
  validation {
    condition = (
      var.security_and_analysis == null ||
      var.security_and_analysis.secret_scanning_push_protection == null ||
      var.security_and_analysis.secret_scanning_push_protection.status == "disabled" ||
      (var.security_and_analysis.advanced_security != null && var.security_and_analysis.advanced_security.status == "enabled")
    )
    error_message = "When secret_scanning_push_protection is enabled, advanced_security must also be enabled."
  }
}

# ruleset custom properties for the repository

variable "ruleset_protect_main_branch" {
  description = "prevent force pushes to main branch"
  type        = bool
  default     = true
}

variable "ruleset_restrict_branch_names" {
  description = "enforce branch naming standards and require branches to begin with prefixes: feat, fix, docs"
  type        = bool
  default     = true
}

variable "ruleset_restrict_files" {
  description = "enforces strict restrictions on the types of files and file sizes that can be pushed to the repository."
  type        = bool
  default     = true
}


variable "ruleset_restrict_commit_messages" {
  description = "enforces a standardized format for commit messages, making it easier to understand the history of a project"
  type        = bool
  default     = true
}

locals {
  valid_permissions = ["admin", "maintain", "push", "pull", "write", "read", "triage"]
}

variable "team_permissions" {
  description = <<-EOT
    A map of team permissions for the repository.
    Key: Team slug (e.g., "data-platform-admins")
    Value: Team permission level (admin, maintain, push, pull, triage, write, or read)
    
    Example:
      team_permissions = {
        "data-platform-admins" = "admin"
        "data-platform-viewers" = "pull"
      }
  EOT
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for permission in values(var.team_permissions) : contains(local.valid_permissions, permission)
    ])
    error_message = <<-EOT
      Permission values must be one of:
        - admin
        - maintain
        - push
        - pull
        - triage
        - write (legacy for push)
        - read (legacy for pull)
    EOT
  }
}

variable "user_permissions" {
  description = <<-EOT
    A map of user permissions for the repository.
    Key: User name (e.g., "person1")
    Value: User permission level (admin, maintain, push, pull, triage, write, or read)
    
    Example:
      user_permissions = {
        "person1" = "admin"
      }
  EOT
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for permission in values(var.user_permissions) : contains(local.valid_permissions, permission)
    ])
    error_message = <<-EOT
      Permission values must be one of:
        - admin
        - maintain
        - push
        - pull
        - triage
        - write (legacy for push)
        - read (legacy for pull)
    EOT
  }
}

variable "environments" {
  description = "A map of environments to create in the repository"
  type = map(object({
    wait_timer          = optional(number, null)
    prevent_self_review = optional(bool, null)
    secrets             = optional(map(string), {})
    reviewers = optional(object({
      teams = optional(list(string), [])
      users = optional(list(string), [])
    }), {})
  }))
  default = {}
}

variable "codeowners_list" {
  description = <<-EOT
    Optional list of GitHub usernames or team names to be added to the CODEOWNERS file as owners of the entire repository.
    Each entry should be a valid GitHub username or team (e.g., "DATA-Github-Admin").
    If not set, a default will be used (set to {var.product_code}-Github_Admin)
  EOT
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for owner in var.codeowners_list : !startswith(owner, "@")
    ])
    error_message = "Entries in codeowners_list must not start with '@'. The CODEOWNERS template will add the '@' automatically."
  }
}

variable "custom_codeowners_lines" {
  description = <<-EOT
    Optional list of custom lines to add to the CODEOWNERS file.
    This is useful if teams want to require review by a specific person or team for certain kinds of files.
    For example: ["*.js    @js-owner"] will require @js-owner to review all JavaScript files.
    
    Note: Order matters in CODEOWNERS. 
    If multiple patterns match a file, the last matching pattern in the file takes precedence.
  EOT
  type        = list(string)
  default     = []
  validation {
    condition = var.custom_codeowners_lines == null ? true : alltrue([
      for line in var.custom_codeowners_lines : can(regex("@", line))
    ])
    error_message = "Each custom_codeowners_lines entry must contain an '@' character."
  }
}

variable "jira_base_url" {
  description = "The base URL of the Jira instance to link to in autolinks"
  type        = string
  default     = "https://mcd-tools.atlassian.net/browse/"
}

variable "jira_project_keys" {
  description = "A list of unique identifiers for JIRA projects to create autolinks for"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for key in var.jira_project_keys :
        can(regex("^[A-Z][A-Z0-9_]*$", key))
    ])
    error_message = <<-EOT
      The following entries do not adhere to the JIRA project key format:

      ${join("\n", [
        for v in var.jira_project_keys : v
        if !can(regex("^[A-Z][A-Z0-9_]*$", v)) 
        ]) }

        Please ensure the following:
          - Each key starts with an uppercase letter (A-Z)
          - Contains only uppercase Modern Roman letters (A-Z), numbers (0-9), or underscores (_)
          - Does not contain lowercase letters or other symbols 
      EOT
  }
}

variable "autolinks" {
  description = <<-EOT
    List of autolinks to create on the repository.
    Each autolink is an object with:
      - key_prefix: The prefix for the autolink (e.g., "TEAM-")
      - url_template: The URL template for the autolink (e.g., "https://mcd-tools.atlassian.net/browse/<num>")
      - is_alphanumeric: (optional) Whether the reference is alphanumeric (default: true)

    Example:
      autolinks = [
        {
          key_prefix      = "TEAM-"
          url_template    = "https://mcd-tools.atlassian.net/browse/TEAM-<num>"
          is_alphanumeric = false
        }
      ]
  EOT
  type = list(object({
    key_prefix      = string
    url_template    = string
    is_alphanumeric = optional(bool, true)
  }))
  default = []
}
