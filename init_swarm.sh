#!/bin/bash

set -e

docker-machine create -d google kv

docker $(docker-machine config kv) run \
    -d -p "8500:8500" \
    --name="consul" --restart "always" -h "consul" \
    progrium/consul -server -bootstrap

docker-machine create -d google --swarm --swarm-master \
    --swarm-discovery="consul://$(docker-machine ip kv):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip kv):8500" \
    --engine-opt="cluster-advertise=eth0:2376" \
    master

for i in {1..5}; do
  name=$(printf "%0.2d" $i)

  docker-machine create -d google --swarm \
      --swarm-discovery="consul://$(docker-machine ip kv):8500" \
      --engine-opt="cluster-store=consul://$(docker-machine ip kv):8500" \
      --engine-opt="cluster-advertise=eth0:2376" \
      $name
done

docker $(docker-machine config --swarm master) network create --driver overlay lab-net
