# Docker Container Usage

Start the container from [docker folder](./docker) is as simple as:

```sh
docker compose run -it --rm build-yocto-stm32mp257f-dk bash
```

Aou may want to login to the container from any other console:

```sh
docker exec -u $(id -u) -it docker-build-yocto-stm32mp257f-dk-<check the id with docker ps -a command> bash
```

In case of troubles you may delete the created continer or bring docker to orignal state by:

```sh
docker system prune -af
```

**ATTENTION:** The above command will DELETE all NON running images from your docker system!
