# set your directory
setwd("C:/Users/583413/Documents/GitHub/rtwitter-viz")

##twitter test
library(rtweet)
library(tidytext)
library(tm)
library(data.table)
library(twitteR)

#load keys in a seperate file--put this in the git ignore so that you arent publishing your API access
source("keys.R")

setup_twitter_oauth(
  consumer_key = app_details$con_key,
  consumer_secret = app_details$con_secret,
  access_token = app_details$access_key,
  access_secret = app_details$access_secret
)

searchTwitter("#trump", n =1)
mw = userTimeline("marwilliamson", n = 500, excludeReplies = T)
mw = twitteR::twListToDF(mw)

a2 = userTimeline("realDonaldTrump", n = 500)
b2 = twitteR::twListToDF(a2)



#create the token
twitter_token <- create_token(
  app = app_details$name,
  consumer_key = app_details$con_key,
  consumer_secret = app_details$con_secret,
  access_token = app_details$access_key,
  access_secret = app_details$access_secret
)

#cnn
cnn = get_timeline("cnn", n=3200)
fwrite(cnn, "cnn.csv")

#antonio brown
ab = get_timeline("AB84", n =3200)
fwrite(ab, "ab.csv")

#trump
trump = get_timeline("realDonaldTrump", n=3200)
fwrite(trump2, "trump.csv")

# after looking at the tweets, lets stick to using trumps!
