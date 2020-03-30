import pandas
import matplotlib.pyplot as plt
from sklearn import model_selection
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score, classification_report, confusion_matrix
from sklearn.tree import DecisionTreeClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.naive_bayes import GaussianNB
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier
from sklearn.ensemble import BaggingClassifier
from sklearn.ensemble import AdaBoostClassifier
from sklearn.ensemble import ExtraTreesClassifier
from sklearn.model_selection import LeaveOneOut 
import numpy as np
from timeit import default_timer as timer
from joblib import Parallel, delayed
from sklearn.metrics import confusion_matrix
from sklearn.metrics import accuracy_score
from sklearn.metrics import classification_report

def stats(df):
	# Split-out validation datas1et
	array = df.values
	#print(i.packets)
	X = df[['bytes_out','packets','average','min','max','vari']].copy()
	Y = df['type'].copy()
	#print(X)
	# X = array[:,0:2] #pega colunas 0,1 (apenas numeros)
	#Y = np.array([i[1]])
	#print(Y)
	# Y = array[:,1]
	validation_size = 0.40
	seed = 7
	X_train, X_validation, Y_train, Y_validation = model_selection.train_test_split (X, Y, test_size=validation_size, random_state=seed)
	#X_train, X_validation, Y_train, Y_validation = model_selection.train_test_split (X_train, Y_train, test_size=0.5)
	target_names = ['amazonEcho', 'babyMonitor', 'belkinMotion', 'blipcareBP', 'laptop', 'lifxlighbulb', 'netatmo', 'sleepSensor', 'tribySpeaker']

	# Test options and evaluation metric
	seed = 7
	scoring = 'accuracy'

	models = []
	#models.append(('NB', GaussianNB()))
	#models.append(('CART', DecisionTreeClassifier()))
	models.append(('R.Forest', RandomForestClassifier(n_estimators=100)))
	#models.append(('Bagging', BaggingClassifier(base_estimator=DecisionTreeClassifier(), n_estimators=100, random_state=seed)))
	#models.append(('KNN', KNeighborsClassifier()))
	#models.append(('SVM', SVC(gamma='auto')))
	#models.append(('Kmeans', KMeans(5, random_state=0)))
	#models.append(('AdaBoost', AdaBoostClassifier(n_estimators=50, learning_rate=1)))

	# Evaluate each model in turn	

	results, names, f1Results, recallResults, precisionResults, timeResults = [], [], [], [], [], []
	for name, model in models:
		startTemp = timer()
		kfold = model_selection.KFold(n_splits=9, random_state=seed)
		cv_results = model_selection.cross_val_score(model, X_train, Y_train, cv=kfold, scoring=scoring)
		results.append(np.mean(cv_results))
		names.append(name)
		model.fit(X_train, Y_train)
		predictions = model.predict(X_validation)
		g = model.score(X_validation, Y_validation)
		#results.append(g)
		accuracy = accuracy_score(Y_validation, predictions)
		f1 = f1_score(Y_validation, predictions, average="macro")
		#print f1
		f1Results.append(f1)
		recall = recall_score(Y_validation, predictions, average="macro")
		recallResults.append(recall)
		precision = precision_score(Y_validation, predictions, average="macro")
		precisionResults.append(precision)
		endTemp = timer()
		#msg = "\n%s: mean: %f tempo: %f" % (name, g.mean(), endTemp-startTemp)
		#print(g)
		msg = "\n%s: accuracy: %f, f1: %f, recall: %f, precision: %f, tempo: %f" % (name, np.mean(cv_results), f1, recall, precision, endTemp-startTemp)
		#print(msg)

		timeResults.append(endTemp-startTemp) 
		#print >> arquivo, msg
		cm = confusion_matrix(Y_validation, predictions)
		cm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]
		print(cm.diagonal())
		print(classification_report(Y_validation, predictions, target_names=target_names, digits=4))
	return (names, results, f1Results, recallResults, precisionResults, timeResults)

start = timer()

# Load df
df = pandas.read_csv("./logFlowLabel.csv", sep=",", header='infer')
#df = pandas.read_csv("/home/iago/Documentos/globecom/teste.csv", sep=",")
#df = pandas.read_csv("/home/iago/Documentos/globecom/pcap/amazonEcho/amazonEcho-16-09-23.csv", sep=",")

# class distribution (define target class)
#print (df.groupby('type').size())
#print(df.groupby('type')[['packets','average','min','max','vari']].info())
#print(df.groupby('type')[['bytes_out','packets','average','min','max','vari']].describe())
# Set colors
colorX=['#0000ff','#1919ff', '#3232ff', '#4c4cff', '#6666ff', '#7f7fff', '#9999ff', '#b2b2ff']

resultado = Parallel(n_jobs=4)(delayed(stats)(df) for i in range(2))
#r0, r1,r2,r3,r4,r5 = zip(*resultado)

#print(size(r0))
#arquivo = open('matrixKfold.txt', 'a')
#print >> arquivo, ('\n------------XXXXXXXXXXXXXXXXX kFold - Flow XXXXXXXXXXXXXXXXX--------------')
#for idx in range(len(r1)):
#	print >> arquivo, ('\n------------XXXXXXXXXXXXXXXXXXXX Run %g XXXXXXXXXXXXXXXXXXXX---------------' % (int(idx)+1))
#	for idx2 in range(len(r1[idx])):
#		idx = int(idx)
#		idx2 = int(idx2)
#		msg = "\n%s: accuracy: %f, f1: %f, recall: %f, precision: %f, tempo: %f" % (r0[idx][idx2], r1[idx][idx2], r2[idx][idx2], r3[idx][idx2], r4[idx][idx2], r5[idx][idx2])
#		print >> arquivo, msg