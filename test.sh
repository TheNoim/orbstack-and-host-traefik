#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -e
clean_up () {
    ARG=$?
    
    set +e

    # Unload launchctl service used to start traefik
    if [[ -f $HOME/Library/LaunchAgents/io.noim.traefik_orbstack_test.plist ]]; then
        launchctl list | grep io.noim&>/dev/null
        if [ $? -eq 0 ]; then
            launchctl unload $HOME/Library/LaunchAgents/io.noim.traefik_orbstack_test.plist
        fi

        rm $HOME/Library/LaunchAgents/io.noim.traefik_orbstack_test.plist
    fi

    docker compose -f $script_dir/deps/docker-compose.yaml -p traefik_test down

    kill $(jobs -p)

    exit $ARG
}

trap clean_up EXIT

# Make sure traefik is installed
if ! [ -x "$(command -v traefik)" ]; then
    echo "Traefik is not installed"
    echo "Install: brew install traefik"
    exit 1
fi
# Make sure jq is installed
if ! [ -x "$(command -v jq)" ]; then
    echo "jq is not installed"
    echo "Install: brew install jq"
    exit 1
fi

docker compose&>/dev/null

if [ ! $? -eq 0 ]; then
    echo "Please install orbstack and enable docker compose"
    exit 1
fi

# Start whoami container
docker compose -f $script_dir/deps/docker-compose.yaml -p traefik_test up --wait

traefik_path=$(which traefik)
traefik_config_path="$script_dir/deps/traefik.yaml"
echo "Traefik installed at $traefik_path"
echo "Traefik config located at $traefik_config_path"

service_template=$(cat <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>io.noim.traefik_orbstack_test</string>
        <key>ProgramArguments</key>
        <array>
            <string>$traefik_path</string>
            <string>--configfile=$traefik_config_path</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>/tmp/io.noim.traefik_orbstack_test.out</string>
        <key>StandardOutPath</key>
        <string>/tmp/io.noim.traefik_orbstack_test.out</string>
    </dict>
    </plist>
EOF
)

# Create launchctl service
touch $HOME/Library/LaunchAgents/io.noim.traefik_orbstack_test.plist
echo $service_template >> $HOME/Library/LaunchAgents/io.noim.traefik_orbstack_test.plist
echo "Service:"
cat $HOME/Library/LaunchAgents/io.noim.traefik_orbstack_test.plist

if [[ -f /tmp/io.noim.traefik_orbstack_test.out ]]; then
    rm /tmp/io.noim.traefik_orbstack_test.out
fi

launchctl load $HOME/Library/LaunchAgents/io.noim.traefik_orbstack_test.plist

# Fail if service isn't loaded
launchctl list | grep io.noim&>/dev/null

touch /tmp/io.noim.traefik_orbstack_test.out

tail -f /tmp/io.noim.traefik_orbstack_test.out &

traefik_is_ready () {
    local status=$(curl http://localhost:37308/api/http/services/whoami@docker | jq -r '.status')
    if [[ $status == 'enabled' ]]; then
        return 0
    else
        return 1
    fi
}

until traefik_is_ready
do
  echo "Wait for traefik to be ready"
  sleep 1
done

echo "Ready. Start test..."

curl -f http://localhost:53504

echo "If you see this, the connection is working"