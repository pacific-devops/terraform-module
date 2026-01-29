resource "github_repository" "repo" {
  name                        = var.name
  description                 = var.description
  homepage_url                = var.homepage_url
  visibility                  = var.visibility
  archived                    = var.archived
  has_issues                  = var.has_issues
  has_discussions             = var.has_discussions
  has_projects                = var.has_projects
  has_wiki                    = var.has_wiki
  is_template                 = var.is_template
  allow_merge_commit          = var.allow_merge_commit
  allow_rebase_merge          = var.allow_rebase_merge
  allow_auto_merge            = var.allow_auto_merge
  allow_squash_merge          = var.allow_squash_merge
  squash_merge_commit_message = var.squash_merge_commit_message
  squash_merge_commit_title = var.squash_merge_commit_title   # new line added
  delete_branch_on_merge      = var.delete_branch_on_merge
  web_commit_signoff_required = var.web_commit_signoff_required
  auto_init                   = var.auto_init
  gitignore_template          = var.gitignore_template
  topics                      = var.topics
  vulnerability_alerts        = var.vulnerability_alerts
  allow_update_branch         = var.allow_update_branch

  dynamic "template" {
    for_each = var.template_details != null ? [1]: []
    content {
      owner = local.template_owner
      repository = local.template_repository
      include_all_branches = var.template_details.include_all_branches
    }
  }

  dynamic "security_and_analysis" {
    for_each = var.security_and_analysis != null ? [var.security_and_analysis] : []
    content {
      dynamic "advanced_security" {
        for_each = security_and_analysis.value.advanced_security != null ? [security_and_analysis.value.advanced_security] : []
        content {
          status = advanced_security.value.status
        }
      }
      dynamic "secret_scanning" {
        for_each = security_and_analysis.value.secret_scanning != null ? [security_and_analysis.value.secret_scanning] : []
        content {
          status = secret_scanning.value.status
        }
      }
      dynamic "secret_scanning_push_protection" {
        for_each = security_and_analysis.value.secret_scanning_push_protection != null ? [security_and_analysis.value.secret_scanning_push_protection] : []
        content {
          status = secret_scanning_push_protection.value.status
        }
      }
    }
  }
}

resource "github_branch_default" "default_branch" {
  repository = github_repository.repo.name
  branch     = var.default_branch
  depends_on = [
    github_repository_file.codeowners
  ]
}

resource "github_repository_custom_property" "product_code" {
  repository     = github_repository.repo.name
  property_name  = "product_code"
  property_type  = "single_select"
  property_value = [var.product_code]
}

resource "github_repository_custom_property" "owner" {
  repository     = github_repository.repo.name
  property_name  = "owner"
  property_type  = "string"
  property_value = [var.owner]
}

resource "github_repository_custom_property" "product_domain" {
  repository     = github_repository.repo.name
  property_name  = "product_domain"
  property_type  = "single_select"
  property_value = [var.product_domain]
}

resource "github_repository_custom_property" "ruleset_protect_main_branch" {
  repository     = github_repository.repo.name
  property_name  = "ruleset_protect_main_branch"
  property_type  = "true_false"
  property_value = [var.ruleset_protect_main_branch]
  depends_on = [  github_repository_file.codeowners ] # ensure CODEOWNERS file is created before applying branch protection rules -new code
}

resource "github_repository_custom_property" "ruleset_restrict_branch_names" {
  repository     = github_repository.repo.name
  property_name  = "ruleset_restrict_branch_names"
  property_type  = "true_false"
  property_value = [var.ruleset_restrict_branch_names]
}

resource "github_repository_custom_property" "ruleset_restrict_files" {
  repository     = github_repository.repo.name
  property_name  = "ruleset_restrict_files"
  property_type  = "true_false"
  property_value = [var.ruleset_restrict_files]
}

resource "github_repository_custom_property" "rulset_restrict_commit_messages" {
  repository     = github_repository.repo.name
  property_name  = "rulset_restrict_commit_messages" # confirmed missing e
  property_type  = "true_false" 
  property_value = [var.ruleset_restrict_commit_messages]
}

resource "github_repository_collaborators" "collaborators" {
  repository = github_repository.repo.name

  dynamic "user" {
    for_each = var.user_permissions
    content {
      username = user.key
      # Map legacy roles shown in the GitHub UI to roles available in the GitHub REST API
      # write = push, read = pull
      permission = lookup({
        write    = "push"
        read     = "pull"
      }, user.value, user.value)
    }
  }

  dynamic "team" {
    for_each = var.team_permissions
    content {
      team_id = team.key
      # Map legacy roles shown in the GitHub UI to roles available in the GitHub REST API
      # write = push, read = pull
      permission = lookup({
        write    = "push"
        read     = "pull"
      }, team.value, team.value)
    }
  }
}

resource "github_repository_environment" "environment" {
  for_each            = var.environments
  repository          = github_repository.repo.name
  environment         = each.key
  prevent_self_review = each.value.prevent_self_review
  wait_timer          = each.value.wait_timer
  reviewers {
    teams = tolist(each.value.reviewers.teams)
    users = tolist(each.value.reviewers.users)
  }
}

resource "github_repository_file" "codeowners" {
  file       = ".github/CODEOWNERS"
  branch     = var.default_branch
  repository = github_repository.repo.name

  content = local.codeowners_content_from_codeowners_list

  commit_message      = "chore: update CODEOWNERS file"
  commit_author       = "global-data-analytics/dops-infra"
  commit_email        = "placeholder@us.mcd.com"

  depends_on = [github_repository.repo] # ensure repo & branch exist before adding file new code
}

data "github_repository" "template_repository" {
  count = var.template_details != null ? 1 : 0
  full_name = "${var.github_organization}/${var.template_details.repository}"
}

# Validation checks so failures are clear & early
resource "null_resource" "validate_template_repository" {
  count = var.template_details != null ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.template_full_name != null
      error_message = "Template repository for ${var.name} does not exist: ${var.template_details.owner}/${var.template_details.repository}"
    }

    precondition {
      condition     = local.template_repo_is_template == true
      error_message = "Template repository for ${var.name} is not a template repository: ${var.template_details.owner}/${var.template_details.repository}"
    }
  }
}

resource "github_repository_autolink_reference" "autolink" {
  for_each            = { for a in local.deduped_autolinks : a.key_prefix => a }

  repository          = github_repository.repo.name
  key_prefix          = each.value.key_prefix
  target_url_template = each.value.url_template
  is_alphanumeric     = each.value.is_alphanumeric
}
