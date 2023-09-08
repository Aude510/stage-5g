#!/bin/bash

nb_healthy=$(docker ps | grep -e oai -e mysql | grep "(healthy)" -c)

if [[ ($nb_healthy -ne 9) ]]; then # si les 9 containers ne sont pas healthy 
	/home/oai/5g-oai-platform/launch.sh -s # arrêter le coeur 
	/home/oai/5g-oai-platform/launch.sh -c 00101 # le relancer
	# si le gnb est allumé 
	if [[ $(ps aux | grep nr-softmodem -c) -gt 1 ]]; then
		pid=$(ps aux | grep nr-softmodem | head -n 1 | awk '{print $2;}') # arrêter le gnb 
		sudo kill $pid
	fi
	# relancer gnb 
	/home/oai/5g-oai-platform/launch.sh -g 00101 -l 
fi
