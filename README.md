# Introduction

This repo contains code to accompany [The Basics Of Enabling Pods To Communicate Across Namepaces In Kubernetes]() blog post on Medium

# Prerequisites

The scripts in this repo was built and tested on Ubuntu 21.04.

# Usage

Run the following commands in a terminal:
```bash
source 00_install_microk8s.sh
source 01_env_vars.sh
source 02_create_namespace.sh
source 03_create_secret.sh
source 04_deploy_postgres.sh
source 05_get_postgres_fqn.sh
source 06_deploy_rasax.sh
source 07_create_users.sh
source 08_check_network.sh
```