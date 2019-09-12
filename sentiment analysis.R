
trumps = trump2%>%select(text, created_at, favorite_count, retweet_count)%>%
  mutate(created_at = ymd_hms(created_at))%>%
  filter(created_at > "2019-07-31",
         created_at < "2019-09-01")%>%
  mutate(linenumber = row_number())

trump_text = trumps%>%select(text)%>%
  mutate(text = gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", trumps$text),
         linenumber = row_number())%>% #this allows us to retain the row number
  unnest_tokens(word, text)

trump_ranks = trump_text%>%anti_join(stop_words)%>% #removes common words (stop words)
  left_join(get_sentiments("afinn"))

trump_sent = trump_text%>%anti_join(stop_words)%>% #removes common words (stop words)
  left_join(get_sentiments("afinn")) %>% 
  group_by(linenumber) %>% 
  summarise(sentiment = sum(value, na.rm = T)) %>% 
  mutate(method = "AFINN")%>%
  right_join(., trumps, by = "linenumber")%>%
  mutate(date = substr(created_at, 1,10))

write.csv(trump_sent, "trump_sent.csv")

trump_month = trump_sent%>%group_by(date)%>%
  summarise(sentiment = sum(sentiment, na.rm =T))

#first we need to tokenize the tweets
ab_text = ab%>%select(text)%>%
  mutate(text = gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", ab$text),
         linenumber = row_number())%>% #this allows us to retain the row number
  unnest_tokens(word, text)


ab_sent = ab_text%>%anti_join(stop_words)%>% #removes common words (stop words)
  left_join(get_sentiments("afinn")) %>% 
  group_by(linenumber) %>% 
  summarise(sentiment = sum(value, na.rm = T)) %>% 
  mutate(method = "AFINN")

ab_final = ab%>%
  mutate(linenumber = row_number())%>%
  left_join(., ab_sent, by = "linenumber")

sad = ab_final%>%arrange(sentiment)
sadness = sad[1:10,5]
happy = ab_final%>%arrange(desc(sentiment))
happyness = happy[1:10,5]

write.csv(sadness, "sadness.csv")
write.csv(happyness, "happyness.csv")

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
cnn_df <-data.frame(text=sapply(cnn_corp, identity), #creating dataframe to use tidytext
                    stringsAsFactors=F)

cnn_df = cnn_df%>%unnest_tokens(word, text) #tokenizing cnn_df
cnn_df$linenumber = gsub('\\..*', '', row.names(cnn_df)%>%as.numeric()) #creating line number

cnn_sent <- cnn_df %>% 
  left_join(get_sentiments("afinn")) %>% 
  group_by(linenumber) %>% 
  summarise(sentiment = sum(value, na.rm = T)) %>% 
  mutate(method = "AFINN")

cnn$linenumber = row.names(cnn)

final = left_join(cnn, cnn_sent, by = "linenumber")%>%
  select(screen_name, text, created_at, sentiment)


#### visualization
final$date = ymd(substr(final$created_at, 1, 10))

cnn_day = final%>%group_by(date)%>%
  summarise(avg = mean(sentiment))

#getting the day of the week
cnn_day$day = wday(cnn_day$date)

ggplot(cnn_day, aes(variable, Name)) + geom_tile(aes(fill = rescale),
                                                 +     colour = "white") + scale_fill_gradient(low = "white",
                                                                                               +     high = "steelblue")
