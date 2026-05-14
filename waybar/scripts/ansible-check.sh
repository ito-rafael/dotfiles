#!/usr/bin/env bash

# silently update the git repos
git -C /home/ansible/git/dotfiles pull -q > /dev/null 2>&1
git -C /home/ansible/git/ansible-provision pull -q > /dev/null 2>&1
git -C /home/ansible/git/keebab pull -q > /dev/null 2>&1

export ANSIBLE_STDOUT_CALLBACK=json
# run the dry-run check
ansible-playbook /home/ansible/git/ansible-provision/local.yml \
  --inventory /home/ansible/git/ansible-provision/inventory/hosts.yml \
  --limit $(hostname) \
  --vault-id lbic@/home/ansible/git/ansible-provision/.secrets/lbic_vault.txt \
  --check
