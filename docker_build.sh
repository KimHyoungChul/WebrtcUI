#!/bin/bash

docker build --tag=phemium-videocall-plugin .

docker run \
--rm \
-v $PWD:/project \
-v /cache-bower:/root/.cache/bower/ \
phemium-videocall-plugin \
sh -c "cd /project && \
       npm install && \
       gulp jenkins_app && \
       gulp release:plugin"
