### How to run

Just run `./test.sh`

### What this does

Starts [traefik](https://traefik.io) on the host (MacOS, not as container and via launchctl) and a [whoami](https://github.com/traefik/whoami) container in [orbstack](https://orbstack.dev). After starting both, the script tries to connect to the [whoami](https://github.com/traefik/whoami) container via [traefik](https://traefik.io).

### Why

[Softwares written in go have issues connecting to containers when launched via launchd](https://github.com/orbstack/orbstack/issues/1680)