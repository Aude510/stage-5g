#!/bin/bash -i


template='{"time":replace_time,"text":"replace_etat of UE replace_imsi","tags":["replace_etat","replace_imsi"]}'


print_help () {
	echo "Utilisation : "
	echo "-d <date> : poste les annotations de <date> au format yyyy-mm-dd"
	echo "-a : poste toutes les annotations depuis le début des logs de l'AMF si elles n'y sont pas déjà"
	echo "-t : poste les annotations du jour"
	echo "-h : print help"
}

#######################################POST_ALL######################################################"

post_all () {

echo "post de toutes les connexions et déconnexions à ce jour"

logs=$(mktemp)


# récupération des logs de l'amf...
docker logs oai-amf > $logs 2>&1

# déconnexions 
deco=$(mktemp)
cat $logs | grep "Received UE_CONTEXT_RELEASE_COMPLETE message, handling" > $deco

# connexions 
conex=$(mktemp)
cat $logs | grep "has been registered to the network" > $conex

rm $logs

# parsing connexions 
while read line; do
	json=$(mktemp)
	date=$(date -d "$(echo $line | grep -Po '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}')" +%s%3N)
	etat="connection"
	imsi=$(echo $line | grep -Po '0010100000000..')
	echo $template | sed -e "s/replace_time/$date/g" -e "s/replace_etat/$etat/g" -e "s/replace_imsi/$imsi/g" > $json	
	# get le time pour voir si elle y est déjà et ne pas la reposter le cas échéant 

	request=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $token" http://localhost:3000/api/annotations 2>/dev/null | grep -Poc "$date")
	if [ $request -eq 0 ]; then # si l'annotation n'y est pas déjà, poster 
		curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
	fi
	rm $json
done < $conex
rm $conex

# parsing deconnexions : pas d'imsi sur la ligne de log  
while read line; do
	json=$(mktemp)
	date=$(date -d "$(echo $line | grep -Po '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}')" +%s%3N)
	etat="deconnection"
	imsi=$(echo $line | grep -Po '0010100000000..')
	echo $template | sed -e "s/replace_time/$date/g" -e "s/replace_etat/$etat/g" -e "s/replace_imsi/$imsi/g" > $json	
	# get le time pour voir si elle y est déjà et ne pas la reposter le cas échéant 
	request=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $token" http://localhost:3000/api/annotations 2>/dev/null | grep -Poc "$date")
	if [ $request -eq 0 ]; then # si l'annotation n'y est pas déjà, poster 
		curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
	fi
	rm $json
done < $deco
rm $deco

}



#######################################POST_DATE#################################################################

post_date () { # $1 date à sélectionner, basiquement un copier coller de post_all avec un grep en plus mais flemme 

echo "post des connexions et déconnexions du $1" 

logs=$(mktemp)


# récupération des logs de l'amf...
docker logs oai-amf > $logs 2>&1

# déconnexions 
deco=$(mktemp)
cat $logs | grep "Received UE_CONTEXT_RELEASE_COMPLETE message, handling" | grep "$1"> $deco
# connexions 
conex=$(mktemp)
cat $logs | grep "has been registered to the network" | grep "$1" > $conex
rm $logs

# parsing connexions 
while read line; do
	json=$(mktemp)
	date=$(date -d "$(echo $line | grep -Po '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}')" +%s%3N)
	etat="connection"
	imsi=$(echo $line | grep -Po '0010100000000..')
	echo $template | sed -e "s/replace_time/$date/g" -e "s/replace_etat/$etat/g" -e "s/replace_imsi/$imsi/g" > $json	
	# get le time pour voir si elle y est déjà et ne pas la reposter le cas échéant 
	poubelle=$(mktemp) #sinon curl imprime des stats 
	request=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $token" http://localhost:3000/api/annotations 2>$poubelle | grep -Poc "$date")
	rm $poubelle
	if [ $request -eq 0 ]; then # si l'annotation n'y est pas déjà, poster 
		curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
	fi
	rm $json
done < $conex
rm $conex

# parsing deconnexions : pas d'imsi sur la ligne de log  
while read line; do
	json=$(mktemp)
	date=$(date -d "$(echo $line | grep -Po '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}')" +%s%3N)
	etat="deconnection"
	imsi=$(echo $line | grep -Po '0010100000000..')
	echo $template | sed -e "s/replace_time/$date/g" -e "s/replace_etat/$etat/g" -e "s/replace_imsi/$imsi/g" > $json	
	# get le time pour voir si elle y est déjà et ne pas la reposter le cas échéant 
	poubelle=$(mktemp) #sinon curl imprime des stats 
	request=$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $token" http://localhost:3000/api/annotations 2>$poubelle | grep -Poc "$date")
	rm $poubelle
	if [ $request -eq 0 ]; then # si l'annotation n'y est pas déjà, poster 
		curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $token" --data "@$json" http://localhost:3000/api/annotations
	fi
	rm $json
done < $deco
rm $deco




}

 #######################################SCRIPT###############################################################""


help=0

if [ $# -eq 0 ]; then
	let help=1
fi


while getopts 'd:ath' OPTION; do 
	case "$OPTION" in 
		d)
		  DATE="$OPTARG"
		  if [[ "$DATE" =~ ^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$ ]]; then # regex de date trouvée sur internet 
		 	 post_date $DATE
		 	 exit
		  else
		  	echo "$DATE : mauvais format de date!"
		  	let help=1
		  fi
		  ;;
		a)
		  post_all
		  exit
		  ;;
		t)
		  DATE="$(date +%F)"
		  post_date $DATE
		  exit
		  ;;
		h) 
		  let help=1
		  ;;
	        ?)
	          let help=1
	          ;;
	esac
done


if [ $help -eq 1 ]; then 
	print_help
	exit
fi 





























