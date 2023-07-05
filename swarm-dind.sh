#!/bin/bash

set -eo pipefail
shopt -s lastpipe

getCurrentContainerId() {
  cat /proc/self/mountinfo | grep "/docker/containers/" | head -1 | sed -E 's/.*?\/docker\/containers\/([^/]*?).*/\1/'
}

getContainerEnv() {
  local -n _vars="$1"
  local containerId="$2"
  local var
  docker container inspect --format '{{range .Config.Env}}{{println (json .)}}{{end}}' "$containerId" |
    head -n -1 |
    while IFS= read -r var; do
      _vars+=("$(echo "$var" | jq -r)")
    done
}

getContainerMounts() {
  local -n _mounts="$1"
  local containerId="$2"
  local mount
  docker container inspect --format '{{range .Mounts}}{{printf "%s:%s:%s\n" .Source .Destination (or (and .RW "rw") "ro")}}{{end}}' "$containerId" |
    head -n -1 |
    while IFS= read -r mount; do
      _mounts+=("$mount")
    done
}

if [[ "$1" == "" ]]; then
  echo "No dind image specified!" >&2
  false
fi

containerId="$(getCurrentContainerId)"

args=(-i --sig-proxy --rm --privileged --network="container:$containerId" --name "swarm-dind-$containerId")

vars=()
getContainerEnv vars "$containerId"
for var in "${vars[@]}"; do
  if [[ "$var" != "" ]] && [[ "$var" != DOCKER_HOST=* ]]; then
    args+=(-e "$var")
  fi
done

mounts=()
getContainerMounts mounts "$containerId"
for mount in "${mounts[@]}"; do
  if [[ "$mount" != *:/var/run/docker.sock:* ]]; then
    args+=(-v "$mount")
  fi
done

args+=("$@")

exec docker run "${args[@]}"
