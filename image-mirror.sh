#!/bin/bash

MIRROR_REGISTRY=registry.clt.unnet.co.kr:5000

function mirror_image() {
### Image Mrirroring
  TRIM=${1#*/}
  oc image mirror -a ${LOCAL_SECRET_JSON} $1 ${MIRROR_REGISTRY}/${TRIM}
}

for i in $@
do
	mirror_image $i
done
