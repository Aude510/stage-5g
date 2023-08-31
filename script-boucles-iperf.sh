#!/bin/bash

# function si le serveur en face répond return bool / int possible en bash?
					# echo $res et $(function) pour récupérer la valeur

# je suis en bash donc 0 = true et tout le reste = false on va dire

check_connect () { # $1 : adresse ip

# TODO

if [[ $(($(date +%s%3N)%2)) -eq 0 ]]; then # juste pour tester
	echo 0 # tout va bien
else
	echo 1 # pas cool
fi
}



get_ip () {
ip="localhost" # TODO
echo $ip
}


# udp
# tcp
# taille buffer (tcp only)
# BW


tailles=(2 4 8 16 32 64 128 256)
BW=(1M 2M 3M 4M 5M 6M 7M 8M 9M 10M 15M 20M 25M 30M)




# taille buffer tcp
for taille in "${tailles[@]}"
do
	done=1 # false
	while [[ $done -ne 0 ]]; do
		ip=$(get_ip)
		ok=$(check_connect $ip)
		if [[ $ok -eq 0 ]]; then
			#iperf3 -c $ip -l $taille -t 70
			echo "test TCP avec buffer de taille $taille KB"
			# TODO post annotation
			done=0
		else
			echo "serveur iperf down sur test TCP buffer $taille KB"
		fi
	done
done


# BW TCP
for bw in "${BW[@]}"
do
	done=1 # false
	while [[ $done -ne 0 ]]; do
		ip=$(get_ip)
		ok=$(check_connect $ip)
		if [[ $ok -eq 0 ]]; then
			# iperf3 -c $ip -b $bw -t 70
			echo "test TCP avec bande passante $bw Mbps"
			# TODO post annotation
			done=0
		else
			echo "serveur iperf down sur test TCP BW $bw Mbps"
		fi
	done
done

# BW UDP
for bw in "${BW[@]}"
do
	done=1 # false
	while [[ $done -ne 0 ]]; do
		ip=$(get_ip)
		ok=$(check_connect $ip)
		if [[ $ok -eq 0 ]]; then
			# iperf3 -c $ip -b $bw -t 70 -u
			echo "test UDP avec bande passante $bw Mbps"
			# TODO post annotation
			done=0
		else
			echo "serveur iperf down sur test UDP BW $bw Mbps"
		fi
	done
done

