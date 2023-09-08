#!/bin/bash


template='{"time":replace_time,"text":"replace_etat with replace_param","data":"return code : replace_code","tags":["replace_etat"]}'
token="glsa_AfJIfIUzA4SAc1gtKWR4I3DoAbp9cIGy_cb610202"
todays_date=$(date +%d-%m-%Hh%M)

touch $todays_date-annotations.json

echo "{}" > $todays_date-annotations.json

get_ip () {
	# grep logs oai-smf ; prendre la dernière ligne avec une adresse
	logs=$(mktemp)
	docker logs oai-smf > $logs 2>&1
	ip=$(cat $logs | grep "UE IPv4 Address" | tail -n 1 | grep -Po '(?:[0-9]{1,3}\.){3}[0-9]{1,3}') # regex d'adresse ip
	rm $logs
	echo $ip
}

test_connect () { # $1 : ip serveur iperf à tester
	# test connectivité
	timeout 10 docker exec oai-ext-dn ping "$1" -c 2 > /dev/null # rediriger l'output vers null sinon le code de retour il est pas content
	code=$?
	echo $code # echo return code of ping to ip
}


tailles=(2 4 8 16 32 64 128 256)
BW=(1M 2M 3M 4M 5M 6M 7M 8M 9M 10M 15M 20M 25M 30M)



# boucle sur la taille du buffer tcp
for taille in "${tailles[@]}"; do
	fini=1
	while [[ $fini -ne 0 ]]; do
		ip=$(get_ip)
		code=$(test_connect $ip)
		if [[ $code -eq 0 ]]; then # pas de problème
			echo "test de connexion réussi"
			echo "test TCP buffer $taille KB"
			debut=$(date +%s%3N)
			timeout 150 docker exec oai-ext-dn iperf3 -n 131M  -l $taille -p 5201 -c $ip
			return_code=$?
			#echo "return code : $return_code"
			#echo "début : $debut"
			fin=$(date +%s%3N)
			json=$(mktemp)
			#### post début ###
			echo $template | sed -e "s/replace_time/$debut/g" -e "s/replace_etat/trafic generation/g" -e "s/replace_param/TCP buffer $taille KB/g" -e "s/replace_code/$return_code/g" > $json
			cat $json
			curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
			#### post fin ###
			echo $template | sed -e "s/replace_time/$fin/g" -e "s/replace_param/TCP buffer $taille KB/g" -e "s/replace_etat/end of trafic/g" -e "s/replace_code/$return_code/g" > $json
			cat $json
			curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
			rm $json
			# add annotation to json for python script
			jq -c ".\"$(date -d @$((debut/1000)) +%R:%S)\" = \"tcp $taille KB\"" $todays_date-annotations.json > tmp.$$.json && mv tmp.$$.json $todays_date-annotations.json
			jq -c ".\"$(date -d @$((fin/1000)) +%R:%S)\" = \"fin tcp $taille KB\"" $todays_date-annotations.json > tmp.$$.json && mv tmp.$$.json $todays_date-annotations.json
			fini=0
		else
			echo "serveur iperf down test TCP buffer $taille KB"
		fi
	done
done



# boucle sur la BW TCP 
for bw in "${BW[@]}"; do
	fini=1
	while [[ $fini -ne 0 ]]; do
		ip=$(get_ip)
		code=$(test_connect $ip)
		if [[ $code -eq 0 ]]; then # pas de problème
			echo "test de connexion réussi"
			echo "test TCP BW $bw bps"
			debut=$(date +%s%3N)
			timeout 150 docker exec oai-ext-dn iperf3 -n 131M -b $bw -p 5201 -c $ip
			return_code=$?
			#echo "return code : $return_code"
			#echo "début : $debut"
			fin=$(date +%s%3N)
			json=$(mktemp)
			#### post début ###
			echo $template | sed -e "s/replace_time/$debut/g" -e "s/replace_etat/trafic generation/g" -e "s/replace_param/TCP BW $bw bps/g" -e "s/replace_code/$return_code/g" > $json
			cat $json
			curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
			#### post fin ###
			echo $template | sed -e "s/replace_time/$fin/g" -e "s/replace_etat/end of trafic/g" -e "s/replace_param/TCP BW $bw bps/g" -e "s/replace_code/$return_code/g" > $json
			cat $json
			curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
			rm $json
			# add annotation to json for python script
			jq -c ".\"$(date -d @$((debut/1000)) +%R:%S)\" = \"tcp $bw bps\"" $todays_date-annotations.json > tmp.$$.json && mv tmp.$$.json $todays_date-annotations.json
			jq -c ".\"$(date -d @$((fin/1000)) +%R:%S)\" = \"fin tcp $bw bps\"" $todays_date-annotations.json > tmp.$$.json && mv tmp.$$.json $todays_date-annotations.json
			fini=0
		else
			echo "serveur iperf down test TCP BW $bw bps"
		fi
	done
done




# boucle sur la bw udp
for bw in "${BW[@]}"; do
	fini=1
	while [[ $fini -ne 0 ]]; do
		ip=$(get_ip)
		code=$(test_connect $ip)
		if [[ $code -eq 0 ]]; then # pas de problème
			echo "test de connexion réussi"
			echo "test UDP BW $bw bps"
			debut=$(date +%s%3N)
			timeout 150 docker exec oai-ext-dn iperf3 -n 131M -u -b $bw -p 5201 -c $ip
			return_code=$?
			#echo "return code : $return_code"
			#echo "début : $debut"
			fin=$(date +%s%3N)
			json=$(mktemp)
			#### post début ###
			echo $template | sed -e "s/replace_time/$debut/g" -e "s/replace_etat/trafic generation/g" -e "s/replace_param/UDP BW $bw bps/g" -e "s/replace_code/$return_code/g" > $json
			cat $json
			curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
			#### post fin ###
			echo $template | sed -e "s/replace_time/$fin/g" -e "s/replace_param/UDP BW $bw bps/g" -e "s/replace_etat/end of trafic/g" -e "s/replace_code/$return_code/g" > $json
			cat $json
			curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
			rm $json
			# add annotation to json for python script
			jq -c ".\"$(date -d @$((debut/1000)) +%R:%S)\" = \"udp $bw bps\"" $todays_date-annotations.json > tmp.$$.json && mv tmp.$$.json $todays_date-annotations.json
			jq -c ".\"$(date -d @$((fin/1000)) +%R:%S)\" = \"fin udp $bw bps\"" $todays_date-annotations.json > tmp.$$.json && mv tmp.$$.json $todays_date-annotations.json
			fini=0
		else
			echo "serveur iperf down test UDP BW $bw bps"
		fi
	done
done

# checker code de retour du iperf?
# garder la date où je commence le traffic et poster une annotation grafana
# juste si c'est successful du coup?
