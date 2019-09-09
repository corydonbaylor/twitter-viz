# set your directory
setwd("C:/Users/583413/Documents/GitHub/rtwitter-viz")

##twitter test
library(rtweet)
library(tidytext)
library(tm)

#load keys in a seperate file--put this in the git ignore so that you arent publishing your API access
source("keys.R")

#create the token
twitter_token <- create_token(
  app = app_details$name,
  consumer_key = app_details$con_key,
  consumer_secret = app_details$con_secret,
  access_token = app_details$access_key,
  access_secret = app_details$access_secret
)

cnn = get_timeline("cnn", n =100)

cnn_text <- cnn$text
cnn_corp = Corpus(VectorSource(cnn_text))

#due to the structure of tm's corprus, print wont show much. Instead use inspect:
inspect(cnn_corp)

# now we begin cleaning the corpus into a machine readible format
cnn_corp = tm_map(cnn_corp, removePunctuation) # remove punctuation
cnn_corp <- tm_map(cnn_corp, content_transformer(tolower)) # lower case

#lets remove stop words
cnn_corp <- tm_map(cnn_corp, function(x)removeWords(x,stopwords()))

#lets also remove hyperlinks
removeURL <- function(x) gsub("http[[:alnum:]]*", "", x)
cnn_corp <- tm_map(cnn_corp, content_transformer(removeURL))

inspect(cnn_corp)

#### frequency of words
cnn_terms = TermDocumentMatrix(cnn_corp)
cnn_terms_count = sort(rowSums(as.matrix(cnn_terms)), decreasing = T)
head(cnn_terms_count)

# the thurst of sentiment analysis is the delta between positive and negative words in text
nrc = get_sentiments("nrc") # this dictionary maps sentiment scores to words
