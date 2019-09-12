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

I originally wanted to measure how positive or negative the news was by day for a month, so I pulled the max number of tweets (3,200) for CNN. Unfortunately, this resulted in pulling back about a week and a half of tweets. It appears that CNN--and every other news organization I looked into--simply tweets too much. You can get more tweets with a premium account, but I do not have that and also do not want to pay for it. 

So the hunt was on. I needed someone who tweets at least once a day but no more than ten times a day. Someone who has expressive but simple tweets that would be easy to analyze with an algorhtm. I wanted someone well known with tweets that we interesting to read. I tried Kayne West and Antonio Brown--both of whom were well known for social media miscues, but they did not tweet enough. I tried a few presidential candidates, but their tweets appear to be managed by teams and are not expressive and interesting to read. 

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
