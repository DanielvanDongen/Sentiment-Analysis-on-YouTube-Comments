# Sentiment-Analysis-on-YouTube-Comments


## 1. Introduction 

Since November 2021, YouTube has deactivated the dislike function under each video and therefore an evaluation of the quality of a video is no longer possible or can only be estimated in a roundabout way. <br />
The objective of my analysis is to estimate the quality of a video based on the comments and determine what viewers liked or disliked about it. <br />
The video chosen for the analysis is the trailer of the new *World of Warcraft* expansion *Dragonflight*. <br />


<p>&nbsp;</p>


## 2. Methods

The programming language used for the preparation, analysis and visualization of the data was R. <br />
The analysis consists of 5 main parts, which are explained below.

| Web-scraping | Text-analysis | Sentiment-Analysis | Sentiment-Score | N-grams & Correlations |
| :----------- | :------------ | :----------------- | :-------------- | :--------------------- |

### 2.1 Web scraping
The first part of the analysis was to scrape all comments existed and safe them in a appropriate format. <br />
Being able to scrape all YouTube comments was possible through using an R-package called 'tuber'. <br />
This package enabled to connect to the Google Cloud API key and download all comments available.
```
vid_data1 <- get_all_comments(video_id = "3ZtedjN1JXY")
```
For privacy reasons all usernames and other columns besides original text weren't used further.

### 2.2 Text-analysis + Preperation
To analyze the text some preparations were made. That includes the transformation to a 'tidy-format' which means that the table was transformed to a one token per row format (token = unit of text, can be one word or multiple ones (n-grams)). In addition the text was cleaned throught deleting all stop words (e.g. the, of, I) and converting all words to their root form (words without affixes). <br />
Now that the text is in a appropriate format the text-analysis could begin that includes counting the most frequent words and visualizing them through a wordcloud.


