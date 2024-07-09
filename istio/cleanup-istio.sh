export CTX_CLUSTER1=cluster-1
export CTX_CLUSTER2=cluster-2

istioctl uninstall --purge --context $CTX_CLUSTER1 --skip-confirmation
istioctl uninstall --purge --context $CTX_CLUSTER2 --skip-confirmation