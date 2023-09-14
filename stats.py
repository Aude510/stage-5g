import argparse
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import re
import json




def find_index1(heure1: str, times: [str]) -> int: # hh:mm
    index1=-1
    if heure1:
        regex1=heure1+',\d{3}'
        for (heure, index) in zip(times, range(len(times))):
            if re.search(regex1,heure):
                index1=index
                break
    return index1 

def find_index2(index1: int, heure2: str, times: [str]) -> int:
    index2=-1
    debut=0
    if index1>0: # index 1 n'est ni -1 (pas trouvé) ni 0 (inutile)
        debut=index1+1 # le +1 pour éviter de repasser par index1 

    if heure2:
        regex2=heure2+',\d{3}'
        for (heure, index) in zip(times[debut:], range(debut,len(times))): 
            if re.search(regex2,heure):
                index2=index
                break
    return index2

def get_indexes(heure1: str, heure2:str, times: [str]) -> (int, int): 
    # return index de heure1 dans times, index de heure2 dans times
    # regex heure \d{2}:\d{2}:\d{2},\d{3} si jamais 
    # re.search(pattern,string-to-search)
    index1=find_index1(heure1,times)
    index2=find_index2(index1,heure2,times)
    return (index1,index2)


parser = argparse.ArgumentParser(prog='script', 
                                    description='Script to plot wattmeter data',
                                    epilog='NB : one value every 300ms i.e. 200 / minut')

    # Required positional argument

parser.add_argument('file', type=str,
                        help='datas (text file name)')

    
parser.add_argument('--hour1', type=str, nargs='?', const=None, default=None,
                        help='filter the file between specific hours; default none; format hh:mm:ss')


parser.add_argument('--hour2', type=str, nargs='?', const=None, default=None,
                        help='filter the file between specific hours; default none; hh:mm:ss')
    
parser.add_argument('-e','--minimum', type=float, nargs='?', const=None, default=None,
                        help='remove all points below the minimum')

parser.add_argument('-t','--maximum', type=float, nargs='?', const=None, default=None,
                        help='remove all points above the maximum')


args = parser.parse_args()


fichier=args.file

heure1=args.hour1
heure2=args.hour2
print("hour 1 : %s" % heure1)
print("hour 2 : %s" % heure2)

minimum=args.minimum
maximum=args.maximum

data = pd.read_csv(fichier,sep='\t')
times=data['Time']
powers=data['P']
    
print("number of points in the file : %d" % len(times))

(index1,index2)=get_indexes(heure1,heure2,times) 
if index1!=-1:
    debut=index1
else:
    debut=0
if index2!=-1:
    fin=index2
else:
    fin=len(times)

print("index1 : %d" % index1) 
print("begin at index : %d" % debut)
print("index2 : %d" % index2)
print("end at index : %d" % fin)
print("nombre total de points : %d" % (fin-debut))
indexes=list(range(debut,fin))

powers=[powers[x] for x in indexes]

powers=[float(s.replace(',','.')) for s in powers]

if minimum :
    points=[]
    for p in powers:
        if p > minimum:
            points.append(p)     
    if points:
        moyenne=sum(points)/len(points)
        print("La moyenne des points au dessus de {0} sur le fichier {1} est {2}".format(minimum,fichier,moyenne)) 
        ecart_type=np.std(points)
        print("il y a {0} points au dessus de {1}".format(len(points),minimum))
        print("l'écart type est %.2f" % ecart_type)
    else:
        print("hélas, il n'y a pas de points supérieurs à {0} dans le fichier {1}".format(minimum,fichier))
elif maximum:
    points=[]
    for p in powers:
        if p <= maximum:
            points.append(p)     
    if points:
        moyenne=sum(points)/len(points)
        print("La moyenne des points en dessous de {0} sur le fichier {1} est {2}".format(maximum,fichier,moyenne)) 
        ecart_type=np.std(points)
        print("il y a {0} points en dessous de {1}".format(len(points),maximum))
        print("l'écart type est %.2f" % ecart_type)
    else:
        print("hélas, il n'y a pas de points inférieurs à {0} dans le fichier {1}".format(maximum,fichier))
else:
    moyenne=sum(powers)/len(powers)
    print("La moyenne sur le fichier {0} entre {1} et {2} est {3}W".format(fichier,debut,fin,moyenne)) 
    ecart_type=np.std(powers)
    print("l'écart type est %.2f" % ecart_type)