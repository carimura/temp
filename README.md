# Traffic splitting using Fn and Nginx

This is a simple demo that demonstrates how to do weight based traffic splitting to different functions/function versions.

## Setup

1.  Deploy Fn using the Helm chart
    If you're using Docker for Mac, Fn API URL will be localhost:80, you can try that it works by doing `curl localhost/version`

    Deploy the Helm chart fo `fn-nginx` namespace and call your release `nginx-fn` (this is important as these values are used in the nginx config)

2.  Deploy the functions (app/v1 and app/v2) from the `fn` folder:

```
export FN_REGISTRY=[your_repo]
FN_API_URL=http://localhost:80 fn deploy --all
```

Check that functions are deployed (calls below should return 'hello v1' and 'hello v2'):

```
curl localhost/r/app/v1
curl localhost/r/app/v2
```

## Deploying the App service

We need a Kubernetes service that's going to represent our app (`myapp.yaml`). This service can be only accessible from within the cluster or exposed publicly as well. In the demo, we are exposing the service to the host on port `9999` (internally to the cluster, service is accessbile on host `http://myapp.fn-nginx` where `fn-nginx` is the namespace service runs in. This service in turn, routes to an Nginx instance with custom config where the routing rules are defined.

1.  Create the `myapp` deployment and service:

```
kubectl apply -f deploy/myapp.yaml
```

By default, `myapp` service will route 100% of traffic to the v1 version (i.e. /app/v1). The service is also accessible from `http://localhost:9999`.

2.  Shift traffic
    The easiest way to see traffic shifting in progress is to contiuously make requests to the endpoint. In a separate terminal window, open:

```
while true; do sleep 1; curl http://localhost:9999;done
```

This is will make continouos calls to the service - at this point it should be output the message below every second:

```
{"message":"hello v1"}
```

The `update.sh` script can be used to change the traffic split like this:

```
# All traffic to V1
./update.sh v1

# All traffic to V2
./update.sh v2

# 50/50 split between v1 and v2
./update.sh 5050
```

As you run the commands above, observe how the output changes in the endless loop.

# Tech details

## Custom Nginx image (`/appimage`)

Nothing too special with this image - we are just copying the Nginx configurations to the image, so we can replace them when `./update.sh` is called.

Image lives at `pj3677/nginx-fn`. To rebuild/push to different registry:

```
docker build -t [registry]/[image-name] .
```

If you make changes to the image, make sure yo update the `image` field in the `myapp.yaml` file as well and eithe re-deploy the app OR delete the pod, so it restarts and pulls the new image automatically.

## Nginx config

ic splitting is done using the `split_clients` module from Nginx. We are defining a variable called `app_url` and then setting the variable either to v1 endpoint or v2 endpoint (e.g. /r/app/v1 or /r/app/v2), based on the set percentage. Once that's set, we are passing the traffic to an upstram server (which is the Fn load balancer) and appending the `app_url` to it, so it routes to specific function version.

## Update script

Script is doing a quick and dirty way of updating the Nginx configuration - we have 3 different Nginx config files for 3 cases (100% -> v1, 100% -> v2 and 50/50) and script gets the pod where the Nginx is running, replaces the config and reloads the Nginx.

In the ideal world, we would probably use a config map to store the Nginx configuration and a custom Nginx image that could reload the configuration automatically as soon as the associated config map changes.
