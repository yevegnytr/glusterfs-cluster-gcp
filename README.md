# glusterfs-cluster-gcp
A bootstrap script to setup a 3 node GlusterFS cluster on GCP.

This script will launch 3 compute instances each in separate AZs based on CentOS 7.5 and GlusterFS 3.12 (can be adjusted according to your needs).
On each node the script will launch a bash script for first time provision.
The idea behind this set of swcripts was to create a simplier and more modular solution from the one I found on the Internet before.

### How to use
* Clone the repo and edit `settings.conf`.
* Make sure that you are connected to the required account with `gcloud info` and fire the script.


Ideas and thoughts are always welcome.
