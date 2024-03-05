#!/bin/sh

pushd ..

printf "\Deploy HTTPBin service ...\n"
kubectl apply -f apis/httpbin.yaml

printf "\Deploy VirtualServices ...\n"
kubectl apply -f virtualservices/api-example-com-vs.yaml

popd