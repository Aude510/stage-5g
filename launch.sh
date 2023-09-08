#!/bin/bash

usrp=0
start_cn=0
stop_cn=0
start_gnb=0
help=0
ue=0
logs=0
logs_cn=0

# colored outputs 
BLUE='\033[0;34m'

print_help () {
	echo "Utilisation : "
	echo "-u : set up the server to use USRP (mandatory on reboot)"
	echo "-c <plmn> : start core network"
	echo "-s : stop core network"
	echo "-o : put core network logs in /tmp/core-network ; useful if core network is running and you want to check logs"
	echo "-e PLMN : start a user equipment on the server"
	echo "-g <plmn> : start gNB"
	echo "-l : used with -g, put gnb logs in /tmp/gNB.logs"
	echo "-h : print help"
	echo "PLMN values supported : "
	echo "20895 : France, Orange"
	echo "20899 : France, test"
	echo "00101 : test"
	echo "NB : this script's purpose is to help you to easily start the components of the platform;"
	echo "it is not designed to help you debug"
}

if [ $# -eq 0 ]; then
	let help=1
fi


while getopts 'uc:soeg:htl' OPTION; do 
	case "$OPTION" in 
		u)
		  let usrp=1
		  ;;
		c)
		  PLMN="$OPTARG"
		  let start_cn=1
		  ;;
		s)
		  let stop_cn=1
		  ;;
		o) 
		  let logs_cn=1
		  ;;
		e)
		  PLMN="$OPTARG"
		  let ue=1
		  ;;

		g)
		  PLMN="$OPTARG"
		  let start_gnb=1
		  ;;
		h)
	          let help=1
	          ;;
	        l)
	          let logs=1
	          ;;
	        ?)
	          let help=1
	          ;;
	esac
done


if [[ $help -eq 1 ]]
then 
	print_help
	exit 0
fi 


if [[ $stop_cn -eq 1 && $start_cn -eq 1 ]]
then 
	echo "error : you cannot start and stop the core in one command"
	exit 1
fi 

if [[ $usrp -eq 1 ]]
then 
	echo "configuring server to use USRP"
	echo "stopping NetworkManager"
	sudo systemctl stop NetworkManager
	echo "configuration of eno2 interface :" 
	sudo ifconfig eno2 192.168.40.10 # usrp sur 192.168.40.0/24
	sudo ifconfig eno2 mtu 9000 # câble 10G ethernet 
	ifconfig eno2
	echo "try uhd_find_devices --args addr=192.168.40.2 to find usrp"
	exit 0
fi

# starts gNB ; displays logs on the terminal or on /tmp
if [[ $start_gnb -eq 1 ]]
then
	check=0 # vérifier que la config existe
	let check=`ls /home/oai/5g-oai-platform/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/ | grep plmn$PLMN.conf -c`
	if [[ $check -ne 1 ]]; then
		echo "Please enter a supported PLMN"
		print_help
		exit 1
	fi
	echo "starting gnb with PLMN $PLMN, make sure the core network is started first with $PLMN"
	source /home/oai/5g-oai-platform/openairinterface5g/oaienv
	cd /home/oai/5g-oai-platform/openairinterface5g/cmake_targets/ran_build/build
	if [[ $logs -eq 1 ]] 
	then 
		echo "check /tmp/gNB.logs for gNB logs"
		sudo /home/oai/5g-oai-platform/openairinterface5g/cmake_targets/ran_build/build/nr-softmodem -E --sa -nokrnmod -O /home/oai/5g-oai-platform/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb1.sa.band78.fr1.106PRB.prs.usrpx310.plmn$PLMN.conf -d > /tmp/gNB.logs 2>&1 
	else
		sudo /home/oai/5g-oai-platform/openairinterface5g/cmake_targets/ran_build/build/nr-softmodem -E --sa -nokrnmod -O /home/oai/5g-oai-platform/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb1.sa.band78.fr1.106PRB.prs.usrpx310.plmn$PLMN.conf -d
	fi 
	exit 0
fi


