import pandas as pd
import numpy as np
df = pd.read_csv("zum3.txt", header=None)

for col in df.columns.values:
	name = str(col) + "_std"
	df[name] = df[col].std()
print(df)

df3 = df[[0,'0_std', '0_std', 1, '1_std', '1_std', 2, '2_std', '2_std', 3, '3_std', '3_std', 4, '4_std', '4_std', 5, '5_std', '5_std', 6, '6_std', '6_std']]
df3.columns = ['"NB"', '"desvioNB"', '"desvioNB.1"', '"CART"', '"desvioC"', "\"desvioC.1\"", '"R.Forest"', '"desvioRF"', '"desvioRF.1"', '"Bagging"', '"desvioB"', '"desvioB.1"', '"KNN"', '"desvioKNN"', '"desvioKNN.1"', '"SVM"', '"desvioSVM"', '"desvioSVM.1"', '"Adaboost"', '"desvioAda"', '"desvioAda.1"']
df3.index = df.index.map(str)
df3.to_csv('DatasetTimeHandoutPacket.csv', sep=',', header=True, index=True)