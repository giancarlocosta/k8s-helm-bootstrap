# Kubernetes Cluster Bootstrap Helm Chart

> Helm chart to bootstrap a cluster with various resources, tools, etc.

## Usage

**The intended use of this chart is to use it for templating only, using
`helm template`, and then use those populated templates in your `kubectl apply`
command, since Helm doesn't manage some non-namespaced Kubernetes resources like
storageclasses well.**

```

# Populate templates
helm2.9.0 template . --values=your-custom-bootstrap-values.yaml \
--set dockerRegistry.REGISTRY_STORAGE_S3_ACCESSKEY=${REGISTRY_STORAGE_S3_ACCESSKEY} \
--set dockerRegistry.REGISTRY_STORAGE_S3_SECRETKEY=${REGISTRY_STORAGE_S3_SECRETKEY} \
--set dockerRegistry.REGISTRY_STORAGE_S3_BUCKET=${REGISTRY_STORAGE_S3_BUCKET} \
--set dockerRegistry.REGISTRY_HTTP_SECRET=${REGISTRY_HTTP_SECRET} \
--set snapEbs.EBS_SNAP_PASSWORD_ACCESSKEY=${EBS_SNAP_PASSWORD_ACCESSKEY} \
--set snapEbs.EBS_SNAP_PASSWORD_SECRETKEY=${EBS_SNAP_PASSWORD_SECRETKEY} \
--set nodelabel.PROD_READONLY_SA_AWS_DEFAULT_REGION=${PROD_READONLY_SA_AWS_DEFAULT_REGION} \
--set nodelabel.PROD_READONLY_SA_AWS_ACCESS_KEY_ID=${PROD_READONLY_SA_AWS_ACCESS_KEY_ID} \
--set nodelabel.PROD_READONLY_SA_AWS_SECRET_ACCESS_KEY=${PROD_READONLY_SA_AWS_SECRET_ACCESS_KEY} \
> /tmp/populated-bootstrap-templates.yaml

#  Review specs
cat /tmp/populated-bootstrap-templates.yaml

# If specs look good, apply them
${KUBE_COMMAND} apply -f /tmp/populated-bootstrap-templates.yaml
```