# starts and checks core network, then runs on background 
if [[ $start_cn -eq 1 ]]
then 
	check=0 # vérifier que la config existe 
	let check=`ls /home/oai/5g-oai-platform/oai-cn5g-fed/docker-compose | grep plmn-$PLMN.yaml -c`
	if [[ $check -ne 1 ]]; then
		echo "Please enter a supported PLMN"
		print_help
		exit 1
	fi
	echo "Starting core network with PLMN $PLMN"
	cd /home/oai/5g-oai-platform/oai-cn5g-fed/docker-compose
	
	# the following has be adapted from core-network.py to support several PLMN 
	
    	echo -e '\033[0;34m Starting 5gcn components... Please wait\033[0m....'
    	# The assumption is that all services described in docker-compose files
    	# have explicit or built-in health checks.
    	let ct=`docker-compose -f docker-compose-basic-nrf-plmn-$PLMN.yaml config --services | wc -l`


        # When no capture, just deploy all at once.
        docker-compose -f docker-compose-basic-nrf-plmn-$PLMN.yaml up -d
     
     	
    	echo -e '\033[0;32m OAI 5G Core network started, checking the health status of the containers... takes few secs\033[0m....'

    	sleep 5
    	
    	for x in $(seq 1 50); do 
    		docker-compose -f docker-compose-basic-nrf-plmn-$PLMN.yaml ps -a > /tmp/output-docker-compose
    		let cnt=`cat /tmp/output-docker-compose | grep '(healthy)' -c`
    		if [[ $cnt -eq $ct ]]; then 
    			echo -e '\033[0;32m All components are healthy, please see below for more details\033[0m....'
    			cat /tmp/output-docker-compose
    			break 
    		fi 
      	done 
  	
  	if [[ $cnt -ne $ct ]]; then 
  		echo -e '\033[0;31m Core network is un-healthy, please see below for more details\033[0m....'
  		cat /tmp/output-docker-compose
  		exit 1
  	fi 
  	
  	
  	# checking configs 
  	
  	echo -e '\033[0;34m Checking if the containers are configured\033[0m....'
 
        echo -e '\033[0;34m Checking if AMF, SMF and UPF registered with nrf core network\033[0m....'
        let amf=`curl -s -X GET http://192.168.70.130/nnrf-nfm/v1/nf-instances?nf-type="AMF" | grep -o "192.168.70.132" -c`
   
        let smf=`curl -s -X GET http://192.168.70.130/nnrf-nfm/v1/nf-instances?nf-type="SMF" | grep -o "192.168.70.133" -c`

        let upf=`curl -s -X GET http://192.168.70.130/nnrf-nfm/v1/nf-instances?nf-type="UPF" | grep -o "192.168.70.134" -c`
       
  
        echo -e '\033[0;34m Checking if AUSF, UDM and UDR registered with nrf core network\033[0m....'
        let ausf=`curl -s -X GET http://192.168.70.130/nnrf-nfm/v1/nf-instances?nf-type="AUSF" | grep -o "192.168.70.138" -c`

        let udm=`curl -s -X GET http://192.168.70.130/nnrf-nfm/v1/nf-instances?nf-type="UDM" | grep -o "192.168.70.137" -c`

        let udr=`curl -s -X GET http://192.168.70.130/nnrf-nfm/v1/nf-instances?nf-type="UDR" | grep -o "192.168.70.136" -c`
        
        if [[ $amf+$smf+$upf+$ausf+$udm+$udr -ne 6 ]]; then
        	echo -e '\033[0;31m Registration problem with NRF, check the reason manually\033[0m....'
        else
        	echo -e '\033[0;32m AUSF, UDM, UDR, AMF, SMF and UPF are registered to NRF\033[0m....'
        fi  
        
	echo -e '\033[0;34m Checking if SMF is able to connect with UPF\033[0m....'
      	let logs1=`docker logs oai-smf 2>&1 | grep "Received N4 ASSOCIATION SETUP RESPONSE from an UPF" -c`
	let logs2=`docker logs oai-smf 2>&1 | grep "Node ID Type FQDN: oai-spgwu" -c`

      	if [[ $logs1 -eq 0 || $logs2 -eq 0 ]]; then 
        	echo -e '\033[0;31m UPF did not answer to N4 Association request from SMF\033[0m....'
        	exit 1
	else
        	echo -e '\033[0;32m UPF did answer to N4 Association request from SMF\033[0m....'
	fi 
	let logs3=`docker logs oai-smf 2>&1 | grep "PFCP HEARTBEAT PROCEDURE" -c`
        
	if [[ $logs3 -eq 0 ]]; then 
       	echo -e '\033[0;31m SMF is NOT receiving heartbeats from UPF\033[0m....'
		exit 1
	else
        	echo -e '\033[0;32m SMF is receiving heartbeats from UPF\033[0m....'
	fi 
	
	
        echo -e '\033[0;34m Checking if SMF is able to connect with UPF\033[0m....'
        let logs4=`docker logs oai-spgwu 2>&1 | grep "Received SX HEARTBEAT RESPONSE" -c`
        let logs5=`docker logs oai-spgwu 2>&1 | grep "Received SX HEARTBEAT REQUEST" -c`
        
        
        if [[ $logs4 -eq 0 && $logs5 -eq 0 ]]; then 
        	echo -e '\033[0;31m UPF is NOT receiving heartbeats from SMF\033[0m....'
        	exit 1
        else
        	echo -e '\033[0;32m UPF is receiving heartbeats from SMF\033[0m....'
        fi

    	exit 0
