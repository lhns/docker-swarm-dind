#!/bin/bash

set -eo pipefail

getCurrentContainerId() {
  local cpuset
  cpuset="$(cat /proc/self/cpuset)"
  echo "${cpuset#/docker/}"
}

getContainerEnv() {
  local -n _vars="$1"
  local containerId="$2"
  while IFS= read -r var; do
    _vars+=("$(echo "$var" | jq -r)")
  done < <(
    docker container inspect --format '{{range .Config.Env}}{{println (json .)}}{{end}}' "$containerId"
  )
}

getContainerLabels() {
  local -n _labels="$1"
  local containerId="$2"
  while IFS= read -r label; do
    _labels+=("$(echo "$label" | jq -r)")
  done < <(
    docker container inspect --format '{{range $k,$v:=.Config.Labels}}{{println (json (printf "%s=%s" $k $v))}}{{end}}' "$containerId"
  )
}

containerId="$(getCurrentContainerId)"

args=(--ti --rm --privileged --network="container:$containerId")

vars=()
getContainerEnv vars "$containerId"
for var in "${vars[@]}"; do
  args+=(-e "$var")
done

labels=()
getContainerLabels labels "$containerId"
for label in "${labels[@]}"; do
  if [[ "$label" = com.docker.stack.* ]] || [[ "$label" = com.docker.swarm.* ]]; then
    args+=(-l "$label")
  fi
done

args+=("$@")

exec docker run "${args[@]}"
