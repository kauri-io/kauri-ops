#!/bin/sh
env=${TARGET_ENV}
helm delete --purge kibana-${env}
