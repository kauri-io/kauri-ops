#!/bin/sh
##

LOCATN=${WEST_EUROPE}
env=${TARGET_ENV}


helm delete --purge kafka-${env}
