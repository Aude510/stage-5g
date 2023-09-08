#!/bin/bash

if_ok=$(/usr/sbin/ifconfig | grep oaitun_ue1 -c)


echo "début"
echo "if_ok : $if_ok"
if [[ if_ok -eq 1 ]]; then
	echo "connexion 5g ok"
	regex='(?:[0-9]{1,3}\.){3}[0-9]{1,3}'
	ip=$(/usr/sbin/ifconfig | grep oaitun_ue1 -A 1 | grep -Po $regex | head -n 1) 
	echo "ip : $ip"
	# check si le serveur iperf sur cette ip a déjà été lancé 
	serv_ok=$(ps aux | grep "iperf3" -c)
	echo "serv_ok : $serv_ok"
	case $serv_ok in
		0) 
		  echo "ERROR problem with grep"
		  exit 
		  ;; 
		1) # juste le grep : restart le serveur 
		  echo "serveur iperf non présent, redémarrage"
		  iperf3 -s -B $ip
		  ;;
		2)
		  ip_ok=$(ps aux | grep "iperf3 -s -B $ip" -c)
		  echo "ip_ok : $ip_ok"
		  if  [[ ip_ok -eq 1 ]]; then # le serveur iperf a une autre ip que l'actuelle 
			pid=$(ps aux | grep "iperf3" -m 1 | awk '{print $2;}')
			kill $pid
			echo "mauvaise ip, redémarrage du serveur iperf"
			iperf3 -s -B $ip
		  else 
		  	echo "tout va bien"
		  fi
		  ;; 
		?) # tous les kills et redémarrer 
		  echo "plusieurs serveurs présent, kill et redémarrage..."
		  pids=$(ps aux | grep "iperf3" -m $((serv_ok-1)) | awk '{print $2;}')
		  for pid in $pids; do 
		  	kill $pid 
		  done
		  iperf3 -s -B $ip
		  ;;
	esac
fi
echo "fin"
