# K3S, MetalLB and Docker Registry on Vagrant

This is a follow-up to my [Vagrant + MicroK8S](https://gist.github.com/JonTheNiceGuy/66f44e352352c24307bb5ca78c984793) 
environment, but re-based to use K3S instead of MicroK8S.

Aside from just the Vagrantfile, there are also two files in the Build directory which provide the 
[registry](Build/registry.yaml) and [configuration settings for subsequent machines](Build/use_pubip.sh).

This is something I'm using for my personal environment, so I'm unlikely to make any changes to the repo, aside from
what I'm using it for... but if you've got any improvement suggestions, feel free to raise a PR, create an incident
or just [email me](mailto:jon+K3sAndMetallb@sprig.gs).