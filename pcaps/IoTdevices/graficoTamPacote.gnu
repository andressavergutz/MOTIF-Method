##
## Gnuplot é um programa de linha de comando que plota
## gráficos de funções matemáticas e de conjuntos de dados,
## em duas ou três dimensões. Para mais informações acesse:
## http://gnuplot.sourceforge.net/
##
## Este script contem comandos do Gnuplot na versão 4.6. As
## linhas que iniciam com o carácter '#' indicam comentários,
## e são ignoradas na execução.
##
## Descrição do gráfico gerado:
##	Gráfico em linhas;
##	Três linhas e formas geométricas;
##	Intervalo de confiança;
##	Grades horizontais e verticias;
##	Legenda posicionada no canto superior esquerdo.
##

#limpa configurações anteriores do gnuplot
reset

#formato de codificação
set encoding utf8

#formato do arquivo, estilo da fonte e tamanho da fonte
set terminal postscript eps enhanced "Helvetica, 22"

#arquivo de saída em formato eps
#set output "comport_04.eps"

#arquivo de saída em formato pdf
set output '| epstopdf --filter > tamPac-tribySpeaker-161011.pdf'
	# | epstopdf --filter #(direciona a saida no gnuplot para o epstopdf)
	# > barra.pdf #(nome de saída após a conversão no epstopdf)
	# Para instalar o epstopdf via terminal
		#Ubuntu -> "sudo apt-get install texlive-font-utils"
		#Mac OS -> "sudo port install texlive-fontutils"
		#Testado na versão Ubuntu 14.04 LTS e MacOS X 10.10

#insere grade
unset grid
#set grid lt 1 lw 0.5 lc rgb "#c0c0c0"
	# lt #(tipo da linha)
	# lc #(cor da linha ##outro exemplo## lc rgb 'black')
	# lw #(espessura da linha)

#posição da legenda
set key left top reverse Left samplen 4
	#left bottom...#(Canto inferior esquerdo)
	#right bottom..#(Canto inferior direito)
	#left top......#(Canto superior esquerdo)
	#right top.....#(Canto superior direito)
	#reverse Left..#(Troca a posição do texto com a posição da amostra e alinha para esquerda)
	#samplen.......#(Tamanho da amostra da legenda)

#tamanho do gráfico
set size 1.0, 1.0

#títulos
set title "Dispositivo IoT triby Speaker (16-10-11)" #(titulo do gráfico)
set xlabel "Tempo (s)" #(titulo eixo X)
set ylabel "Tamanho do Pacote (bytes)" #(titulo eixo Y)

#valores dos eixos x e y
#set yrange [0:1000] #intervalo do eixo Y
set xrange [-1:90000]	#intervalo do eixo X
set xtic 20000		 #(intervalo entre os pontos do eixo Y)

#estilo das linhas e dos pontos
set style line 2 lt 1 lw 2 pt 0 linecolor rgb "#3232CD"
#set style line 3 lt 1 lw 3 ps 1.6 pt 9 linecolor rgb "#A52A2A"

	# lt #(tipo da linha)
	# lw #(espessura da linha)
	# ps #(tamanho dos pontos)
	# pt #(tipo do ponto)
	# lc #(cor da linha ##outro exemplo## lc rgb 'black')

#estilo do intervalo de confiança
set style line 1 lt 1 lw 3
	# lt #(tipo da linha)
	# lw #(espessura da linha)

plot  'out-tribySpeaker-16-10-11.txt' using 1:2 with linespoints notitle ls 2 #,\
			#'' using 1:5 with linespoints t "AC-AM-Priorizado" ls 3 ,\
			#'' using 1:2:3:4  with yerrorbars notitle ls 1 linecolor rgb "#3232CD" ,\
			#gn'' using 1:5:6:7  with yerrorbars notitle ls 1 linecolor rgb "#A52A2A" ,\

#
# 'dados.txt' --> especificação dos dados do plot
# with linespoints --> especifica o uso de linhas e pontos
# using col:col --> valor eixo x e eixo y (exemplo, 1:2)
# t --> título da legenda das linhas
# with yerrorbars --> especifica o uso do intervalo de confiança
# using col:col:intervalo --> valor eixo x, eixo y e internvalo de confiança (exemplo, 1:2:3)
# notitle --> remove da legenda
# ls --> chamada dos estilos definidos
# lc --> cor das linhas
# QUANDO MAIS DE UMA COMBIACAO USAR ',' E '\' PARA QUEBRA DE LINHA
###################################################