#!/bin/sh

export GLOO_EDGE_VERSION="1.15.14"
export GLOO_EDGE_HELM_VALUES_FILE="gloo-edge-helm-values.yaml"

if [ -z "$GLOO_EDGE_LICENSE_KEY" ]
then
   echo "Gloo Edge License Key not specified. Please configure the environment variable 'GLOO_EDGE_LICENSE_KEY' with your Gloo Edge License Key."
fi

helm upgrade --install gloo glooe/gloo-ee --namespace gloo-system --create-namespace --set-string license_key=$GLOO_EDGE_LICENSE_KEY -f $GLOO_EDGE_HELM_VALUES_FILE --version $GLOO_EDGE_VERSION
