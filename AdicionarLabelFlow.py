with open('./Flow/flow-amazonEcho.csv', 'r') as f:
    lines = f.readlines()
    with open('flow-amazonEcho.csv', 'w+') as outfile:
        #outfile.write('{},\n'.format(lines[0][:-1]))
        for lin in lines[0:]:
            outfile.write('{},{}\n'.format(lin[:-1], 'amazonEcho'))

with open('./Flow/flow-babyMonitor.csv', 'r') as f:
    lines = f.readlines()
    with open('flow-babyMonitor.csv', 'w+') as outfile:
        #outfile.write('{},\n'.format(lines[0][:-1]))
        for lin in lines[0:]:
            outfile.write('{},{}\n'.format(lin[:-1], 'babyMonitor'))

with open('./Flow/flow-belkinMotion.csv', 'r') as f:
    lines = f.readlines()
    with open('flow-belkinMotion.csv', 'w+') as outfile:
        #outfile.write('{},\n'.format(lines[0][:-1]))
        for lin in lines[0:]:
            outfile.write('{},{}\n'.format(lin[:-1], 'belkinMotion'))

with open('./Flow/flow-blipcareBP.csv', 'r') as f:
    lines = f.readlines()
    with open('flow-blipcareBP.csv', 'w+') as outfile:
        #outfile.write('{},\n'.format(lines[0][:-1]))
        for lin in lines[0:]:
            outfile.write('{},{}\n'.format(lin[:-1], 'blipcareBP'))

with open('./Flow/flow-laptop.csv', 'r') as f:
    lines = f.readlines()
    with open('flow-laptop.csv', 'w+') as outfile:
        #outfile.write('{},\n'.format(lines[0][:-1]))
        for lin in lines[0:]:
            outfile.write('{},{}\n'.format(lin[:-1], 'laptop'))

with open('./Flow/flow-lifxlighbulb.csv', 'r') as f:
    lines = f.readlines()
    with open('flow-lifxlighbulb.csv', 'w+') as outfile:
    	#outfile.write('{},\n'.format(lines[0][:-1]))
    	for lin in lines[0:]:
    		outfile.write('{},{}\n'.format(lin[:-1], 'lifxlighbulb'))

with open('./Flow/flow-netatmo.csv', 'r') as f:
    lines = f.readlines()
    with open('flow-netatmo.csv', 'w+') as outfile:
    	#outfile.write('{},Type\n'.format(lines[0][:-1]))
    	for lin in lines[0:]:
    		outfile.write('{},{}\n'.format(lin[:-1], 'netatmo'))

with open('./Flow/flow-sleepSensor.csv', 'r') as f:
    lines = f.readlines()
    with open('flow-sleepSensor.csv', 'w+') as outfile:
    	#outfile.write('{},Type\n'.format(lines[0][:-1]))
    	for lin in lines[0:]:
    		outfile.write('{},{}\n'.format(lin[:-1], 'sleepSensor'))

with open('./Flow/flow-tribySpeaker.csv', 'r') as f:
    lines = f.readlines()
    with open('flow-tribySpeaker.csv', 'w+') as outfile:
    	#outfile.write('{},Type\n'.format(lines[0][:-1]))
    	for lin in lines[0:]:
    		outfile.write('{},{}\n'.format(lin[:-1], 'tribySpeaker'))

