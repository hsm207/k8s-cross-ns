#!/bin/bash

# Add the repository which contains the Rasa X Helm chart
helm repo remove rasa-x
helm repo add rasa-x https://rasahq.github.io/rasa-x-helm

# Deploy Rasa X
helm --kubeconfig $KUBECONFIG install \
    $RASAX_NS \
    --namespace $RASAX_NS \
    --values values.community.yml \
    --values values.nodb.yml \
    --values values.ingress.yml \
    rasa-x/rasa-x && \
k apply -f custom_ingress.yml