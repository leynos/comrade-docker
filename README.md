# Docker amd Compose Files for Comrade

The Dockerfile can be used to create a repeatable deployment environment for the COMRADE canvasing suite.  The comrade-compose.yml file automatically loads supporting containers (database and nginx), and configures these to support a new instance of COMRADE.

## Building:

    docker build -t comrade .

## Running:

Using docker-compose:

(Coming soon)

## To Do

Incorporate database configuration into compose logic (i.e., this most likely won't do anything yet).

Actually get the whole shebang running.

## Dependencies

This docker file was tested with Docker 1.3.1, but should work with any newer version.

The compose file requires ```docker-compose``` which can be installed from [here](https://docs.docker.com/compose/install/).

I've so far done eveything using CentOS 7, but any 64-bit Linux distro supported by Docker will work.
