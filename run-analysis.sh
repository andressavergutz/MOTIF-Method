#!/bin/bash

##########################################################################
#----- Andressa Vergutz
# 
#-----  Este código realiza a manipulação de arquivos pcaps (tráfego de rede)
#-----  Além da linguagem shell script, são usadas ferramentas como tshark e joy
#-----  Os dados utilizados estão disponíveis na internet 
##########################################################################



##########################################################################
#----- Flows are: 
#----- (a) either unicast or multicast/broadcast, 
#----- (b) destined to either local hosts (LAN) or Internet servers (WAN), and 
#----- (c) tied to protocols (TCP, UDP, ICMP or IGMP) and port numbers.
# 
# 
#----- A flow is the data-plane stream of packets between sender and receiver that shares key IP header information. For example, a client at 10.1.1.1 port 12398 communicating with a server at 192.168.1.1 port 22 for SSH is a specific flow that can be captured as the key fields don't change.

#----- A session is the control-plane communication between sender and receiver. The TCP 3-way handshake creates a session that establishes a connection between the sender's source port and receiver's destination listening port. TCP window size, initial sequence and acknowledge values, and keepalives are negotiated as part of building the session.

#----- Basically, flow represents the data-plane and session represents the control-plane.

#----- Edit: Removed bidirectional requirement for a flow.
#----- 
#----- To use an analogy, a flow is me speaking to you. A session is a conversation between us.
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


