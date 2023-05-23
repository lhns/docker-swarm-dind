#!/bin/bash

set -eo pipefail
shopt -s lastpipe

getCurrentContainerId() {
  local cpuset
  cpuset="$(cat /proc/self/cpuset)"
  echo "${cpuset#/docker/}"
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

getContainerBindMounts() {
  local -n _binds="$1"
  local containerId="$2"
  local bind
  docker container inspect --format '{{range .Mounts}}{{if eq .Type "bind"}}{{printf "%s:%s:%s\n" .Source .Destination (or (and .RW "rw") "ro")}}{{end}}{{end}}' "$containerId" |
    head -n -1 |
    while IFS= read -r bind; do
      _binds+=("$bind")
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

binds=()
getContainerBindMounts binds "$containerId"
for bind in "${binds[@]}"; do
  if [[ "$bind" != *:/var/run/docker.sock:* ]]; then
    args+=(-v "$bind")
  fi
done

args+=("$@")

exec docker run "${args[@]}"
