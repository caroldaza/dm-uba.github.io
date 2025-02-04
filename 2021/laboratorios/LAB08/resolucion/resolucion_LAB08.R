################################################################
##### Recuperamos todas las letras de canciones en español #####
################################################################

library(mongolite)
conx_lyrics_spa = mongo(collection = "lyrics_spanish", db = "DMUBA_SPOTIFY")
df_lyrics = conx_lyrics_spa$find('{}')

# eliminamos las conexión dado que no la vamos a usar
rm(conx_lyrics_spa)

#####################################################
############### Generación del corpus ###############
#####################################################

library(tm)
corpus = Corpus(VectorSource(enc2utf8(df_lyrics$lyrics)))

# Recuperamos la letra de la primera canción
# Luis Fonsi (despacito)
inspect(corpus[10])

#####################################################
###########Pre-procesamiento del corpus #############
#####################################################

# Eliminamos espacios
corpus.pro <- tm_map(corpus, stripWhitespace)
inspect(corpus.pro[10])

# Elimino todo lo que aparece antes del primer []
corpus.pro <- tm_map(corpus.pro, content_transformer(
                                          function(x) sub('^.+?\\[.*?\\]',"", x)))
inspect(corpus.pro[10])

# Elimino las aclaraciones en las canciones, por ejemplo:
# [Verso 1: Luis Fonsi & Daddy Yankee]
corpus.pro <- tm_map(corpus.pro, content_transformer(
                                          function(x) gsub('\\[.*?\\]', '', x)))
inspect(corpus.pro[10])

# Elimino todo lo que aparece luego de 'More on Genius'
corpus.pro <- tm_map(corpus.pro, content_transformer(function(x) gsub("More on Genius.*","", x)))
inspect(corpus.pro[10])

# Convertimos el texto a minúsculas
corpus.pro <- tm_map(corpus.pro, content_transformer(tolower))
inspect(corpus.pro[10])

# removemos números
corpus.pro <- tm_map(corpus.pro, removeNumbers)
inspect(corpus.pro[10])

# Removemos palabras vacias en español
corpus.pro <- tm_map(corpus.pro, removeWords, stopwords("spanish"))
inspect(corpus.pro[10])

# Podemos agregar palabras a las stopwords
# my_stopwords <- append(stopwords("spanish"), 'palabra')

# Removemos puntuaciones
corpus.pro <- tm_map(corpus.pro, removePunctuation)
inspect(corpus.pro[10])

# Removemos todo lo que no es alfanumérico
corpus.pro <- tm_map(corpus.pro, content_transformer(function(x) str_replace_all(x, "[[:punct:]]", " ")))
inspect(corpus.pro[10])

# En tm_map podemos utilizar funciones prop
library(stringi)
replaceAcentos <- function(x) {stri_trans_general(x, "Latin-ASCII")}
corpus.pro <- tm_map(corpus.pro, replaceAcentos)
inspect(corpus.pro[10])

# Eliminamos espacios que se van generando con los reemplazos
corpus.pro <- tm_map(corpus.pro, stripWhitespace)
inspect(corpus.pro[10])

####################################################################
####### Generación de la Matríz Término-Documento del corpus #######
####################################################################

dtm <- TermDocumentMatrix(corpus.pro, 
                          control = list(weighting = "weightTf"))

# Resumen de la dtm (document-term matrix)
dtm

matriz_td <- as.matrix(dtm)
View(matriz_td)


################################################################
####### Conteos de frecuencia de los términos del corpus #######
################################################################

# Calculamos la frecuencia de cada término en el corpus
freq_term <- sort(rowSums(matriz_td),decreasing=TRUE)

# Generamos un dataframe con esta sumatoria (de rows)
df_freq <- data.frame(termino = names(freq_term), frecuencia=freq_term)

# Reseteamos el índice (sino era el término "dueño" de la frecuencia)
row.names(df_freq) <- NULL

# Dataframe con frecuencia de términos
df_freq

# Gráfico de barras con los N más frecuentes
N=15
barplot(df_freq[1:N,]$frecuencia, las = 2, names.arg = df_freq[1:N,]$termino,
        col ="lightblue", main ="Palabras más frecuentes",
        ylab = "Frecuencia de palabras", ylim = c(0, max(df_freq$frecuencia)+300))

#######################################################
###################### WORDCLOUD ######################
#######################################################

topK = head(df_freq, 100)

# Visualización de los resultados
# Nube de Etiquetas
library("wordcloud")
library("RColorBrewer")

par(bg="grey30") # Fijamos el fondo en color gris

set.seed(1234)
wordcloud(words = topK$termino, freq = topK$frecuencia, min.freq = 1,
          max.words=200, random.order=FALSE, rot.per=0.35, 
          colors=brewer.pal(4, "Dark2"))

# Parámetros
# words : the words to be plotted
# freq : their frequencies
# min.freq : words with frequency below min.freq will not be plotted
# max.words : maximum number of words to be plotted
# random.order : plot words in random order. If false, they will be plotted in decreasing frequency
# rot.per : proportion words with 90 degree rotation (vertical text)
# colors : color words from least to most frequent. Use, for example, colors =“black” for single color.

######################################################
#### Ley de Zipf (sobre el corpus sin preprocesar ####
######################################################

# Creo una función para no repetir código (podría reemplazar arriba también)
corpus2freq_term <- function(corpus_terminos) {
  dtm <- TermDocumentMatrix(corpus_terminos, control = list(weighting = "weightTf"))
  matriz_td <- as.matrix(dtm)
  freq_term <- sort(rowSums(matriz_td),decreasing=TRUE)
  df_frecuencias <- data.frame(termino = names(freq_term), frecuencia=freq_term)
  return(df_frecuencias)
}

df_freq_crudo <- corpus2freq_term(corpus)

# Histograma
par(bg="white") # Fijamos el fondo en color blanco
hist(df_freq_crudo$frecuencia, xlab='Cantidad de términos', ylab='Frecuencia observada', main='Histograma')

# Plot de líneas
plot(df_freq_crudo$frecuencia[1:150], type='l', xlab='Cantidad de términos', ylab='Frecuencia observada', main='Plot con frequencias')

