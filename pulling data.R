# set your directory
setwd("C:/Users/583413/Documents/GitHub/rtwitter-viz")

##twitter test
library(rtweet)
library(tidytext)
library(tm)
library(data.table)

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

# cnn_text <- cnn$text
# cnn_corp = Corpus(VectorSource(cnn_text))
# 
# 
# cnn_small = cnn%>%select(text)
# cnn_tidy = cnn_small %>% unnest_tokens(word, text)
# 
# gsub(stop_words$word, "", cnn$text)

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

# remove extra whitespaces
cnn_corp <- tm_map(cnn_corp, content_transformer(stripWhitespace))

inspect(cnn_corp)

#### frequency of words
cnn_terms = TermDocumentMatrix(cnn_corp)
cnn_terms_count = sort(rowSums(as.matrix(cnn_terms)), decreasing = T)
head(cnn_terms_count)

# the thurst of sentiment analysis is the delta between positive and negative words in text
afinn = get_sentiments("afinn") # this dictionary maps sentiment scores to words

cnn_df <-data.frame(text=sapply(cnn_corp, identity), 
                       stringsAsFactors=F)

cnn_df = cnn_df%>%unnest_tokens(word, text)
cnn_df$linenumber = gsub('\\..*', '', row.names(cnn_df)%>%as.numeric())

test <- cnn_df %>% 
  left_join(get_sentiments("afinn")) %>% 
  group_by(linenumber) %>% 
  summarise(sentiment = sum(value)) %>% 
  mutate(method = "AFINN")

