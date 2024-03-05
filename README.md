# Solo-Projects-5889 Reproducer

## Installation

Add Gloo EE Helm repo:
```
helm repo add glooe https://storage.googleapis.com/gloo-ee-helm
```

Export your Gloo Edge License Key to an environment variable:
```
export GLOO_EDGE_LICENSE_KEY={your license key}
```

Install Gloo Edge:
```
cd install
./install-gloo-edge-enterprise-with-helm.sh
```

> NOTE
> The Gloo Edge version that will be installed is set in a variable at the top of the `install/install-gloo-edge-enterprise-with-helm.sh` installation script.

## Setup the environment

Run the `install/setup.sh` script to setup the environment:
- Deploy the HTTPBin service
- Deploy the VirtualServices

```
./setup.sh
```

## Run the test

Call the HTTPBin service with a simple cURL GET command:

```
curl -v http://api.example.com/httpbin/get
```

Our default VirtualService has a WAF policy that will reject the request when we set the `agent` header to "scammer"
```
curl -v -H "agent: scammer" http://api.example.com/httpbin/get
```
The request should be rejected.

Restart the gateway-proxy:
```
kubectl -n gloo-system rollout restart deployment gateway-proxy && kubectl -n gloo-system rollout status deploy/gateway-proxy
```

Notice that we can still access the route:

```
curl -v http://api.example.com/httpbin/get
```

Now, deploy the bad WAF configuration for our VirtualService:

```
kubectl apply -f virtualservices/api-example-com-vs-waf-problem-1.yaml 
```

The gateway-proxy logs will emit this error:

```
[2024-03-05 14:54:29.255][1][warning][config] [external/envoy/source/common/config/grpc_subscription_impl.cc:128] gRPC config for type.googleapis.com/envoy.config.route.v3.RouteConfiguration rejected: Rules error. File: <<reference missing or not informed>>. Line: 5. Column: 19.
```

Notice that we can still access the service:

```
curl -v http://api.example.com/httpbin/get
```

Now, restart the `gateway-proxy`. This will result in bad-config being server to Envoy, which means our routes are no longer accessible (404):

```
kubectl -n gloo-system rollout restart deployment gateway-proxy && kubectl -n gloo-system rollout status deploy/gateway-proxy
```

Try accessing the service, this will result in a 404:

```
curl -v http://api.example.com/httpbin/get
```

Apply the correct VirtualService again and notice that we can now access our service again:

```
kubectl apply -f virtualservices/api-example-com-vs.yaml
```

```
curl -v http://api.example.com/httpbin/get
```

The virtualservices `virtualservices/api-example-com-vs-waf-problem-2.yaml` and `virtualservices/api-example-com-vs-waf-problem-3.yaml` show different variations of the same problem. Simply apply these CRs and follow the same steps as we did earlier to demonstrate the problem (e.g. applying the CR and restarting the gateway-proxy).


## Conclusion
What happens is that Gloo Edge control plane does not catch any malformed/misconfigured WAF policies, resulting in the control plane sending bad configuration to Envoy. Envoy will not accept that configuration and will keep running the existing one, until you restart the gateway-proxy/Envoy. At that point, Envoy can no longer load a valid configuration, resulting in a full outage of all VirtualServices and Routes.
