# Builds a Node-RED image that already has the Dashboard 2.0 nodes installed,
# so "Manage palette" is never needed and the setup is reproducible.
FROM nodered/node-red:latest

# package.json here lists the extra nodes to install into the userDir (/data).
COPY package.json /data/package.json

RUN cd /data && npm install --unsafe-perm --no-update-notifier --no-audit --progress=false
