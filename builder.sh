#!/bin/sh

# Dir of this script
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change into repo dir and pull
cd $REPO_DIR
git pull

# Create if necessary
touch ~/.syncthing-release

# Get veresion latest build and latest release
LATEST_RELEASE=$(curl -s https://api.github.com/repos/syncthing/syncthing/releases/latest | jq -r .tag_name )
LATEST_BUILD=$(cat ~/.syncthing-release)
#LATEST_BUILD=$(head -n 1 ~/.syncthing-release)

if [ "$LATEST_RELEASE" == "$LATEST_BUILD" ]; then
    echo "Latest version (${LATEST_RELEASE}) was already built."
    exit
fi

docker build -t "strobi/rpi-syncthing:latest" .

docker tag "strobi/rpi-syncthing:latest" "strobi/rpi-syncthing:${LATEST_RELEASE}"

docker push "strobi/rpi-syncthing:latest"
docker push "strobi/rpi-syncthing:${LATEST_RELEASE}"

echo $LATEST_RELEASE > ~/.syncthing-release
