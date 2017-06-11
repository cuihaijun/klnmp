#!/bin/bash

docker rm -f klnmp &> /dev/null

echo "start klnmp container..."

docker run -itd  \
                -p 80:80 \
                --name klnmp \
                --hostname klnmp \
                klnmp:1.0 /bin/sh &> /dev/null

docker exec -it klnmp bash
