setwd("C:/Users/583413/Documents/GitHub/twitter-viz")
library(tidytext)
library(dplyr)
library(ggplot2)
library(lubridate)

trump = read.csv("data/trump.csv")

trumps = trump%>%select(text, created_at, favorite_count, retweet_count)%>%
  mutate(created_at = ymd_hms(created_at))%>%
  filter(created_at >= "2019-08-01", #we just want tweets from august
         created_at < "2019-09-01")%>%
  mutate(linenumber = row_number())

# we need to tokenize the text (make each line a word while retaining which tweet it comes from)
trump_text = trumps%>%select(text)%>%
  mutate(text = gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", trumps$text),
         linenumber = row_number())%>% #this allows us to retain the row number/the tweet
  unnest_tokens(word, text) # this unnests the tweets into words


trump_sent = trump_text%>%anti_join(stop_words)%>% #removes common words (stop words)
  left_join(get_sentiments("afinn")) %>% # gets sentiment score based on afinn dictionary
  group_by(linenumber) %>% 
  summarise(sentiment = sum(value, na.rm = T)) %>% # sums up the sentment to the tweet level 
  right_join(., trumps, by = "linenumber")%>% # joins back to the original dataset with the sentiment score
  mutate(date = substr(created_at, 1,10)) # cleans up created_at var

write.csv(trump_sent, "trump_sent.csv")


# now we have the sentiment scores for each tweet, we want to know what he was thinking on that day
# lets sum instead of the average that way we better capture his overall intensity rather than his average intensity
trump_month = trump_sent%>%group_by(date)%>%
  summarise(sentiment = sum(sentiment, na.rm =T))%>%
  # to create the plot we need to be able to organzie with days as the columns and week number as the rows
  mutate(weekday =  
         factor(wday(date), labels = c("Sun", "Mon", "Tues", "Wed", "Thu", "Fri", "Sat"))
         )%>% # this gives us an order factor variable for days
  mutate(day = day(date))%>% # we will use this to write in the date on the squares
  mutate(weeknum = isoweek(date))%>% # what number week it is--allows us to group days into weeks
  mutate(weeknum = ifelse(weekday == "Sun", weeknum +1, weeknum))%>% # iso says that monday is the first day of the week but we want sunday to be the first day
  mutate(weeknum = factor(weeknum, rev(unique(weeknum)), ordered = T) # we want the earlier weeks at the top of the calendar
)

trump_month

# creating plot 

ggplot(trump_month, aes(x= weekday, y =weeknum, fill = sentiment))+ 
  geom_tile(color = "#323232")+ # makes the lines a bit more muted
  geom_text(label = trump_month$day, size =4, color = "black")+ # days
  # positive days should be green and negative ones should be red
  scale_fill_gradient2(midpoint = 0, low = "#d2222d", mid = "white", high = "#238823")+ 
  # we are going to remove the majority of the plot 
  theme(axis.title = element_blank(),
        panel.background = element_blank(),
        axis.ticks = element_blank(),
        axis.text.y = element_blank(),
        legend.text = element_blank(),
        legend.position = "none",
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(color = "#323232")
        )+
  labs(title = "This August in Tweets", 
       subtitle = "A Sentiment Analysis of President Trump's Tweets",
       caption = "Darker Green = More Positive\nDarker Red = More Negative")

