# twitter-viz

Monday, Tuesday, Happy Days! Thursday, Friday, Happy Days! etc etc

The Happy Days theme song, while wonderful, does not answer the important question of how do we actual measure these "happy days". What the Fonz will not tell you is that there is a programmatic way to measure such a thing. 

Enter R and the rtweets and tidytext packages. For this project, I am going to first scrape twitter data using the rtweets and then perform a basic sentiment analysis using the tidytext package. 

But first, the final product:


![alt text](https://github.com/corydonbaylor/twitter-viz/blob/master/Rplot.png?raw=true)


### Scraping the Data
The rtweets package makes getting twitter data shockingly easy. Both the api call and cleaning response are largely abstracted away. All it takes is a single line of code to get a tidy dataframe of twitter data. But before we can do that, we need to set up access to use twitter's API. I believe that how we do this is best captured on twitters on website rather than here. But essentially, you need a twitter account and the ability to answer a few simple questions. 

Once you do get access, however, you will need to show authenticate your api call using the keys from your access. For rtweets, this should be as simple as plugging them into the correct arguement:
```
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

```
If you are working with git, I would suggest saving your keys in a seperate file and putting that in a gitignore so that you aren't sharing this information with everyone when you share your code.

Once you have authorized yourself, getting the actual data will be very simple. You can look up tweets by subject or by hashtag among a large list of other things, but I wanted to see how happy the days were for a particular user. 

To do this, I needed someone who tweets at least once a day but no more than ten times a day (due to the limit on the number of tweets I can pull back). Someone who has expressive but simple tweets that would be easy to analyze with an algorithm. I wanted someone well known-- with tweets that we interesting to read. I tried Kayne West and Antonio Brown--both of whom were well known for social media miscues, but they did not tweet enough. I tried a few presidential candidates, but their tweets appear to be managed by teams and are not expressive and interesting to read. 

Eventually I landed where I knew that I was going to land but really didnt want to land--with Donald Trump. The reason I did not want to use Trump's twitter is because I did not want this project to be viewed through a political lense, which is obviously inescapable with Trump. But do to the nature of his tweets and golden zone frequency of his tweeting, I realized that his twitter is the obvious choice for an analysis such as this. 

See below for how to pull a user's tweets:
```
#cnn
cnn = get_timeline("cnn", n=3200)
fwrite(cnn, "cnn.csv")

#antonio brown
ab = get_timeline("AB84", n =3200)
fwrite(ab, "ab.csv")

#trump
trump = get_timeline("realDonaldTrump", n=3200)
fwrite(trump2, "trump.csv")
```
### Sentiment Analysis i.e. Counting Happy Words
Sentiment analysis sounds very advanced, but at its heart, its really just about counting up positive and negative words and assuming a net positive value means a positive sentiment. 

So how do we go about doing this? Step one, as with any analysis is getting the data in the right format. We need to do something called tokenizing. Tokenizing breaks a large string--in this case a tweet-- into its essential elements--in this case words. But tokens do not need to be words. They can be words, phrases, or even whole sentences. But for now, lets stick with words. 

We are going to be using the tidytext package for sentiment analysis. I think its easier to work in dataframes instead of corpuses like "tm" does. Tidytext fits in nicely with other tidyverse packages making it a no brainer for me.

One more thing to note. We need to keep track of what tweet each token belongs to, that way we can get the sentiment for the tweet overall. We will create a linenumber variable to do this.
```
# we need to tokenize the text (make each line a word while retaining which tweet it comes from)
trump_text = trumps%>%select(text)%>%
  mutate(text = gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", trumps$text),
         linenumber = row_number())%>% #this allows us to retain the row number/the tweet
  unnest_tokens(word, text) # this unnests the tweets into words
 ```
 After tokenizing using tidytext, each row will be a word and there will be a variable for line numbers as well.  
 
Next, using dplyr we will remove "stop words". Stop words are words with very little or no semantic meaning--think words like "the", "as" or "of". I think a better name for them would have been "helper words" since they primarily serve to connect meaningful words together as their purpose more closely aligns to grammar than vocabulary in my opinion. However, to remove them, we use an anti-join. 
```
trump_text%>%anti_join(stop_words)
```
Next, we find the sentiments of the remaining words. Again, using the tidyverse way, we can do a left join on a sentiment dictionary to get different sentiment scores. Tidytext makes this easy. Just use the below command:
```
trump_text%>%anti_join(stop_words)%>% #removes common words (stop words)
  left_join(get_sentiments("afinn"))
```
Finally, we are going to group back up to the tweet level using the line number that we created earlier, and join back to the original dataset. The whole process looks like this:
```
trump_sent = trump_text%>%anti_join(stop_words)%>% #removes common words (stop words)
  left_join(get_sentiments("afinn")) %>% # gets sentiment score based on afinn dictionary
  group_by(linenumber) %>% 
  summarise(sentiment = sum(value, na.rm = T)) %>% # sums up the sentment to the tweet level 
  right_join(., trumps, by = "linenumber")%>% # joins back to the original dataset with the sentiment score
  mutate(date = substr(created_at, 1,10))
 ```
 And with that we now have the sentiment score for each of Trumps tweets!

### Making a Heatmap Calendar
I wanted to make a somewhat obscure visualization for this dataset. Its time series data technically but I didn't want a line graph because those can be a bit boring. Instead, I wanted a cleaner version of the little heatmap that shows up for commits under github. 

To do this, I used the geom_tile from ggplot2. The rows would be weeks and the columns would be the day of the week--just like any other calendar. Doing this was a little harder than I orginally imagined, though as always with coding, once you have the actual code it looks quite easy. Using lubridate, you can get the day of the week using the "wday()" command. And you can get the week number--ie how many weeks have passed this year--using the "isoweek()" command. 

The issue is that isoweeks start on Monday not Sunday, so you will have to use an ifelse statement to move Sundays up a week. Also geom_tile will display the earlier weeks at the bottom of the plot--as one would expect with a bar graph--instead of at the top--as one would expect with a calendar. So you will need to set the weeks as reverse the weeks and set them as an ordered factor. Take a look at the code below:
```
trump_month = trump_sent%>%group_by(date)%>%
  summarise(sentiment = sum(sentiment, na.rm =T))%>%
  # to create the plot we need to be able to organzie with days as the columns and week number as the rows
  mutate(weekday =  
         factor(wday(date), labels = c("Sun", "Mon", "Tues", "Wed", "Thu", "Fri", "Sat"))
         )%>% # this gives us an order factor variable for days
  mutate(day = day(date))%>% # we will use this to write in the date on the squares
  mutate(weeknum = isoweek(date))%>% # what number week it is--allows us to group days into weeks
  mutate(weeknum = ifelse(weekday == "Sun", weeknum +1, weeknum))%>% # iso says that monday is the first day of the week but we want     sunday to be the first day
  mutate(weeknum = factor(weeknum, rev(unique(weeknum)), ordered = T) # we want the earlier weeks at the top of the calendar
)
```
Finally we just need to make the actual visualization. This is the easy part (thankfully). All we are going here is setting the x and y for tiles, adding text (for the date) to appear within the tiles and removing extra things like gridlines and the legend. 

One little trick, that I didn't think was readily apparent, was to use scale_fill_gradient2 to make a diverging color scale centered around 0. Other than that, the inline comments should provide enough context to what was going on here.  
```
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
```
And there you have it! A heatmap calendar that shows the sentiment of Trump's tweets!
