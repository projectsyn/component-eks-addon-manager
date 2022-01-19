# ⚠️  Repo Archive Notice

As of Jan 19, 2022, this component will no longer be updated.

We recommend that you use the mechanisms provided by AWS to manage the EKS addons.
See the [EKS documentation](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html) for details.

See our [migration how-to](./docs/modules/ROOT/pages/how-tos/migrate-to-eks-add-ons.adoc) for instructions to migrate the EKS addons to be managed through Terraform.

# Commodore Component: eks-addon-manager

This is a [Commodore][commodore] Component to manage EKS addon versions.

EKS "addons" are components which are deployed when a cluster is initially installed (e.g.  kube-proxy and coredns) but which are not upgraded automatically when the EKS control plane is upgraded.

This component requires the [resource-locker-operator component] to manage the addon versions.

This repository is part of Project Syn.
For documentation on Project Syn and this component, see https://syn.tools.

## Documentation

Documentation for this component is written using [Asciidoc][asciidoc] and [Antora][antora].
It is located in the [docs/](docs) folder.
The [Divio documentation structure](https://documentation.divio.com/) is used to organize its content.

Run the `make docs-serve` command in the root of the project, and then browse to http://localhost:2020 to see a preview of the current state of the documentation.

After writing the documentation, please use the `make docs-vale` command and correct any warnings raised by the tool.

## Contributing and license

This library is licensed under [BSD-3-Clause](LICENSE).
For information about how to contribute see [CONTRIBUTING](CONTRIBUTING.md).

[commodore]: https://docs.syn.tools/commodore/index.html
[asciidoc]: https://asciidoctor.org/
[antora]: https://antora.org/
[resource-locker-operator component]: https://github.com/projectsyn/component-resource-locker