fi


# puts core network logs in /tmp/core-network
if [[ $logs_cn -eq 1 ]]
then 
	echo "check /tmp/core-network for logs"
	echo "this can take a few seconds"
	mkdir -p /tmp/core-network # create dir if not exists 
	# mysql logs 
	docker logs $(docker ps | grep mysql | awk '{print $NF;}') > /tmp/core-network/$(docker ps | grep mysql | awk '{print $NF;}').logs 2>&1

	# other oai logs (probably a better way to do this 
	list=`docker ps | grep oai | awk '{print $NF;}'`

	for container in $list; do
		docker logs $container > /tmp/core-network/$container.logs 2>&1
	done
	
	exit 0
fi

if [[ $stop_cn -eq 1 ]] 
then 
	echo "stoping core network..."
	docker stop $(docker ps | grep mysql | awk '{print $1;}') # stop mysql
	docker stop $(docker ps | grep oai | awk '{print $1;}') # stop other oai containers 
	echo "done"
	exit 0
fi


if [[ $ue -eq 1 ]]
then
	check=0
	let check=`ls /home/oai-5g-ue/5g-oai-platform/openairinterface5g/ci-scripts/conf_files | grep ue$PLMN- -c `
	if [[ $check -eq 0 ]]; then 
		echo "Please enter a supported PLMN"
		print_help
		exit 1
	fi
	# on slice sst 1 sd 1
	echo "Starting with PLMN $PLMN, please check that CN and gNB are started with $PLMN"
	source /home/oai-5g-ue/5g-oai-platform/openairinterface5g/oaienv
	cd /home/oai-5g-ue/5g-oai-platform/openairinterface5g/cmake_targets/ran_build/build
	if [[ $logs -eq 1 ]]
	then
		echo "check /tmp/ue.logs for UE logs"
		sudo /home/oai-5g-ue/5g-oai-platform/openairinterface5g/cmake_targets/ran_build/build/nr-uesoftmodem --usrp-args "addr=192.168.40.3" --nokrnmod --ue-fo-compensation --ue-rxgain 105 -r 106 --numerology 1 --band 78 -C 3319680000 --sa -E -O /home/oai-5g-ue/5g-oai-platform/openairinterface5g/ci-scripts/conf_files/ue$PLMN-1-1.sa.conf -d > /tmp/ue.logs 2>&1
	else
		sudo /home/oai-5g-ue/5g-oai-platform/openairinterface5g/cmake_targets/ran_build/build/nr-uesoftmodem --usrp-args "addr=192.168.40.3" --nokrnmod --ue-fo-compensation --ue-rxgain 105 -r 106 --numerology 1 --band 78 -C 3319680000 --sa -E -O /home/oai-5g-ue/5g-oai-platform/openairinterface5g/ci-scripts/conf_files/ue$PLMN-1-1.sa.conf -d
	fi
	exit 0
fi





if [[ $logs -eq 1 ]]
then
	print_help
	exit
fi
