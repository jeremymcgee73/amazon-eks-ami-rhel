#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

BUILD_IMAGE=public.ecr.aws/eks-distro-build-tooling/golang:1.22

sudo systemctl start containerd

sudo nerdctl run \
  --rm \
  --network host \
  --workdir /workdir \
  --volume $PROJECT_DIR:/workdir \
  $BUILD_IMAGE \
  make build

# cleanup build image and snapshots
sudo nerdctl rmi \
  --force \
  $BUILD_IMAGE \
  $(sudo nerdctl images -a | grep none | awk '{ print $3 }')

# move the nodeadm binary into bin folder
sudo chmod a+x $PROJECT_DIR/_bin/nodeadm
sudo mv $PROJECT_DIR/_bin/nodeadm /usr/bin/

# change SELinux context for nodeadm binary
sudo semanage fcontext -a -t bin_t "/usr/bin/nodeadm"
sudo restorecon -v /usr/bin/nodeadm

# enable nodeadm bootstrap systemd units
sudo systemctl enable nodeadm-config nodeadm-run