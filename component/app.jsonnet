local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.eks_addon_manager;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('eks-addon-manager', params.namespace) + {
  spec+: {
    syncPolicy+: {
      automated+: {
        prune: false,
      },
    },
  },
};

{
  'eks-addon-manager': app,
}
