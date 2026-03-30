terraform {
  required_providers {
    semaphoreui = {
      source  = "ansible-semaphore/semaphoreui"
      version = "~> 0.1.4"
    }
  }
}

provider "semaphoreui" {
  #url   = "http://localhost:3000"
  #token = "your_personal_access_token_here"
}

# Assuming you want everything inside a single project space
resource "semaphoreui_project" "workstation" {
  name = "Arch Linux Workstation"
}

resource "semaphoreui_project_repository" "github_repo" {
  project_id = semaphoreui_project.workstation.id
  name       = "ansible-provision"
  git_url    = "https://github.com/ito-rafael/ansible-provision"
  git_branch = "main"
  # access_key is omitted since it is "None"
}

resource "semaphoreui_project_repository" "local_repo" {
  project_id = semaphoreui_project.workstation.id
  name       = "local (test)"
  git_url    = "file:///home/rafael/git/ansible-provision"
  git_branch = "main"
}

resource "semaphoreui_project_environment" "linear_strategy" {
  project_id = semaphoreui_project.workstation.id
  name       = "Linear Strategy"
  env        = jsonencode({
    "ANSIBLE_STRATEGY" = "linear"
  })
}

resource "semaphoreui_project_inventory" "file_inventory" {
  project_id    = semaphoreui_project.workstation.id
  name          = "ansible-provision"
  type          = "file"
  repository_id = semaphoreui_project_repository.github_repo.id
  inventory     = "inventory/hosts.yml"
}

resource "semaphoreui_project_template" "github_template" {
  project_id     = semaphoreui_project.workstation.id
  name           = "ansible-provision"
  playbook       = "local.yml"
  repository_id  = semaphoreui_project_repository.github_repo.id
  inventory_id   = semaphoreui_project_inventory.file_inventory.id
  #environment_id = semaphoreui_project_environment.linear_strategy.id

  # Ansible Options & Prompts
  # The provider allows you to set the default CLI arguments or limit strings directly.
  # The specific UI prompt toggles (Tags: enabled, etc.) are currently handled by allowing overrides.
  allow_override_args_in_task = true
}

resource "semaphoreui_project_template" "local_template" {
  project_id     = semaphoreui_project.workstation.id
  name           = "local (test)"
  playbook       = "local.yml"
  repository_id  = semaphoreui_project_repository.local_repo.id
  inventory_id   = semaphoreui_project_inventory.file_inventory.id
  #environment_id = semaphoreui_project_environment.linear_strategy.id

  allow_override_args_in_task = true
}
