from numpy import std, mean, var

def funcao(dataType, lines, operation):
    n = 2
    lista = []
    for i in lines:
            if (dataType in i):
                texto = i
                # print (texto)
                tamanhoDoPacote = texto.split(',')[1]
                valor=int(tamanhoDoPacote)
                lista.append(valor)

    print(lista)
    if operation == 'average':
        medias = [avg for avg in [sum(lista[i:i+n])//n for i in range(0,len(lista),n)] for j in range(n)]
    if operation == 'min':
        medias = [avg for avg in [min(lista[i:i+n])//n for i in range(0,len(lista),n)] for j in range(n)]
    if operation == 'max':
        medias = [avg for avg in [max(lista[i:i+n])//n for i in range(0,len(lista),n)] for j in range(n)]
    if operation == 'vari':
        medias = [avg for avg in [var(lista[i:i+n])//n for i in range(0,len(lista),n)] for j in range(n)]
    #if operation == 'mov':
    #    N = 100
    #    medias = convolve(lista, ones((N,))/N, mode='same') 
    return medias

with open('FlowComLabel/logFlow.csv', 'r') as f:

    categories = ['amazonEcho', 'babyMonitor', 'belkinMotion', 'blipcareBP', 'laptop', 'lifxlighbulb', 'netatmo', 'sleepSensor', 'tribySpeaker']

    avgs, minimo, maximo, vari, movAvgs = [], [], [], [], []
    lines = f.readlines()
    with open('FlowComLabel/flowLabel.csv', 'w+') as outfile:
        for i in categories:
            print(i)
            avgs.append(funcao(i, lines, 'average'))
            minimo.append(funcao(i, lines, 'min'))
            maximo.append(funcao(i, lines, 'max'))
            vari.append(funcao(i, lines, 'vari'))
            #movAvgs.append(funcao(i, lines, 'mov'))

        outfile.write('bytes_out,packets,type,average,min,max,vari\n')    
        for lin in lines:
            
            for i, cat in enumerate(categories):
                if (cat in lin):
                    outfile.write('{},{},{},{},{}\n'.format(lin[:-1],
                                                               avgs[i][0],
                                                               minimo[i][0],
                                                               maximo[i][0],
                                                               vari[i][0]))
                    avgs[i].pop(0)
                    minimo[i].pop(0)
                    maximo[i].pop(0)
                    vari[i].pop(0)
