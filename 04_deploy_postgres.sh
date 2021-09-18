#!/bin/bash

# Add the repository which contains the postgresql chart
helm repo remove bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami

# Deploy postgresql
helm --kubeconfig $KUBECONFIG install \
    $DB_NS \
    --namespace $DB_NS \
    --values values.postgres.yml \
    bitnami/postgresql

