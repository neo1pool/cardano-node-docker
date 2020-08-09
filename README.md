# Docker image for cardano-node

[GitHub repo](https://github.com/neo1pool/cardano-node-docker)

This Docker image allows you to run `cardano-node` and `cardano-cli` executables.

The build process is done in two stages. The first stage prepares all the dependencies and builds the binaries. The final image just extracts few important files from the build image. For more details see the Dockerfile.

The default entrypoint is `cardano-node run`, but you can overwrite it with option `--entrypoint <x>`.

## Example usage

Consider the following directory structure:
```
 relay1
 ├── config
 │   ├── byron-genesis.json
 │   ├── config.json
 │   ├── shelley-genesis.json
 │   └── topology.json
 ├── db
 └── socket
```

You can start the relay node with:
```
# docker run -it --name cardano-node-relay1 \
    -v </host/path/to/relay1>:/data \
    -p <host_node_port>:3000 \
    -p <host_prometheus_port>:12798 \
    tstdin/cardano-node:1.18.0 \
    --topology /data/config/topology.json \
    --database-path /data/db \
    --socket-path /data/socket/node.socket \
    --host-addr 0.0.0.0 \
    --port 3000 \
    --config /data/config/config.json
```
