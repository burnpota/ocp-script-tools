#!/bin/bash

MIRROR_REGISTRY=registry.clt.unnet.co.kr:5000

function verifying_name() {

CHECK_NAME=$(oc -n openshift get is $1 --no-headers | awk '{print $1}')

if [ $CHECK_NAME != $1 ]
then
 echo "[ERROR] $1 is not a imagestream name"
 exit 1
fi
}

function get_image() {

IMAGELIST+=($(oc -n openshift get is $1 -o jsonpath='{.spec.tags[?(@.from.kind=="DockerImage")].from.name}'))

}

function mirror_image() {
### Image Mrirroring
for j in ${IMAGELIST[@]}
do
  TRIM=${j#*/}
#  oc image mirror -a ${LOCAL_SECRET_JSON} $j ${MIRROR_REGISTRY}/${TRIM}

  ADDR_ORI=${j%%/*}
  REGISTRY_ORI_ARR+=($ADDR_ORI)
done
}

function add_imagecontentsourcepolicy() {

IS_RESOURCE_INDEX=$(oc get imagecontentsourcepolicies.operator.openshift.io | grep redhat-imagesteam | wc -l)

cat > /tmp/icsp-$1.yaml << EOF
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: redhat-imagestream-${IS_RESOURCE_INDEX}
spec:
  repositoryDigestMirrors:
EOF

for j in ${IMAGELIST[@]}
do
  TRIM_ORI=${j%%:*}
  TRIM=${j#*/}
  TRIM_NOT_TAG=${j%%:*}
echo "  - mirrors:
    - ${MIRROR_REGISTRY}/${TRIM_NOT_TAG}
    source: ${TRIM_ORI}" >> /tmp/icsp-$1.yaml
done

oc apply -f /tmp/icsp-$1.yaml
}

function edit_imagestream() {
### Editing ImageStream Resource 
REGISTRY_ARR=($(echo ${REGISTRY_ORI_ARR[@]} | tr ' ' '\n' | sort -u))
for j in ${REGISTRY_ARR}
do
	oc -n openshift get is $1 -o yaml | sed 's/'$j'/'$MIRROR_REGISTRY'/g' | oc apply -f -
done

}


for i in $@
do
	verifying_name $i
done

for i in $@
do
	get_image $i
	mirror_image $i
#	add_imagecontentsourcepolicy $i
	edit_imagestream $i
	unset IMAGELIST
done




