#!/bin/bash

rasax_pod=`k get -n $RASAX_NS pods -o custom-columns=name:.metadata.name --no-headers | \
    grep $RASAX_NS-rasa-x`

kubectl -n $RASAX_NS \
    exec pod/$rasax_pod -- \
    python scripts/manage_users.py create --update me safe_credential admin