| most frequent words | word cloud | 
| :------------------ | :--------- | 
| ![most_frequent_words](https://user-images.githubusercontent.com/104349890/168629988-0241a141-072c-4ec1-875a-c423d4fa3da6.png)| ![wordcloud_stemmed_nonumbers](https://user-images.githubusercontent.com/104349890/168629700-83ac6719-be86-4093-9ba0-6e184e4615e5.png) |

### 2.3 Sentiment-analysis
The third part was the sentiment analysis. In this part multiple sentiment lexicons were used to find out which sentiment each word represents. <br />
All lexicons used:  <br />
`bing` [Bing Liu and collaborators](https://www.cs.uic.edu/~liub/FBS/sentiment-analysis.html) <br />
`afinn` [Finn Årup Nielsen](http://www2.imm.dtu.dk/pubdb/pubs/6010-full.html) <br />
`nrc` [Saif Mohammad and Peter Turney](http://saifmohammad.com/WebPages/NRC-Emotion-Lexicon.htm) <br />
<p>&nbsp;</p>
To analyze the overall sentiment, sections were created that existed out of 20 comments each. <br />
Whereas the overall sentiment represents the sum of the sentiment content of the individual words. <br />
(1 index = summarised sentiment content of 20 comments) <br />

| bing | afinn | nrc |
| :--- | :---- | :-- |
|![bing_overall_sentiment](https://user-images.githubusercontent.com/104349890/168635643-08b32d9b-93d9-45f6-9003-5a671e363065.png)|![afinn_contribution_sentiment](https://user-images.githubusercontent.com/104349890/168635721-aa867605-2ab9-4745-89f5-8f68f439d2af.png)|![nrc_sentiment](https://user-images.githubusercontent.com/104349890/168635740-dcc94227-b20e-4f1e-9f1f-a61d32461b7e.png)|

### 2.4 Sentiment-score
As we can see above the overall sentiment differs according to the lexicon used. <br />
For this reason, the sentiment score was created by calculating the total proportion of sentiments from each lexicon, applying a score to each proportion and combining them into an overall sentiment score. <br />

| `sentiment` | `bing_prop` | `afinn_prop` | `nrc_prop` | 
| :---------- | :---------- | :----------- | :--------- |
| negative    | 0.5971      | 0.4210       | 0.5439     | 
| positive    | 0.4029      | 0.5790       | 0.4561     |

These proportions were rated with a sentiment score that includes values from -9 to +9 (0 included). <br />
| lexicon | sentiment score |
| :------ | :-------------- |
| bing    | -2              |
| afinn   | +2              |
| nrc     | -1              |

These sentiment scores sum up to an overall sentiment score of -1. <br />
This score represents the overall sentiment of the viewership, so based on the comments there are a little bit more people which disliked this video. <br />
But keep in mind that this score can be strongly distorted because multiple problems like negations or words like 'wow' (standing for World of Warcraft instead of a positive sentiment) werent included.


### 2.5 N-grams & Correlations
In the last part of this analysis the goal was to find out what people liked or disliked about video and examine the problems we talked above (negations, misinterpreted words). <br />
This was possible due to analyzing consecutive sequences of words, called n-grams and analyzing the co-occurences of words in each comment using the phi coefficient to calculate binary correlation. <br />

Beginning with n-grams, where we focused on using bigrams existing out of 2 consecutive words. <br /> 

Using bigrams to provide context in sentiment analysis:
| words that contributed most in the wrong direction (negations) | words that were adjacent to 'wow'  |
| :------------------------------------------------------------- | :--------------------------------- |
| ![sentiment_negations](https://user-images.githubusercontent.com/104349890/168787598-f6da280a-39a4-4f70-9d45-4bf0c7c3f429.png) | ![wow_sentiment](https://user-images.githubusercontent.com/104349890/168786238-900a979e-db41-400d-a013-7827de52e1d7.png) |

Visualizing bigram network: 
| bigram network |
| :------------- |
| arrow direction sympolizes the word sequence <br /> arrow color intensity symbolizes the number of occurrences |
| ![bigram_network](https://user-images.githubusercontent.com/104349890/168792243-e648be3b-a6c2-40d9-8c37-c6d99afa728c.png) |

As we can see there are multiple interesting connections that give insight about what people may liked or disliked about the new expansion. <br /> 
For example many people used consecutive combination between words like 'worst -> wow -> cinematic' & 'boring -> trailer' & 'worst -> expansion -> trailer' & 'marketing/art -> team -> ruin' which implies that many people may disliked the work of the marketing/art team and perceive the new cinematic/trailer/expansion as boring/worst. <br />

But there are also good combinations of consecutive words like 'amazing -> video' & 'cool -> anti -> heroes' or the comparison the older expansions like vanilla which implies that the video quality, the protagonists symbolizing the bad guys and the game in general were perceived as good. <br />

Ending with correlations:
| correlation network |
| :------------------ |
| no arrows because relationships are symmetrical <br /> line color intensity symbolizes the number of occurences |
| ![correlation](https://user-images.githubusercontent.com/104349890/168800581-969cb1b6-31d9-4580-a25f-28a87e717248.png) |

As we can see many words that co-occured were words like 'art - team - cut - video - amazing' & ' dragonflight - cataclysm - legion- shadowlands vanilla' which indicates that many people liked the work of the art team and also compare the new expansion to the older ones what can be either good or bad related to which expansion was meant and how people felt about them. <br />

The correlation network shows that looking at bigrams alone can lead to misinterpretation of comments. However, using both methods to gain deeper insight and comparing them, one can understand quite well what viewers liked or disliked the most.

<p>&nbsp;</p>


## 3. Data
All data used for this analysis was scraped from the youtube video published by Blizzard. [Click here for video](https://www.youtube.com/watch?v=3ZtedjN1JXY&t=47s) <br />
Keep in mind that the data that was analyzed only includes all comments that were written till 05/05/2022(d-m-Y). <br />


<p>&nbsp;</p>


# 4. Sources

Mainly this analysis was based on the work done by Julia Silge and David Robinson. <br />
But it also included some insperations from John Little.

- [Text Mining with R (Julia Silge & David Robinson)](https://www.tidytextmining.com/) / [license](https://creativecommons.org/licenses/by-nc-sa/3.0/us/)
- [Sentiment analysis with tidytext (John Little)](https://www.youtube.com/watch?v=P5ihIzoZivc&t=1613s) 
- [textmining workshop (John Little)](https://github.com/libjohn/workshop_textmining) / [license](https://github.com/libjohn/workshop_textmining/blob/main/license.txt)
