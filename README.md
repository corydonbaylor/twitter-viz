# twitter-viz

Monday, Tuesday, Happy Days! Thursday, Friday, Happy Days! Saturday, Sunday, Happy Days!

The Happy Days theme song, while wonderful, does not answer the important question of how do we actual measure these "happy days". What the Fonz will not tell you--dont even bother asking!--is that there is a programtic way to measure such a thing. 

Enter R and the rtweets and tidytext packages. For this project, I am going to first scrape twitter data using the rtweets and then perform a basic sentiment analysis using the tidytext package. 

### Scraping the data
The rtweets package makes getting twitter data shockingly easy. Both the api call and response are largely abstracted away. All it takes is a single line of code to get a tidy dataframe of twitter data. But before we can do that, we need to set up access to use twitters API. I believe that how we do this is best captured on twitters on website rather than here. But essentially, you need a twitter account and the ability to answer a few simple questions. 

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

Once you have authorized yourself, getting the actual data will be very simple. You can look up tweets by subject or by hashtag amoung a large list of other things, but I wanted to see how happy the days were for a particular user. 

I needed someone who tweets at least once a day but no more than ten times a day. Someone who has expressive but simple tweets that would be easy to analyze with an algorithm. I wanted someone well known with tweets that we interesting to read. I tried Kayne West and Antonio Brown--both of whom were well known for social media miscues, but they did not tweet enough. I tried a few presidential candidates, but their tweets appear to be managed by teams and are not expressive and interesting to read. 

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
Sentiment analysis sounds very advanced, but at its heart, its really just about counting up positive and negative words and assuming a positive value means a positive sentiment. 

So how do we go about doing this? Step one, as with any analysis is getting the data in the right format. We need to do something called tokenizing. Tokenizing breaks a large string--in this case a tweet-- into its essential elements--in this case words. But tokens do not need to be words. They can be words, phrases, or even whole sentences. But for now, lets stick with words. 

We are going to be using the tidytext package for sentiment analysis. I think its easier to work in dataframes instead of corpuses like "tm" does. Tidytext fits in nicely with other tidyverse packages making it a no brainer for me.

One more thing to note. We need to keep track of what tweet each token belongs to, that way we can get the sentiment for the tweet overall. 
```
# we need to tokenize the text (make each line a word while retaining which tweet it comes from)
trump_text = trumps%>%select(text)%>%
  mutate(text = gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", trumps$text),
         linenumber = row_number())%>% #this allows us to retain the row number/the tweet
  unnest_tokens(word, text) # this unnests the tweets into words
 ```
 After tokenizing using tidytext, each row will be a word and there will be a variable for line numbers as well.  
 
 Next, using dplyr we will remove 
