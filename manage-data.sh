#!/bin/bash -i


touch stats-connexion-$(date +%d-%m-%Hh%M).json

echo "{}" >> stats-connexion-$(date +%d-%m-%Hh%M).json
 

print_help () {
	echo "Utilisation : "
	echo "-d <date> : traite les données de <date> au format yyyy-mm-dd"
	echo "-a : traite toutes les données à ce jour"
	echo "-t : traite les données du jour"
	echo "-h : print help"
}

########################################## MOYENNE  #################################################


moyenne () { # $1 tableau avec les durées, $2 nb d'éléments 

tab=("$1")
sum=0
#echo ${tab[*]}
for i in $tab
do
	sum=$(($sum+$i))
done


moy=$(($sum / $2))
echo $(date -d "@$moy" +"%Mmin %Ss")

}



###########################################PRINT_DATA##################################################


print_data () { # $1 nombre de connexions, $2 tableau avec les durées, $3 nb d'éléments de $2, $4 optionnel date du jour 



case $# in 
	3)
	 echo "Nombre de connexions au $(date +%F) : $1"
	;;
	4) 
	 echo "Nombre de connexions le $4 : $1"
	;;
	?)
	 echo ERREUR
	;;
esac

echo "durée moyenne de connexion : $(moyenne "$2" $3)" 

}



#######################################TRAITER_ALL######################################################

traiter_all () {




logs=$(mktemp)



# récupération des logs de l'amf...
docker logs oai-amf > $logs 2>&1

# déconnexions 
deco=$(mktemp)
cat $logs -n | grep "Received UE_CONTEXT_RELEASE_COMPLETE message, handling" > $deco

# connexions 
conex=$(mktemp)
cat $logs -n | grep "has been registered to the network" > $conex

rm $logs

nb_conex=$(wc -l < $conex)

nb_deco=$(wc -l < $deco)

#echo $nb_conex
#echo $nb_deco

tours=0
durees_calculees=0
tab_durees=()



while read line_co; do
	index=$(echo $line_co | awk '{print $1;}')
	# premier mot de la première ligne du fichier 
	index_deco=$(head $deco -n 1 | awk '{print $1;}')
	echo "conexion $tours : $index"
#	echo "deconexion $tours : $index_deco"
	((tours++))
	# enlever les $tours premières lignes du fichier, prendre la première, et le premier mot (index)
	next_index=$(tail $conex -n $(($nb_conex-$tours)) | head -n 1 | awk '{print $1;}')
#	echo "next index : $next_index"
	if [[ $next_index -gt $index_deco ]];then # il y a bien eu une déconexion pour cette connexion (déconnexion avant la connexion suivante)
		# todo calcul durée 
		debut=$(echo $line_co | grep -Po '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}' )  
		fin=$(head $deco -n 1 | grep -Po '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}' )
		debut=$(date -d "$debut" +%s) 
		fin=$(date -d "$fin" +%s)
#		echo $debut
#		echo $fin
		echo "debut : $(date -d "@$debut" +"%Hh%Mmin %Ss")"
		echo "fin : $(date -d "@$fin" +"%Hh%Mmin %Ss")"
		duree=$((fin-debut))
		echo "durée : $duree s"
		echo "durée : $(date -d "@$duree" +"%Mmin %Ss")"
		if [[ $duree -lt 0 ]]; then 
			let duree=0
			((durees_calculees++))
		fi
		tab_durees[durees_calculees]=$duree
		((durees_calculees++))
		jq -c ".\"$(date -d @$((debut)) +%F-%R:%S)\" = \"$duree\"" stats-connexion-$(date +%d-%m-%Hh%M).json > tmp.$$.json && mv tmp.$$.json stats-connexion-$(date +%d-%m-%Hh%M).json
		######## on enlève cette ligne du fichier des déconnexions #####################
		old_deco=$deco
		deco=$(mktemp)
		tail $old_deco -n $(($nb_deco-$durees_calculees)) > $deco
		rm $old_deco
	else 
		echo "il n'y a pas eu de déconnexion pour la connexion $(($tours))"
	fi 
	
done < $conex

rm $conex 
rm $deco

#echo "${tab_durees[*]}"

print_data $nb_conex "${tab_durees[*]}" $durees_calculees $1 # passage du tableau en string 

}



###################################### TRAITER_DATE ########################################################
traiter_date () { # $1 date à traiter 

logs=$(mktemp)



# récupération des logs de l'amf...
docker logs oai-amf > $logs 2>&1

# déconnexions 
deco=$(mktemp)
cat $logs -n | grep "Received UE_CONTEXT_RELEASE_COMPLETE message, handling" | grep "$1" > $deco

# connexions 
conex=$(mktemp)
cat $logs -n | grep "has been registered to the network" | grep "$1" > $conex

rm $logs

nb_conex=$(wc -l < $conex)

nb_deco=$(wc -l < $deco)

#echo $nb_conex
#echo $nb_deco

tours=0
durees_calculees=0
tab_durees=()



while read line_co; do
	index=$(echo $line_co | awk '{print $1;}')
	# premier mot de la première ligne du fichier 
	index_deco=$(head $deco -n 1 | awk '{print $1;}')
	echo "conexion $tours : $index"
#	echo "deconexion $tours : $index_deco"
	((tours++))
	# enlever les $tours premières lignes du fichier, prendre la première, et le premier mot (index)
	next_index=$(tail $conex -n $(($nb_conex-$tours)) | head -n 1 | awk '{print $1;}')
#	echo "next index : $next_index"
	if [[ $next_index -gt $index_deco ]];then # il y a bien eu une déconexion pour cette connexion (déconnexion avant la connexion suivante)
		# todo calcul durée 
		debut=$(echo $line_co | grep -Po '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}' )  
		fin=$(head $deco -n 1 | grep -Po '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3}' )
		debut=$(date -d "$debut" +%s) 
		fin=$(date -d "$fin" +%s)
#		echo $debut
#		echo $fin
		echo "debut : $(date -d "@$debut" +"%Hh%Mmin %Ss")"
		echo "fin : $(date -d "@$fin" +"%Hh%Mmin %Ss")"
		duree=$((fin-debut))
		echo "durée : $duree s"
		echo "durée : $(date -d "@$duree" +"%Mmin %Ss")"
		if [[ $duree -lt 0 ]]; then 
			let duree=0
			((durees_calculees++))
		fi
		tab_durees[durees_calculees]=$duree
		((durees_calculees++))
		jq -c ".\"$(date -d @$((debut)) +%F-%R:%S)\" = \"$duree\"" stats-connexion-$(date +%d-%m-%Hh%M).json > tmp.$$.json && mv tmp.$$.json stats-connexion-$(date +%d-%m-%Hh%M).json
		######## on enlève cette ligne du fichier des déconnexions #####################
		old_deco=$deco
		deco=$(mktemp)
		tail $old_deco -n $(($nb_deco-$durees_calculees)) > $deco
		rm $old_deco
	else 
		echo "il n'y a pas eu de déconnexion pour la connexion $(($tours))"
	fi 
	
done < $conex

rm $conex 
rm $deco

#echo "${tab_durees[*]}"

print_data $nb_conex "${tab_durees[*]}" $durees_calculees $1 # passage du tableau en string 

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
		 	 traiter_date $DATE
		 	 exit
		  else
		  	echo "$DATE : mauvais format de date!"
		  	let help=1
		  fi
		  ;;
		a)
		  traiter_all
		  exit
		  ;;
		t)
		  DATE="$(date +%F)"
		  traiter_date $DATE
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





























