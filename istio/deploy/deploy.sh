#!/bin/bash

function help() {
    echo "This file is used to deploy the Nginx proxy for your Fn functions"
    echo "Before running this script, make sure you have Fn deployed on your cluster"
    echo .

    echo "Script arguments:"
    echo "- appname -  generic app name (e.g. myapp) - this is used for the label, as well as"
    echo "  in the deployment name and in the generic service; if you're deploying multiple versions"
    echo "  of the app, make sure this value is the same for all of them"
    echo "- version - e.g. v1, v2, v3 -- this is added to the label"
    echo "- route  - this is the route you want the container to proxy to (eg. r/app/v1)"
    echo "- upstream - name of the upstream Fn service + the namespace name (run kubectl get svc | grep fn-api and provide the full name of the service (e.g. myfn-fn-api.default))"
    echo .

    echo "Example - create proxy for 2 versions of the app"
    echo "./deploy.sh myapp v1 r/app/v1 pj-fn-api.default"
    echo "./deploy.sh myapp v2 r/app/v2 pj-fn-api.default"

}


if [ -z $1 ]; then
    echo "error: appname is missing"
    help
    exit 1
fi
APPNAME=$1

if [ -z $2 ]; then
    echo "error: version is missing"
    help
    exit 1
fi
VERSION=$2

if [ -z $3 ]; then
    echo "error: route is missing"
    help
    exit 1
fi
ROUTE=$3

if [ -z $4 ]; then
    echo "error: upstream server name is missing"
    help
    exit 1
fi
UPSTREAM=$4

TARGET_YAML="fnproxy-$RANDOM.yaml"
cp fnproxy.yaml.templ $TARGET_YAML

# MacOS-only thing where you need to provide the backup file extension ...
sed -i .bak "s@%APPNAME%@$APPNAME@g" $TARGET_YAML
sed -i .bak "s@%VERSION%@$VERSION@g" $TARGET_YAML
sed -i .bak "s@%UPSTREAM%@$UPSTREAM@g" $TARGET_YAML
sed -i .bak "s@%ROUTE%@$ROUTE@g" $TARGET_YAML

# Deleting the .bak as it's not needed and preserved the original file anyway
rm $TARGET_YAML.bak


echo "Done."
echo "Check the file $TARGET_YAML and run kubectl apply -f $TARGET_YAML to deploy it."








