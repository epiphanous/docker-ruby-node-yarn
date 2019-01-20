#!/usr/bin/env bash

RUBY_VERSIONS="2.6 2.5 2.4"
NODE_VERSIONS="11 10 8 6"
YARN_VERSIONS=$(curl -sSL --compressed https://yarnpkg.com/latest-version)

# node release keys pulled from https://github.com/nodejs/node#release-team
NODE_KEYS=(
  0x4ED778F539E3634C779C87C6D7062848A1AB005C 
  0x71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 
  0x77984A986EBC2AA786BC0F66B01FBB92821C587A
  0x8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600
  0x94AE36675C464D64BAFA68DD7434390BDBE9B9C5
  0xA48C2BEE680E841632CD4E44F07496B3EB3C1762
  0xB9AE9905FFD7803F25714661B63B535A4C206CA9
  0xB9E2F5981AA6E0CD28160D9FF13993A75599653C
  0xC4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8
  0xDD8F2338BAE7501E3DD5AC78C273792F7D83545D
  0xFD3A5288F042B6850C66B31F09FE44734EB7990E
)
KEY_SERVER=hkp://na.pool.sks-keyservers.net:80

gen_keys() {
  for key in ${NODE_KEYS[@]}
  do
    echo "import node key $key"
    gpg --keyring '.gnupg/pubring.kbx' --no-default-keyring --keyserver ${KEY_SERVER} --recv-keys "$key"
  done
  echo "import yarn key"
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --keyring './.gnupg/pubring.kbx' --no-default-keyring --import
}

gen_env() {
  RUBY_VERSION=$1
  NODE_MAJOR=$2
  YARN_VERSION=$3
  TAG_VERSION=$4
  cat <<EOF;
  rny-${TAG_VERSION}:
    build:
      context: .
      args:
        RUBY_BASE: ruby:${RUBY_VERSION}
        NODE_MAJOR: ${NODE_MAJOR}
        YARN_VERSION: ${YARN_VERSION}
    image: nextdude/ruby-node-yarn:${TAG_VERSION}

EOF
}

normalize() {
  echo $1 | sed -e 's/\./_/g'
}

gen_tag() {
  echo $(normalize "${1}-${2}-${3}")
}

latest=1
{
  echo "version: '3'"
  echo
  echo "services:"
  for r in ${RUBY_VERSIONS}; do
    for n in ${NODE_VERSIONS}; do
      for y in ${YARN_VERSIONS}; do
        [ ${latest} = 1 ] && {
          latest=0
          gen_env $r $n $y latest
        }
        gen_env $r $n $y $(gen_tag $r $n $y)
      done
    done
  done
} > docker-compose.yml

[ "$1" = "--gen-keys" ] && gen_keys
