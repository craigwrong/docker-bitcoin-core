# Dockerized `bitcoind` and `bitcoin-cli`

Note: For these examples we are using macOS as host even though the binaries are compiled for Linux (Docker). On Linux hosts replace `$HOME/Library/Application Support/Bitcoin` with `$HOME/.bitcoin` or wherever the data directory is.

To build all images from source.

    ./build

Sample `bitcoin.conf` file.

    daemon=0 # Keeps Docker container running.
    printtoconsole=0 # Rely on debug.log.
    testnet=1
    txindex=1
    disablewallet=1
    server=1
    rpcallowip=172.17.0.0/16
    [test]
    rpcbind=0.0.0.0

User `docker network inspect bridge` to get the IP subnetwork – in this case `172.17.0.0/16`.

To run a daemon.

    docker run --name bitcoind --rm -d -v "$HOME/Library/Application Support/Bitcoin":/root/.bitcoin bitcoind

Check the logs.

    open -a Console "$HOME/Library/Application Support/Bitcoin/testnet3/debug.log"

To stop the daemon.

    docker exec bitcoind kill 1

To connect using the CLI.

    docker run --rm -v "$HOME/Library/Application Support/Bitcoin/testnet3/.cookie":/root/.cookie bitcoin-cli -testnet -rpccookiefile=/root/.cookie -rpcconnect=172.17.0.2 -getinfo 

Use `docker inspect bitcoind | grep IPAddress` to get its IP address.
