terraform {
  required_providers {
    semaphoreui = {
      source  = "registry.terraform.io/semaphoreui/semaphore"
      version = "~> 0.2.2"
    }
  }
}

provider "semaphoreui" {
  #url   = "http://localhost:3000"
  #token = "your_personal_access_token_here"
}

variable "target_hostname" {
  type        = string
  description = "The target hostname passed from Ansible to use in the --limit flag"
}

variable "vault_password_lbic" {
  type        = string
  description = "The Ansible Vault password for the LBiC domain"
}

resource "semaphoreui_project" "ansible-provision" {
  name = "ansible-provision"
}

resource "semaphoreui_project_key" "none" {
  project_id = semaphoreui_project.ansible-provision.id
  name       = "None"
  none       = {}
}

resource "semaphoreui_project_key" "vault_key_lbic" {
  project_id = semaphoreui_project.ansible-provision.id
  name       = "LBiC Vault Password"

  login_password = {
    login    = "ansible_vault"
    password = var.vault_password_lbic
  }
}

resource "semaphoreui_project_repository" "github_repo" {
  project_id = semaphoreui_project.ansible-provision.id
  name       = "ansible-provision"
  url        = "https://github.com/ito-rafael/ansible-provision"
  branch     = "main"
  ssh_key_id = semaphoreui_project_key.none.id
}

resource "semaphoreui_project_repository" "local_repo" {
  project_id = semaphoreui_project.ansible-provision.id
  name       = "local (test)"
  url        = "file:///home/rafael/git/ansible-provision"
  branch     = "main"
  ssh_key_id = semaphoreui_project_key.none.id
}

resource "semaphoreui_project_environment" "linear_strategy" {
  project_id  = semaphoreui_project.ansible-provision.id
  name        = "Linear Strategy"
  environment = {
    "ANSIBLE_STRATEGY" = "linear"
  }
}

resource "semaphoreui_project_environment" "empty_environment" {
  project_id  = semaphoreui_project.ansible-provision.id
  name        = "Empty"
  environment = {}
}

resource "semaphoreui_project_inventory" "file_inventory" {
  project_id    = semaphoreui_project.ansible-provision.id
  name          = "ansible-provision"
  ssh_key_id    = semaphoreui_project_key.none.id
  file = {
    repository_id = semaphoreui_project_repository.github_repo.id
    path          = "inventory/hosts.yml"
  }
}

resource "semaphoreui_project_template" "github_template" {
  project_id     = semaphoreui_project.ansible-provision.id
  name           = "ansible-provision"
  playbook       = "local.yml"
  repository_id  = semaphoreui_project_repository.github_repo.id
  inventory_id   = semaphoreui_project_inventory.file_inventory.id
  #environment_id = semaphoreui_project_environment.linear_strategy.id
  environment_id = semaphoreui_project_environment.empty_environment.id
  arguments = [
    "--limit", var.target_hostname,
  ]
  allow_override_args_in_task = true

  vaults = [
    {
      name = "lbic"
      password = {
        vault_key_id = semaphoreui_project_key.vault_key_lbic.id
      }
    }
  ]
}

resource "semaphoreui_project_template" "local_template" {
  project_id     = semaphoreui_project.ansible-provision.id
  name           = "local (test)"
  playbook       = "local.yml"
  repository_id  = semaphoreui_project_repository.local_repo.id
  inventory_id   = semaphoreui_project_inventory.file_inventory.id
  #environment_id = semaphoreui_project_environment.linear_strategy.id
  environment_id = semaphoreui_project_environment.empty_environment.id
  arguments = [
    "--limit", var.target_hostname,
  ]
  allow_override_args_in_task = true

  vaults = [
    {
      name = "lbic"
      password = {
        vault_key_id = semaphoreui_project_key.vault_key_lbic.id
      }
    }
  ]
}
