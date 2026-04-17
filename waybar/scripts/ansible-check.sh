#!/usr/bin/env bash

export ANSIBLE_STDOUT_CALLBACK=json

ansible-playbook /home/ansible/git/ansible-provision/local.yml \
  --inventory /home/ansible/git/ansible-provision/inventory/hosts.yml \
  --limit $(hostname) \
  --check
