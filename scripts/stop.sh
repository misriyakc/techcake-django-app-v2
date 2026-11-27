#!/bin/bash
set -e

docker stop django-app || true
docker rm django-app || true
