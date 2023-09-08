#!/bin/bash

nb_proc=$(ps -ef | grep nr-softmodem -c) 

if [[ !(nb_proc -gt 1) ]]; then # -gt = greater than; ! = négatif 
	/home/oai/5g-oai-platform/launch.sh -g 00101 -l 	
fi
