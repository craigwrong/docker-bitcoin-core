# Dockerized `bitcoind` and `bitcoin-cli`

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

To run a daemon.

    docker run --name bitcoind --rm -d -v "$HOME/Library/Application Support/Bitcoin":/root/.bitcoin bitcoin:daemon

To stop the daemon.

    docker exec bitcoind kill 1

To connect using the CLI.

    docker run --rm -v $HOME/.bitcoin/testnet3/.cookie:/root/.cookie bitcoin:cli -testnet -rpccookiefile=/root/.cookie -rpcconnect=172.17.0.2 -getinfo 
