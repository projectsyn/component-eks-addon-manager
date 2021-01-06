local helper = import 'helper.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local resourcelocker = import 'lib/resource-locker.libjsonnet';

// Define kube-proxy target object as partial DaemonSet manifest.
local kubeproxy = kube.DaemonSet('kube-proxy') {
  metadata+: {
    namespace: 'kube-system',
  },
};

// Define coredns target object as partial Deployment manifest.
local coredns = kube.Deployment('coredns') {
  metadata+: {
    namespace: 'kube-system',
  },
};

local eks_cni = import 'eks-cni.jsonnet';

// Create ResourceLocker patches for kube-proxy and coredns.
{
  '10_kubeproxy_patch': resourcelocker.Patch(kubeproxy, helper.imgver_patch('kube-proxy')),
  '10_coredns_patch': resourcelocker.Patch(coredns, helper.imgver_patch('coredns')),
  '10_eks_cni_resources': eks_cni.resources,
}
