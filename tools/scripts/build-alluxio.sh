#!/bin/bash

###########################################################################
################################# Usage ###################################
## options:                                                              ##
##   -t/--tarball=true/false, whether to build alluxio tarball           ##
##      optional, default: true                                          ##
##   -i/--image=true/false whether to build docker image                 ##
##      optional, default: true                                          ##
##   --local-alluxio=<absolute_path_to_your_alluxio_repostory>           ##
##      optional, default: alluxio submodule path                        ##
##   -p/--push=true/false whether to push docker image                   ##
##      optional, default: true                                          ##
###########################################################################

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/../..

build_tarball=true
build_image=true
local_alluxio=$DIR/../../alluxio
push_image=true

for i in "$@"; do
  case $i in
    -t=*|--tarball=*)
      build_tarball="${i#*=}"
    ;;
    -i=*|--image=*)
      build_image="${i#*=}"
    ;;
    --local-alluxio=*)
      local_alluxio="${i#*=}"
    ;;
    -p=*|--push=*)
      push_image="${i#*=}"
    ;;
    *)
      # unknown option
    ;;
  esac
done

mkdir -p .tmp/alluxio

alluxio_version=$(grep -m1 "<version>" ${local_alluxio}/pom.xml | awk -F'>|<' '{print $3}')

echo "alluxio_version: $alluxio_version"

########################################################################### 
# build alluxio tarball and extract
###########################################################################
cd $DIR/../..
if [ $build_tarball != "false" ]; then
  echo "building alluxio tarball"
  rm -rf .tmp/alluxio/* && \
    cd .tmp/alluxio && \
    ${local_alluxio}/dev/scripts/generate-tarballs single && \
    tar xf alluxio-"${alluxio_version}".tar.gz && \
    rm alluxio-"${alluxio_version}".tar.gz && \
  cd $DIR/../.. && \
    echo -e "\n\n\n"
else
  echo -e "skip building alluxio tarball\n\n\n"
fi

###########################################################################
# build alluxio client tarball
###########################################################################
cd $DIR/../..
cd .tmp/alluxio/alluxio-${alluxio_version}
cp ../../../deploy/env/alluxio-flex-volume.sh ./ && cp ../../../deploy/env/client/alluxio-* ./conf
cd ../
if git describe --exact-match --tags $(git rev-parse --short=7 HEAD); then
  tag=`git describe --exact-match --tags $(git rev-parse --short=7 HEAD)` && echo "$tag" > ./alluxio-${alluxio_version}/version && tar zcvf ${tag}.tar.gz ./alluxio-${alluxio_version}
else
  tag=`git rev-parse --short=7 HEAD` && echo "ava-alluxio-$tag" > ./alluxio-${alluxio_version}/version && tar zcvf ava-alluxio-${tag}.tar.gz ./alluxio-${alluxio_version}
fi
cd $DIR/../..

########################################################################### 
# build docker image
###########################################################################
cd $DIR/../..
if [ $build_image != "false" ]; then
  echo "building docker image"
  cp $DIR/docker-image/Dockerfile.alluxio $DIR/docker-image/entrypoint.sh .tmp/alluxio/
  cd $local_alluxio && alluxio_hash=`git rev-parse --short=7 HEAD` && cd -
  docker build -t alluxio:$alluxio_hash --build-arg ALLUXIO_VERSION="${alluxio_version}" -f .tmp/alluxio/Dockerfile.alluxio .tmp/alluxio
  if [ $push_image != "false" ]; then
    docker tag alluxio:$alluxio_hash reg-xs.qiniu.io/atlab/alluxio:$alluxio_hash
    docker push reg-xs.qiniu.io/atlab/alluxio:$alluxio_hash
  fi
  echo -e "\n\n\n"
else
  echo -e "skip building docker image\n\n\n"
fi
