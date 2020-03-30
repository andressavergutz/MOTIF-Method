#!/bin/bash

##########################################################################
#----- Andressa Vergutz
# 
#-----  Este código realiza a manipulação de arquivos pcaps (tráfego de rede)
#-----  Além da linguagem shell script, são usadas ferramentas como tshark e joy
#-----  Os dados utilizados estão disponíveis na internet 
##########################################################################

declare -a dateFile=("16-09-23.pcap"
					"16-09-24.pcap"
					"16-09-25.pcap"	
					"16-09-26.pcap"
					"16-09-27.pcap"
					"16-09-28.pcap"
					"16-09-29.pcap"
					"16-09-30.pcap"
					"16-10-01.pcap"
					"16-10-02.pcap"
					"16-10-03.pcap"
					"16-10-04.pcap"
					"16-10-05.pcap"
                         "16-10-06.pcap"
                         "16-10-07.pcap"
                         "16-10-08.pcap"
                         "16-10-09.pcap"
                         "16-10-10.pcap"
                         "16-10-11.pcap"
                         "16-10-12.pcap") #-----esse pcap está com um pacote quebrado no meioc
                    
declare -a device=("amazonEcho"
                    "belkinMotion"
                    "blipcareBP"
                    "BabyMonitor"
                    "laptop"
                    "LIFXlighbulb"
                    "Netatmo"
                    "sleepSensor"
                    "tribySpeaker")

#---------- obs.: os endereços MAC estão disponíveis no arq "Lis_of_Devices.txt do dataset usado"
declare -a MACaddress=("44:65:0d:56:cc:d3"
                    	"ec:1a:59:83:28:11"
                    	"74:6a:89:00:2e:25"
                    	"00:24:e4:11:18:a8"
                    	"74:2f:68:81:69:42"
                    	"d0:73:d5:01:83:08"
                    	"70:ee:50:18:34:43"
                    	"00:24:e4:20:28:c6"
                    	"18:b7:9e:02:20:44")


declare PATH_MAIN=/home/healthsense/Documentos/AnaliseTrafego/
declare PATH_JOY=/home/healthsense/Documentos/AnaliseTrafego/joy/
declare PATH_PCAPS=/home/healthsense/Documentos/AnaliseTrafego/pcaps/IoTdevices/
declare PATH_APPSCANNER=/home/healthsense/Documentos/AnaliseTrafego/appscanner-master
declare PATH_HD=/media/avergutz/ANDRESSA/UFPR/UFPR-doutorado/ProjetoHealthsense/AnaliseTrafego/IoTdevices/


   
#-----    esse loop entra no diretório de cada dispositivo, lê o pcap e salva as principais características, como quantidade de pacotes
find . -name "dateVSnumPacket*" -exec rm {} \;  

for (( k=0; k < ${#device[@]}; k++ ))
do             
     cd ${PATH_PCAPS}/${device[$k]}/
     
     echo ${device[$k]}

     for (( i=0; i < ${#dateFile[@]}; i++ ))
     do   

          #----- salva o num de pacotes por dia de cada dispositivo
          tshark -r ${device[$k]}-${dateFile[$i]} | wc -l >> "dateVSnumPackets-${device[$k]}.txt"
             
          echo ${device[$k]}-${dateFile[$i]}    
     done
done  

if [[ ! -e "${PATH_PCAPS}/datas.txt" && ! -f "${PATH_PCAPS}/contagem.txt" ]]; then   

     for (( i=0; i < ${#dateFile[@]}; i++ ))
     do
          echo -e "${dateFile[$i]}" >> ${PATH_PCAPS}/datas.txt
          echo -e $i >> ${PATH_PCAPS}/contagem.txt
     done
fi

#-----
#----- salva arquivo de quantidade de pacotes VS dia do pcap para gráfico
# -----
echo "Criando arquivo dateVSnumPackets-devices.txt ..."

echo -e "Data Data AmazonEcho BelkinMotion BlipcareBP BabyMonitor Laptop LIFXlighbulb Netatmo SleepSensor TribySpeaker" \
     > ${PATH_PCAPS}/dateVSnumPackets-devices.txt

paste ${PATH_PCAPS}/datas.txt \
      ${PATH_PCAPS}/contagem.txt \
      ${PATH_PCAPS}/amazonEcho/dateVSnumPackets-amazonEcho.txt \
      ${PATH_PCAPS}/belkinMotion/dateVSnumPackets-belkinMotion.txt \
      ${PATH_PCAPS}/blipcareBP/dateVSnumPackets-blipcareBP.txt \
      ${PATH_PCAPS}/BabyMonitor/dateVSnumPackets-BabyMonitor.txt \
      ${PATH_PCAPS}/laptop/dateVSnumPackets-laptop.txt \
      ${PATH_PCAPS}/LIFXlighbulb/dateVSnumPackets-LIFXlighbulb.txt \
      ${PATH_PCAPS}/Netatmo/dateVSnumPackets-Netatmo.txt \
      ${PATH_PCAPS}/sleepSensor/dateVSnumPackets-sleepSensor.txt \
      ${PATH_PCAPS}/tribySpeaker/dateVSnumPackets-tribySpeaker.txt \
       >> ${PATH_PCAPS}/dateVSnumPackets-devices.txt
          
echo "Arquivo dateVSnumPackets-devices.txt CRIADO COM SUCESSO!"
