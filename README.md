# migration
docker run -d -p 8100:8100 --restart=unless-stopped -e skstkn=compose --name skopos -v /var/run/docker.sock:/var/run/docker.sock opsani/skopos:edge
