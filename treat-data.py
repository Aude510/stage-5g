import argparse
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import re
import json


def find_index(heure: str, times: [str]) -> int: # hh:mm:ss
    res=-1
    regex=heure+',\d{3}'
    #print("debug: regex : %s" % regex)
    for (heure, index) in zip(times, range(len(times))):
     #   print("debug: heure : %s" % heure)
        if re.search(regex,heure):
            res=index
      #      print("debug: index : %d " % res)
            break
    return res


def find_index1(heure1: str, times: [str]) -> int: # hh:mm
    index1=-1
    if index1!='None':
        regex1=heure1+':\d{2},\d{3}'
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

    if heure2!='None':
        regex2=heure2+':\d{2},\d{3}'
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

def test_get_indexes():
    data = pd.read_csv('24-08-gnb.txt',sep='\t')
    times=data['Time']
    print("get 11:22 et 11:25 ; 104 et 703")
    (index1,index2)=get_indexes("11:22","11:25",times)
    print(index1)
    print(index2)
    print("get 13:00 et 'None'; 19657 et -1")
    (index1,index2)=get_indexes("13:00","None",times)
    print(index1)
    print(index2)
    print("get None et 13:00 ; -1 et 19657")    
    (index1,index2)=get_indexes("None","13:00",times)
    print(index1)
    print(index2)
    print("get None et None ; -1 et -1")
    (index1,index2)=get_indexes("None","None",times)
    print(index1)
    print(index2)

def traiter_fichier(fichier: str, factor: int, heure1:str, heure2:str) -> ([str],[int]):
    data = pd.read_csv(fichier,sep='\t')


    dates=data['Date']
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

    #if fin<debut:
      #  print("error fin après début choisir d'autres heures")
     #   return

    print("decimation factor : %d" % factor)
    indexes=list(range(debut,fin,factor))

    times=[times[x] for x in indexes]
    powers=[powers[x] for x in indexes]

    print("number of points after decimation : %d" % len(times))

    x=list(times)
    y=[float(s.replace(',','.')) for s in powers]

    return (x,y)


def plot(x:[str],y:[int],labels:[str],factor_labels:int,factor:int,annotations_file:str, title:str):

    
    ############## plot  ################################

    plt.plot(x, y, color = '#34536f', linestyle = 'dashed', marker = '.', label = "données wattmètre")

    if annotations_file:
        truc=open(annotations_file)
        dict_ann=json.load(truc)
        for heure in dict_ann: 
            message=dict_ann[heure]
            index=find_index(heure,x)
            if index!=-1:
                plt.annotate(message,(x[index],y[index]),
                            arrowprops=dict(facecolor='black', shrink=0.05))
                print("annotation " + heure + ": " + message)
            else:
                print("the following hour could not be annotate: %s" % heure+":"+message)

    plt.xticks(np.arange(0, len(x), step=factor_labels),labels) 


    plt.xticks(rotation = 25)
    plt.ylabel('power(W)')
    if title:
        plt.title(title)
    else:
        ech_mesures=factor*300 # précision des mesures puisqu'on a décimé de factor les mesures 
                                    # toutes les 300ms à la base
        plt.title('Power measured with the wattmeter, sampling every %dms' % ech_mesures)
    
    plt.show() 

def test_plot():
    x=['11:22:22,000','11:23:23,000','11:24:24,000']
    y=[1,3,2]
    factor_labels=2
    labels=[x[i] for i in range(0,len(x),factor_labels)]
    #annotations=["11:23:32,coucou"]
    annotations=""
    plot(x,y,labels,factor_labels,1,annotations)

def moyenne(powers:[int]) -> float:
    return sum(powers)/len(powers)


def test_traiter_fichier():
    traiter_fichier('gnb.csv',1,'11:22','11:25')
    print("\n")
    traiter_fichier('gnb.csv',100,'11:22','11:25')
    print("\n")
    traiter_fichier('gnb.csv',1,'13:00','None')
    print("\n")
    traiter_fichier('gnb.csv',100,'13:00','None')
    print("\n")
    traiter_fichier('gnb.csv',1,'None','13:00')
    print("\n")
    traiter_fichier('gnb.csv',100,'None','13:00')
    print("\n")
    traiter_fichier('gnb.csv',1,'None','None')
    print("\n")
    traiter_fichier('gnb.csv',100,'None','None')
    print("\n")
    traiter_fichier('gnb.csv',100,'13:00','11:24')
    print("\n")


def parser_et_run():

    parser = argparse.ArgumentParser(prog='script', 
                                    description='Script to plot wattmeter data',
                                    epilog='NB : one value every 300ms i.e. 200 / minut')

    # Required positional argument

    parser.add_argument('file', type=str,
                        help='datas (text file name)')

    parser.add_argument('-f','--factor', type=int, nargs='?', const=1, default=1,
                        help='decimation factor to plot the datas faster; default 1 (no decimation)')

    parser.add_argument('-p','--precision', type=int, nargs='?', const=1, default=1,
                        help='precision of hour display; 1=1x/minut, 10=1x/10min, -10=10x/minut; default 1') 
                        # en considérant une mesure toutes les 300ms soit 200 / minute 

    parser.add_argument('--hour1', type=str, nargs='?', const='None', default='None',
                        help='filter the file between specific hours; default none; format hh:mm')


    parser.add_argument('--hour2', type=str, nargs='?', const='None', default='None',
                        help='filter the file between specific hours; default none; format hh:mm ')
    
    parser.add_argument('-a','--annotations',nargs='?', type=str,
                        help='annotate an event : json file {"11:22:00":"some info","11:23:00":"more info"}')

    parser.add_argument('-m', '--average', action="store_true", # default to false, true when argument present
                        help='calculates and display the average of the power')

    parser.add_argument('-t','--title', type=str, nargs='?', 
                        help='title of the graph')


    args = parser.parse_args()

    fichier=args.file
    factor=args.factor
    heure1=args.hour1
    heure2=args.hour2
    print("hour 1 : %s" % heure1)
    print("hour 2 : %s" % heure2)
    annotations_file=args.annotations
    title=args.title


    if args.precision<0: # j'aurais sûrement pu faire ça mieux 
        factor_labels=-200/args.precision # si precision = -10, on veut 10x par minute donc décimer par 20 
    else:
        factor_labels=200*args.precision # si précision = 10, on veut 1x ttes les 10min donc décimer par 2000

    if factor_labels==0: 
        factor_labels=1

    factor_labels=int(factor_labels)
    
    # une mesure toutes les 300ms
    # soit 200 par minute 
    # je veux donc afficher un xtick tous les 200

    (x,y)=traiter_fichier(fichier,factor,heure1,heure2)

    if (args.average):
        avg=moyenne(y)
        print("average : %.2fW" % avg)

    #print("facteur pour les labels : %g" % factor_labels)
    label_indexes=range(0,len(x),factor_labels)
    labels=[x[i] for i in label_indexes]
    print("hour labels number : %d" % len(labels))
    plot(x,y,labels,factor_labels,factor,annotations_file,title)


parser_et_run()

#test_plot()

#test_parse_ann()
#test_get_indexes()

#test_traiter_fichier()