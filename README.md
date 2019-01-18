# Syncthing Docker Image for Raspberry Pi on ARMv7

This repository containes a Dockerfile to create an image of [Syncthing](https://syncthing.net) for Raspberry Pi on ARMv7.
The image is based on the official Syncthing ARMv7 build and is automatically updated by my Raspberry Pi and pushed to Docker Hub ([strobi/rpi-syncthing](https://cloud.docker.com/u/strobi/repository/docker/strobi/rpi-syncthing)).


## Build the image

To build the image using `docker` run:

```bash
# BUILD_VERSION determines which version of syncthing is used for the image
# BUILD_VERSION must be the tag name of the release on GitHub without `v`, e.g. `1.6.0`
BUILD_VERSION=$(curl -s https://api.github.com/repos/syncthing/syncthing/releases/latest | jq -r .tag_name )
BUILD_VERSION=${BUILD_VERSION:1}

# Build
docker build --no-cache --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg BUILD_VERSION=${LATEST_RELEASE} .
```


## Start the container

To start the container using `docker` run:

```bash
docker run -d -p 8384:8384 -p 22000:22000 -p 21027:21027 -v ~/syncthing/config:/syncthing/config -v ~/syncthing/data:/syncthing/data strobi/rpi-syncthing:latest
```

If you want to use `docker-compose` to manage the container, create a file named `docker-compose.yml` with the following content: 

```
version: '2'

networks:
  syncthing:
    external: false

services:
  syncthing:
    image: strobi/rpi-syncthing:latest
    restart: unless-stopped
    networks:
      - syncthing
    volumes:
      - /home/pi/syncthing/config:/syncthing/config
      - /home/pi/syncthing/data:/syncthing/data
    ports:
      - "8384:8384"
      - "22000:22000"
      - "21027:21027"
    environment:
      - GUI_USERNAME=syncthing
      - GUI_PASSWORD_PLAIN=**changeme**
```
