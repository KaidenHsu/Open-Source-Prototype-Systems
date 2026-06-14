FROM amansinhaatnycu/osp:latest

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    verilator yosys gtkwave make g++ python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir matplotlib pandas || true

WORKDIR /work
