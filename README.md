# Évaluation du coût computationnel et énergétique de la softwarisation dans la 5G
Scripts réalisés au cours de mon stage au LAAS-CNRS du 12 juin 2023 au 15 septembre 2023. 

## Lancement de la plateforme et automatisation 

**- launch.sh**  Script en bash pour lancer la plateforme côté serveur et côté UE. Attention, l'option -e n'est pas disponible côté serveur et seules les options u, l et e sont disponibles côté UE. 
```
Utilisation :
-u : set up the server to use USRP (mandatory on reboot)
-c <plmn> : start core network
-s : stop core network
-o : put core network logs in /tmp/core-network ; useful if core network is running and you want to check logs
-e PLMN : start a user equipment on the server
-g <plmn> : start gNB
-l : used with -g, put gnb logs in /tmp/gNB.logs
-h : print help
PLMN values supported :
20895 : France, Orange
20899 : France, test
00101 : test
NB : this script's purpose is to help you to easily start the components of the platform;
it is not designed to help you debug
```

**- cn-auto.sh** Script en bash destiné à être lancé via crontab à intervalles réguliers _(root nécessaire)_. Relance le Core Network si il n'est pas fonctionnel, arrête et relance le gNB. 

**- gnb-auto.sh** Script en bash destiné à être lancé via crontab à intervalles réguliers _(root nécessaire)_. Relance le gNB si il ne tourne pas.  

**- ue-auto.sh** Script en bash destiné à être lancé via crontab à intervalles réguliers _(root nécessaire)_. Relance l'UE si il ne tourne pas.

**- iperf-auto.sh** Script en bash destiné à être lancé via crontab à intervalles réguliers. Relance un serveur iperf sur l'UE si il n'y en a pas déjà de présent. 
## Mesures de consommation 
### Scaphandre, Grafana 
**- post-to-grafana.sh** Script en bash pour poster les annotations correspondant aux connexions et déconnexions des UE sur le serveur Grafana, à partir des logs du Core Network. 
```
Utilisation :
-d <date> : poste les annotations de <date> au format yyyy-mm-dd
-a : poste toutes les annotations depuis le début des logs de l'AMF si elles n'y sont pas déjà
-t : poste les annotations du jour
-h : print help
```

**- manage-data.sh** Script en bash pour effectuer des statistiques sur les connexions des UE grâce aux logs du Core Network.  En l'état, calcule uniquement la moyenne. 
```
Utilisation :
-d <date> : traite les données de <date> au format yyyy-mm-dd
-a : traite toutes les données à ce jour
-t : traite les données du jour
-h : print help
```

**- generer-traffic.sh** Script en python pour générer du trafic du gnb vers l'UE avec iperf en testant divers paramètres. 

### Wattmètre 


**- treat-data.py** Script en Python pour générer des graphes à partir des fichiers csv générés par le wattmètre. 
```
usage: script [-h] [-f [FACTOR]] [-p [PRECISION]] [--hour1 [HOUR1]] [--hour2 [HOUR2]] [-a [ANNOTATIONS]] [-m] [-t [TITLE]] file

Script to plot wattmeter data

positional arguments:
  file                  datas (text file name)

options:
  -h, --help            show this help message and exit
  -f [FACTOR], --factor [FACTOR]
                        decimation factor to plot the datas faster; default 1 (no decimation)
  -p [PRECISION], --precision [PRECISION]
                        precision of hour display; 1=1x/minut, 10=1x/10min, -10=10x/minut; default 1
  --hour1 [HOUR1]       filter the file between specific hours; default none; format hh:mm
  --hour2 [HOUR2]       filter the file between specific hours; default none; format hh:mm
  -a [ANNOTATIONS], --annotations [ANNOTATIONS]
                        annotate an event : json file {"11:22:00":"some info","11:23:00":"more info"}
  -m, --average         calculates and display the average of the power
  -t [TITLE], --title [TITLE]
                        title of the graph

NB : one value every 300ms i.e. 200 / minut
```

**- stats.py** Script en python pour réaliser des moyennes, écart type, etc, à partir des fichiers csv générés par le wattmètre. 
```
usage: script [-h] [--hour1 [HOUR1]] [--hour2 [HOUR2]] file

Script to plot wattmeter data

positional arguments:
  file             datas (text file name)

options:
  -h, --help       show this help message and exit
  --hour1 [HOUR1]  filter the file between specific hours; default none; format hh:mm:ss
  --hour2 [HOUR2]  filter the file between specific hours; default none; format hh:mm:ss

NB : one value every 300ms i.e. 200 / minut
```




