#!/bin/bash

nb_proc=$(ps -ef | grep nr-uesoftmodem -c)

if [[ !(nb_proc -gt 1) ]]; then
	/home/oai-5g-ue/5g-oai-platform/launch.sh -e 00101 -l
fi