declare PATH_MAIN=/home/healthsense/Documentos/MOTIF-Method/
declare PATH_JOY=/home/healthsense/Documentos/MOTIF-Method/joy/
declare PATH_PCAPS=/home/healthsense/Documentos/MOTIF-Method/pcaps/IoTdevices
#declare PATH_APPSCANNER=/home/healthsense/Documentos/AnaliseTrafego/appscanner-master
declare PATH_HD=/media/avergutz/ANDRESSA/UFPR/UFPR-doutorado/ProjetoHealthsense/AnaliseTrafego/IoTdevices/


	
#########################################################################
#----- 1ª função: manipula o pcap inicial que contém os dados de todos os dispositivos 
#----- Essa função divide os arquivos pcaps coletados diariamente --logo temos um arquivo pcap p/ dia--
#-----  por dispositivo IoT que gerou o tráfego. Para isso, utilizamos o endereço MAC de cada dispositivo
#########################################################################
SeparaPcaps(){

	cd ${PATH_PCAPS}

	for (( i=0; i < ${#dateFile[@]}; i++ ))
  	do
  		for (( k=0; k < ${#device[@]}; k++ ))
  		do
	  		file="${dateFile[$i]}"
	  		echo ${file}

			fileOutDisp="${device[$k]}-${file}"
			echo "Criando pcap apenas com tráfego do dispositivo ${fileOutDisp}"
			
			if [ -f "${device[$k]}/${fileOutDisp}" ]; then
				echo "Arquivo do ${device[$k]} já existe!"
			else	
				tshark -Y "eth.src==${MACaddress[$k]}" -r ${file} -w "${device[$k]}/${fileOutDisp}"
  				echo "Criou arquivo > ${device[$k]}-${file} < com o endereço ${MACaddress[$k]}"
				echo "----------------------------------------------------------------"
			fi
		done
	done	
	echo "-- ARQUIVOS CRIADOS COM SUCESSO! --"
	echo "--******************************--"

}

########################################################################
#----- Esta função une todos os pcaps de acordo com cada dispositivo que gerou tráfego, ou seja,
#----- cria um arquivo pcap para cada dispositivo com seu determinado tráfego de dados
########################################################################
MergePcaps(){
	
	echo "-- INICIANDO MERGE DOS ARQUIVOS DE CADA DISPOSITIVO --"
	for (( k=0; k < ${#device[@]}; k++ ))
  	do
  		cd ${PATH_PCAPS}/${device[$k]}

  		#----- merge pcaps dos mesmos dispositivo
		#----- mergecap -v -w merge_cap capture1 capture2 capture3
		mergecap -a -w ${device[$k]}-all2.pcap \
					   ${device[$k]}-16-10-12.pcap \
					   ${device[$k]}-16-10-11.pcap \
					   ${device[$k]}-16-10-10.pcap \
					   ${device[$k]}-16-10-09.pcap \
					   ${device[$k]}-16-10-08.pcap \
					   ${device[$k]}-16-10-07.pcap \
					   ${device[$k]}-16-10-06.pcap \
					   ${device[$k]}-16-10-05.pcap \
					   ${device[$k]}-16-10-04.pcap \
					   ${device[$k]}-16-10-03.pcap \
					   ${device[$k]}-16-10-02.pcap \
					   ${device[$k]}-16-10-01.pcap \
					   ${device[$k]}-16-09-30.pcap \
					   ${device[$k]}-16-09-29.pcap \
					   ${device[$k]}-16-09-28.pcap \
					   ${device[$k]}-16-09-27.pcap \
					   ${device[$k]}-16-09-26.pcap \
					   ${device[$k]}-16-09-25.pcap \
					   ${device[$k]}-16-09-24.pcap \
					   ${device[$k]}-16-09-23.pcap
		echo "Merge do dispositivo >>> ${device[$k]}-all2 "
		echo "----------------------------------------------------------------"
	done
	echo "-- MERGE REALIZADO COM SUCESSO (; --"
}


########################################################################
#----- Esta função utiliza a ferramenta Joy da Cisco para realizar a extração 
#----- do volume de fluxo de cada dispositivo. Para isso, a função encontra os 
#----- fluxos de cada dispositivo e então soma os bytes.
#########################################################################
ExecutaJoy(){

	cd ${PATH_JOY}

	echo "->>>> Aplicando Sleuth para extrair as features desejadas ... "

	for (( k=0; k < ${#device[@]}; k++ ))
 	do	  	
 		#----- all pcap junto
 		./sleuth ${PATH_PCAPS}/${device[$k]}/${device[$k]}-all2.pcap  \
 			--select  "packets, bytes_out, bytes_in ,da, sa" \
			--groupby sa,sp,da,dp,pr \
			--where "bytes_out>0, da~8.8.8.8"\
			| sort -k 2 -nr > ${PATH_PCAPS}/${device[$k]}/flows-${device[$k]}-all.txt


		#----- pcap por dia de cada dispositivo	
		for (( i=0; i < ${#dateFile[@]}; i++ ))
		do
			./sleuth ${PATH_PCAPS}/${device[$k]}/${device[$k]}-${dateFile[$i]}  \
	 			--select  "packets, bytes_out, bytes_in ,da, sa" \
				--groupby sa,sp,da,dp,pr \
				--where "bytes_out>0, da~8.8.8.8"\
				| sort -k 2 -nr > ${PATH_PCAPS}/${device[$k]}/flows-${device[$k]}-${dateFile[$i]}.txt
		done		
	done

	echo "Todos os arquivos do Joy gerados com SUCESSO! "
	
}


AmostraFluxo(){
	cd ${PATH_MAIN}
	echo ${PATH_MAIN}
	echo "Criando Amostragens"
	for (( k=0; k < ${#device[@]}; k++ ))
 	do	  	
 		python format-amostras.py ${device[$k]}
 	done
 	echo "Amostras criadas"

}
 
########################################################################
#----- Esta função faz um resumo das estatísticas de cada dispositivo, 
#----- como quantidade de pacotes e etc
########################################################################
ExtraiFeatures(){
	
#-----	esse loop entra no diretório de cada dispositivo, lê o pcap e salva as principais características, como quantidade de pacotes
	
	for (( k=0; k < ${#device[@]}; k++ ))
 	do	  		
 		cd ${PATH_PCAPS}/${device[$k]}/
 	
	 	for (( i=0; i < ${#dateFile[@]}; i++ ))
	 	do	

	 	 	#----- salva o num de pacotes por dia de cada dispositivo
	 		if [ ! -e "dateVSnumPackets-${device[$k]}.txt" ]; then
				#----- salva o num de pacotes por dia de cada dispositivo
				tshark -r ${device[$k]}-${dateFile[$i]} | wc -l >> "dateVSnumPackets-${device[$k]}.txt"
			fi		
			
			#----- salva o tamanho dos pacotes por dia de cada dispositivo
			if [ ! -e "tamPac-${device[$k]}-${dateFile[$i]}.txt" ]; then

				echo "entrou ${device[$k]}"

				echo -e "${device[$k]}" > "tamPac-${device[$k]}-${dateFile[$i]}.txt"
				tshark -r ${device[$k]}-${dateFile[$i]} -t e -T fields -e frame.len -E header=n -E quote=n -E occurrence=f \
				>> "tamPac-${device[$k]}-${dateFile[$i]}.txt"

				#----- se arquivo está vazio, após tshark, add valor 0 para o tamanho dos pacotes
				comando=`cat "tamPac-${device[$k]}-${dateFile[$i]}.txt" | wc -l`
				echo $comando
				if [ $comando == 1 ]; then 
					echo "entrou ${device[$k]}"
					echo -e "0" >> "tamPac-${device[$k]}-${dateFile[$i]}.txt" 
				fi 
			fi	

		#-----salva o volume de fluxo por dia de cada dispositivo
			if [ ! -e "flowVolume-${device[$k]}-${dateFile[$i]}.txt" ]; then

				echo "entrou ${device[$k]}"

				echo -e "${device[$k]}" > "flowVolume-${device[$k]}-${dateFile[$i]}.txt"
				cat flows-${device[$k]}-${dateFile[$i]}.txt | grep bytes_out | awk '{print $2}' | sed 's/\,/\ /' \
				  >> flowVolume-${device[$k]}-${dateFile[$i]}.txt

				#---- se arquivo está vazio, add valor 0 para o volume de fluxo
				comando=`cat "flowVolume-${device[$k]}-${dateFile[$i]}.txt" | wc -l`
				echo $comando
				if [ $comando == 1 ]; then 
					echo "entrou ${device[$k]}"
					echo -e "0" >> "flowVolume-${device[$k]}-${dateFile[$i]}.txt" 
				fi 
			fi	
	
			#----- salva o summary por dia de cada dispositivo
			if [ ! -e "${device[$k]}-${dateFile[$i]}-summary.txt" ]; then
				   			
			   	echo "Arquivo summary do dispositivo ${device[$k]}-${dateFile[$i]} ainda não existe!"

		 		capinfos ${device[$k]}-${dateFile[$i]} > "${device[$k]}-${dateFile[$i]}-summary.txt"
		 			
		 		#----- cat amazonEcho-16-09-23.pcap-summary.txt | grep Average | head -1 | awk '{print $4}' | sed 's/\,/\./'
		 		cat "${device[$k]}-${dateFile[$i]}-summary.txt" | grep Average | head -1 | awk '{print $4}' | sed 's/\,/\./' \
		 				>> averagePacketSize-dateVS${device[$k]}.txt
			fi	

		done

		#----- salva sumário das estatísticas de cada dispositivo 
		capinfos ${device[$k]}-all2.pcap > ${device[$k]}-summary.txt

		if [ ! -e "${PATH_PCAPS}/summary-all-devices.txt" ]; then
				
			#----- salva sumário de todos dispositivos em um arquivo de saida
			out="${PATH_PCAPS}/summary-all-devices.txt"
			capinfos -L -u -x -y -z -o -i -d -e -c -a ${device[$k]}-all2.pcap >> ${out}
			echo "Exact number of packets:  " >> ${out}
			tshark -r ${device[$k]}-all2.pcap | wc -l >> ${out}
			echo "  ----------------------------    " >> ${out}
			echo " " >> ${out}
		fi	
	done
	echo "-- ESTATÍSTICAS GERADAS COM SUCESSO! --"
}


OrganizaFiles(){

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
	if [ ! -e "${PATH_PCAPS}/dateVSnumPackets-devices.txt" ]; then

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
	else
		echo "Arquivo dateVSnumPackets-devices.txt já existe!"
	fi	

	#-----
	#----- salva arquivo do tam medio ds pacotes VS dia do pcap para gráfico
	#----- 
	#----- rm "${PATH_PCAPS}/dateVSaveragePacketSize2-devices.txt"

	if [ ! -e "${PATH_PCAPS}/dateVSaveragePacketSize-devices.txt" ]; then

		echo "Criando arquivo dateVSaveragePacketSize-devices.txt ..."

		echo -e "Data Data AmazonEcho BelkinMotion BlipcareBP BabyMonitor Laptop LIFXlighbulb Netatmo SleepSensor TribySpeaker" \
		   > ${PATH_PCAPS}/dateVSaveragePacketSize-devices.txt

		paste ${PATH_PCAPS}/datas.txt \
			  ${PATH_PCAPS}/contagem.txt \
			  ${PATH_PCAPS}/amazonEcho/averagePacketSize-dateVSamazonEcho.txt \
			  ${PATH_PCAPS}/belkinMotion/averagePacketSize-dateVSbelkinMotion.txt \
			  ${PATH_PCAPS}/blipcareBP/averagePacketSize-dateVSblipcareBP.txt \
			  ${PATH_PCAPS}/BabyMonitor/averagePacketSize-dateVSBabyMonitor.txt \
			  ${PATH_PCAPS}/laptop/averagePacketSize-dateVSlaptop.txt \
			  ${PATH_PCAPS}/LIFXlighbulb/averagePacketSize-dateVSLIFXlighbulb.txt \
			  ${PATH_PCAPS}/Netatmo/averagePacketSize-dateVSNetatmo.txt \
			  ${PATH_PCAPS}/sleepSensor/averagePacketSize-dateVSsleepSensor.txt \
			  ${PATH_PCAPS}/tribySpeaker/averagePacketSize-dateVStribySpeaker.txt \
			  >> ${PATH_PCAPS}/dateVSaveragePacketSize-devices.txt
	  	
	  	echo "Arquivo dateVSaveragePacketSize-devices.txt CRIADO COM SUCESSO!"
	else
		echo "Arquivo dateVSaveragePacketSize-devices.txt já existe!"
	fi	


	#
	#----- salva arquivo de tamanho de pacotes VS dia do pcap para gráfico
	# 
	while read LINHA; do
		if [ ! -e "${PATH_PCAPS}/tamPackets-$LINHA.txt" ]; then

			echo "Criando arquivo tamPackets-$LINHA.txt ..."
								
			paste ${PATH_PCAPS}amazonEcho/tamPac-amazonEcho-$LINHA.txt \
				  ${PATH_PCAPS}belkinMotion/tamPac-belkinMotion-$LINHA.txt  \
				  ${PATH_PCAPS}blipcareBP/tamPac-blipcareBP-$LINHA.txt  \
				  ${PATH_PCAPS}BabyMonitor/tamPac-BabyMonitor-$LINHA.txt  \
				  ${PATH_PCAPS}laptop/tamPac-laptop-$LINHA.txt  \
				  ${PATH_PCAPS}LIFXlighbulb/tamPac-LIFXlighbulb-$LINHA.txt  \
				  ${PATH_PCAPS}Netatmo/tamPac-Netatmo-$LINHA.txt  \
				  ${PATH_PCAPS}sleepSensor/tamPac-sleepSensor-$LINHA.txt  \
				  ${PATH_PCAPS}tribySpeaker/tamPac-tribySpeaker-$LINHA.txt  \
				  >> ${PATH_PCAPS}tamPackets-$LINHA.txt
		  	
		  	echo "Arquivo tamPackets-$LINHA.txt CRIADO COM SUCESSO!"
		else
			echo "Arquivo tamPackets-$LINHA.txt já existe!"
		fi	
	done < "${PATH_PCAPS}/datas.txt"

	#
	#----- salva arquivo de volume de fluxo VS dia do pcap para gráfico
	# 
	for (( i=0; i < ${#dateFile[@]}; i++ ))
	do

		if [ ! -e "${PATH_PCAPS}/flowVolume-only-${dateFile[$i]}.txt" ]; then

			echo "Criando arquivo flowVolume-only-${dateFile[$i]}.txt ..."
								
           	echo -e "AmazonEcho BelkinMotion BlipcareBP BabyMonitor Laptop LIFXlighbulb Netatmo SleepSensor TribySpeaker" \
		 			> ${PATH_PCAPS}/flowVolume-only-${dateFile[$i]}.txt

			paste ${PATH_PCAPS}amazonEcho/flowVolume-amazonEcho-${dateFile[$i]}.txt \
				  ${PATH_PCAPS}belkinMotion/flowVolume-belkinMotion-${dateFile[$i]}.txt  \
				  ${PATH_PCAPS}blipcareBP/flowVolume-blipcareBP-${dateFile[$i]}.txt  \
				  ${PATH_PCAPS}BabyMonitor/flowVolume-BabyMonitor-${dateFile[$i]}.txt  \
				  ${PATH_PCAPS}laptop/flowVolume-laptop-${dateFile[$i]}.txt  \
				  ${PATH_PCAPS}LIFXlighbulb/flowVolume-LIFXlighbulb-${dateFile[$i]}.txt  \
				  ${PATH_PCAPS}Netatmo/flowVolume-Netatmo-${dateFile[$i]}.txt  \
				  ${PATH_PCAPS}sleepSensor/flowVolume-sleepSensor-${dateFile[$i]}.txt  \
				  ${PATH_PCAPS}tribySpeaker/flowVolume-tribySpeaker-${dateFile[$i]}.txt  \
				  > ${PATH_PCAPS}flowVolume-only-${dateFile[$i]}.txt
		  	
		  	echo "Arquivo flowVolume-only-${dateFile[$i]}.txt CRIADO COM SUCESSO!"
		else
			echo "Arquivo flowVolume-only-${dateFile[$i]}.txt já existe!"
		fi
	done	
}

ExcluiFiles(){

	#----- busca em subdiretorios
	#----- 	find ./${PATH_PCAPS} -iname '*pcap-summary-txt' -exec rm
	for (( k=0; k < ${#device[@]}; k++ ))
 	do	  		
 		echo "${PATH_PCAPS}/${device[$k]}"
 		cd ${PATH_PCAPS}/${device[$k]}/
 		rm flowVolume-${device[$k]}-16*
 		rm flowsVolume-${device[$k]}-16*
		rm tamPac-${device[$k]}-16*
 	done

 	#---- cd ${PATH_PCAPS}
 	rm flowVolume-only-16-*
 	rm tamPackets-16-*

 	#---- exclui todos os csv das amostras
 	cd ${PATH_MAIN}
 	rm *.csv
	
}



########################################################################
#----- Main
#########################################################################
main(){

	case "$1" in
		'-p'|'--runpcap' )
			SeparaPcaps
		;;
		'-m'|'--mergePcaps' )
			MergePcaps
		;;
		'-j'|'--runjoy' )
			ExecutaJoy
		;;
		'-a'|'--geraamostras' )
			AmostraFluxo
		;;
		'-e'|'--extraiFeatures' )
			ExtraiFeatures
		;;
		'-o'|'organiza' )
			OrganizaFiles
		;;
		'-d'|'exluiFiles' )
			ExcluiFiles
		;;
	esac	
}

main "$@"

