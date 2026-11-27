#!/bin/bash
set -e

yum install -y docker
systemctl start docker
systemctl enable docker
