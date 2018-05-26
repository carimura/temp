# Traffic splitting for Fn using Istio

> I just got this to work, so there might be things that could be done way
> simpler - I'll have to go back and look through this again to see how can we
> simplify it.

## Setup

1.  Deploy Fn using the Helm chart If you're using Docker for Mac, Fn API URL
    will be localhost:80, you can try that it works by doing
    `curl localhost/version`

    Deploy the Helm chart fo `fn-istio` namespace and remember what you called
    your relase as you will need this when deploying the proxies.

2.  Deploy the functions (app/v1 and app/v2) from the root `fn`:

Note: You can delete the Fn UI service as it will probably collide with the
FN_API as both services are running on port 80.

```
export FN_REGISTRY=[your_repo]
FN_API_URL=http://localhost:80 fn deploy --all
```

Check that functions are deployed (calls below should return 'hello v1' and
'hello v2'):

```
curl localhost/r/app/v1
curl localhost/r/app/v2
```

## Deploy the proxy

You can use the `deploy/deploy.sh` script to deploy the proxies to your two
functions.

Assuming your two apps are deployed and accessible on `r/app/v1` and `r/app/v2`,
you can run the deploy script twice to deploy proxies to those two functions.
You will also need the name of the Fn API service that's running in Kubernetes
(run `kubectl get svc | grep fn-api` to get the service name)

```
# Generate the v1 proxy (fn api service name would be something like `prefix-fn-api.default`)
./deploy.sh myapp v1 r/app/v1 [FN_API_SERVICE_NAME]
kubectl apply -f <(istioctl kube-inject -f [GENERATED_FILE_NAME])

# Generate the second version
./deploy.sh myapp v2 r/app/v2 [FN_API_SERVICE_NAME]

kubectl apply -f <(istioctl kube-inject -f [GENERATED_FILE_NAME])
```

This will deploy two proxies, a generic Kubernetes service called
`myapp-service` and an Ingress resource, so you can access this service from
outside of the cluster.

To get the Ingress IP, run the command below and use the external IP column:

```
kubectl get svc -n istio-system | grep istio-ingress
```

## Routing traffic

Run `curl` in endless loop, so you can see the responses:

```
while true; do sleep 1; curl http://[INGRESS_ENDPOINT];done
```

3.  Deploy the routing rule to route all requests to V1:

```
kubectl apply -f all-v1.yaml
```

At this point, all requests should be going to V1.

4.  Try other routing rules:

You can now deploy `all-v2.yaml` or `5050.yaml` (or modify any of these routing
rules and try them out).

To delete the routing rule(s), run `kubectl get routerule -n fn-istio` and then
`kubectl delete routerule [rulename] -n fn-istio`.

## Deploying the App service (OLD)

In order for Istio routing to work properly we need the following:

*   Kubernetes service that represents a versioned app we want to access
    (`appservice`)
*   Kubernetes deployment for each version of the app (e.g. /r/app/v1 and
    /r/app/v2) with Istio sidecar injected

> Explanation on why we need this: Reason we need this is because of the way
> Istio does routing - it uses Pods and labels to route to different version.
> The gist is that you need a generic service (`appservice`) that targets all
> versions of your app (label: app=myapp) and then you create version specific
> deployments (v1, v2, ...). At this point, calling the >generic service will
> give you responses back from all versioned deployments as the only label
> you're using in the service is `app=myapp`. Here's where Istio comes >into
> play - with a Route rule you can say that you want X% of traffic to go to a
> route represented with a label `version=v1`. With this rule deployed and with
> Istio >sidecar in all your versioned app deployments, when you call the
> generic `appservice`, the rule will be respected and X% of the traffic will
> get routed to pods that >correspond to labels: `app=myapp, version=v1`. Since
> your functions are run by the Fn server (which is in it's own pod), the
> versioned deployments are in our case just simple Nginx containers that route
> to the >Fn loadbalancer at the correct path where the app lives. So, the v1
> Nginx deployment routes to `fn-server/r/app/v1` and v2 routes to
> `fn-server/r/app/v2`. I'd like >to come back to the way this is implemented
> and see if it's possible to make this simpler, so it doesn't involve deploying
> Nginx proxies.

*   Ingress to call the `appservice`, so Istio rules are respected

Note: To make things easier (demo purposes), I changed the type of the
`istio-ingress` service in `istio-system` namespace to LoadBalancer and changed
the port from 80 to 1234 - this makes the Istio ingress accessible from the
`http://localhost:1234`. You should be able to use the external IP address of
`istio-ingress` if you're using OKE or other publuic cloud.

1.  Deploy the two versioned apps (with Istio sidecar injected) and the
    `appservice` Kubernetes service:

```
kubectl apply -f <(istioctl kube-inject -f deploy/app.yaml)
```

2.  Deploy the gateway ingress:

```
kubectl apply -f deploy/ing.yaml
```

At this point, you can try and access the versioned apps by calling the Istio
ingress at `http://localhost:1234`. You should be getting `hello v1` and
`hello v2` responses (this is because the `appservice` is load balancing between
all pods with labels app=myapp and that includes v1 and v2 pods).

---

Next steps:

*   finish the readme/docs
*   install it on public Kubernetes cluster
*   spinnaker/jenkins rolling deploy with manual promotion to different stages

TODO:

*   Kubernetes Services for functions - expose functions as kubernetes services
