local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local helper = import 'helper.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.eks_addon_manager;

// Define EKS CNI (aws-node) resources
local patch_cni_ds_image(objs) = [
  if obj.kind == 'DaemonSet' then
    // process all containers, only patch ones which use the aws-node image
    local containers = [
      helper.fix_registry_region(c)
      for c in obj.spec.template.spec.containers
    ];
    local init_containers = [
      helper.fix_registry_region(c)
      for c in obj.spec.template.spec.initContainers
    ];
    obj + {
      spec+: {
        template+: {
          spec+: {
            containers: containers,
            initContainers: init_containers,
          }
        }
      }
    }
  else
    obj
  for obj in objs
];

local eks_cni_objs = patch_cni_ds_image(
  std.prune(
    std.parseJson(
      kap.yaml_load_stream('eks-addon-manager/manifests/aws-k8s-cni.yaml')
    )
  )
);

local eks_cni_locker_sa = kube.ServiceAccount('eks-cni-manager') {
  metadata+: {
    namespace: params.namespace,
  },
};

// find ClusterRole object in EKS CNI manifests
local eks_cni_clusterrole = [
  obj for obj in eks_cni_objs if obj.kind == 'ClusterRole'
][0];

// apigroup extraction helper
local apigroup(obj) =
  local apigrp = std.split(obj.apiVersion, '/')[0];
  if apigrp == 'v1' then '' else apigrp;

// Extract RBAC rules for resource locker SA from EKS CNI objects and EKS CNI
// ClusterRole.
// We need to extract the rules from the ClusterRole as the
// service account is not allowed to create the ClusterRole if it doesn't have
// at least the same permissions as the ClusterRole to be created.
local kindresourcelist =
  [
    {
      // required RBAC permissions to create resources from EKS CNI manifests
      [apigroup(obj)]+: {
        resources+: [ std.asciiLower(obj.kind) + 's' ],
      },
    }
    for obj in eks_cni_objs
  ] + [
    // required RBAC permissions to create EKS CNI ClusterRole
    {
      [g]+: {
        resources+: rule.resources,
        verbs+: rule.verbs,
      } for g in rule.apiGroups
    }
    for rule in eks_cni_clusterrole.rules
  ];

// merge RBAC rules for matching api groups
// Note: the key+ syntax in kindresourcelist is mandatory for this fold to
// work.
local kindresources = std.foldl(
  function(prev, o) prev + o,
  kindresourcelist,
  {});

local eks_cni_locker_clusterrole =
  // ResourceLocker needs the following verbs to create&update resources
  // Note: we explicitly do not grant delete to the service account used by
  // resource-locker-operator. This ensures that the EKS CNI resources cannot
  // be deleted if the ResourceLocker object is deleted.
  local baseverbs = ['list', 'watch', 'create', 'get', 'update', 'patch'];
  // merge with potential other verbs for resources that are required due to
  // resourcelocker having to create a ClusterRole
  local groupverbs(g) = std.set(
    (if std.objectHas(g, 'verbs') then g.verbs else []) + baseverbs
  );

  kube.ClusterRole('eks-cni-manager') {
    rules+: [
      {
        apiGroups: [group],
        resources: kindresources[group].resources,
        verbs: groupverbs(kindresources[group]),
      } for group in std.objectFields(kindresources)
    ],
  };

local eks_cni_locker_clusterrolebinding =
  kube.ClusterRoleBinding('eks-cni-manager') {
    subjects_: [eks_cni_locker_sa],
    roleRef_: eks_cni_locker_clusterrole,
  };

local eks_cni_locker = [
  kube._Object('redhatcop.redhat.io/v1alpha1', 'ResourceLocker', 'eks-cni') {
    metadata+: {
      namespace: params.namespace,
      annotations+: {
        'argocd.argoproj.io/sync-options': 'SkipDryRunOnMissingResource=true',
      },
    },
    spec: {
      serviceAccountRef: {
        name: eks_cni_locker_sa.metadata.name,
      },
      resources: [{
        excludedPaths: [
          '.metadata',
          '.status',
          '.spec.replicas',
        ],
        object: obj,
        // sort by kind to ensure Roles are before RoleBindings
      } for obj in std.sort(eks_cni_objs, (function(o) o.kind)) ],
    },
  },
  eks_cni_locker_sa,
  eks_cni_locker_clusterrole,
  eks_cni_locker_clusterrolebinding,
];

{
  resources: eks_cni_locker,
}
