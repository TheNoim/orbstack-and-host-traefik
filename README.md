### How to run

Just run `./test.sh`

### What this does

Starts [traefik](https://traefik.io) on the host (MacOS, not as container) and a [whoami](https://github.com/traefik/whoami) container in [orbstack](https://orbstack.dev). After starting both, it tries to connect to the [whoami](https://github.com/traefik/whoami) container via [traefik](https://traefik.io).