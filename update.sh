#!/bin/bash

namespace=fn-nginx
podname=$(kubectl get po -n $namespace --selector=app=myapp --output=jsonpath={.items[*].metadata.name})

if [ "$1" = "v1" ]; then
    echo "All traffic to V1"
    kubectl exec -it $podname -n $namespace -- bash -c "cp /etc/nginx/nginx-v1.conf /etc/nginx/nginx.conf && nginx -s reload"  > /dev/null 2>&1
    exit 0
fi

if [ "$1" = "v2" ]; then
    echo "All traffic to V2"
    kubectl exec -it $podname -n $namespace -- bash -c "cp /etc/nginx/nginx-v2.conf /etc/nginx/nginx.conf && nginx -s reload"  > /dev/null 2>&1
    exit 0
fi

if [ "$1" = "5050" ]; then
    echo "Split traffic 50/50"
    kubectl exec -it $podname -n $namespace -- bash -c "cp /etc/nginx/nginx-50-50.conf /etc/nginx/nginx.conf && nginx -s reload"  > /dev/null 2>&1
    exit 0
fi

exit 1


