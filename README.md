# MOTIF Method

MOTIF identifies the traffic of different classes of applications employing side-channel information and following three main phases: (1) Pre-Processing, (2) Feature Extraction, and (3) Identification. The first phase pre-processes the network traffic filtering traffic according to certain feature (called ground-truth information). The main goal of this phases is the associate in a first moment the traffic with the devices. 
From ground-truth information, MOTIF can filter the network traffic per device. This assists in the next phases and also make easier to quantify how accurate MOTIF is in terms of precision, recall, and other metrics.

## Reproducing our analysis

### Prerequisites

We used a laptop Dell, i5 8th G., 500GB HD with Ubuntu 16.04 LTS. Create a directory called MOTIF-Method to save all files, scripts, and others since our scripts follow this path name.

**1)** Dataset download - [Link](https://iotanalytics.unsw.edu.au/iottraces.html). Dataset contains IoT devices traffic over 20 days (20 pcaps). We used all the traffic available. 

The file ```List_Of_Devices.txt``` details each device MAC address.

Save the pcaps in a directory named IoTdevices. Directory path: ```MOTIF-Method/pcaps/IoTdevices```. 

**2)** Installing Tshark (v2.6.8), Tcpdump (v4.9.2), libpcap (v1.7.4) Joy (available on GitHub) and dependencies:

```
sudo apt-get install build-essential libssl-dev libpcap-dev libcurl4-openssl-dev
sudo apt-get install tshark tcpdump
sudo apt-get update
git clone https://github.com/cisco/joy.git
cd joy
[joy]$ ./configure --enable-gzip
[joy]$ make clean
[joy]$ make
sudo apt-get update; apt-get install gcc git libcurl3 libcurl4-openssl-dev libpcap0.8 libpcap-dev libssl1.0.0 libssl-dev make python python-pip ruby ruby-ffi
./build_pkg -t deb

```

Installing Python (v2.7.12) and libraries (numpy, scipy, scikit learn, etc.). Run the following script:

```
./downloadLibraries.sh
```

If you only want to verify the tools version. Run: 
```
python verifyLibraries.py
```

### Data Organization

The ```run_analysis.sh``` do everything! It manages the files and organizes the classifiers input. Also, it selects the 20 pcaps and the devices considered in our analysis. Devices = ('amazonEcho', 'babyMonitor', 'belkinMotion', 'blipcareBP', 'laptop', 'lifxlighbulb', 'netatmo', 'sleepSensor', 'tribySpeaker').

```run_analysis.sh```: In summary, it creates a file specific to each device containing its corresponding traffic over 20 days (we used the MAC address to do this).  Afterward, it extracts the features (e.g., packet size) through the tool Joy from Cisco. Hence, it runs **sleuth**to extract the features. This allows selecting the traffic flow considering the 5-tuples (source and destination IP address, source and destination port number, and transport-layer protocol). 

**3)** Run:
 
```
./run-analysis.sh -p 
./run-analysis.sh -m 
./run-analysis.sh -j 
./run-analysis.sh -a 
./run-analysis.sh -e 
./run-analysis.sh -o
``` 

Then, add the pcaps from different days in 1 file using basic command in shell/Linux.

Separate into different .csvs


**4)** Then, we select the total flow volume from each device and add a label to each one ('amazonEcho', 'babyMonitor', 'belkinMotion', 'blipcareBP', 'laptop', 'lifxlighbulb', 'netatmo', 'sleepSensor', 'tribySpeaker'). We save in a csv file (```logFlow.csv```). 

``` 
python AdicionarLabelFlow.py
``` 

**5)** Compute the average from the features (e.g., packet size):

``` 
python mediaFlow.py
``` 

### Running classifiers

Note we have 4 scripts in Python: 2 for Flow Scenario (```FlowHoldoutScenario.py, FlowKFoldScenario.py```) and 2 for Packet Scenario (```PacketHoldoutScenario.py, PacketKFoldScenario.py```). Each one generates 1 result log, for instance: ```resultadosFlowHoldout.txt, resultadosFlowKFold.txt, resultadosHoldoutPacotes.txt, resultadosKFoldPacotes.txt```. Hence, totally, we have 4 python scripts, 4 scenarios, and 4 results. 

Follow, I will show only the command for one result. However, you need to do the same for the other 3 scenarios.


Description: We import the libraries and add the name for file columns by panda. We add the size and feed the seed. Also, we divide the dataset into train, test, and validation, specifying the classes name ('amazonEcho', 'babyMonitor', 'belkinMotion', 'blipcareBP', 'laptop', 'lifxlighbulb', 'netatmo', 'sleepSensor', 'tribySpeaker'). We do a loop to instatiate the machine learning models (NB, CART, R. Forest, Bagging, k-NN, SVM, K-means, Adaboost), compute the performance metrics (accuracy, f1 score, recall, precision, classification time) and save the results in temporary vectors. Finally, we save all the results in an output file (e.g., resultadosFlowHoldout.txt or ResultadosHoldoutPacotes.txt) through parallel process.

**6)** Run:

``` 
python holdoutFluxo.py
``` 


