library(tuber)       # web-scraping, connection to api-key
library(httpuv)      # necessary packet for connection to api key
library(tidyverse)   # data-manipulation and -plotting
library(tidytext)    # additional text mining functions
library(dplyr)       # data manipulation
library(SnowballC)   # text stemming
library(wordcloud)   # creating word-clouds
library(ggplot2)     # visualizations
library(igraph)      # manipulating & analyzing networks
library(ggraph)      # visualizing networks
library(widyr)       # analyze correlating words 



# ---- Scraping comment data from YouTube -----



# Connect to API Key
yt_oauth("api_id", "api_code", token = '')


# scrape all YouTube comments
vid_data1 <- get_all_comments(video_id = "3ZtedjN1JXY")



# ---- Data preparation ----



# create data frame only with comment-data
comments1 <- vid_data1$textOriginal
c_data1 <- tibble(line = 1:4388, text = comments1)


# tokenization to create a data frame where each row only contains one token
c_data1_t <- c_data1 %>%
  unnest_tokens(word, text)


# safe data frame as .csv file
write.csv(c_data1, "cdataWOW.csv")



# ---- Data preperation -----



# count most used words 
c_data1_t %>%
  count(word, sort = TRUE)


# cut out the stop words like I, the, of  ...
c_data1_nos <- c_data1_t %>%
  anti_join(stop_words)

c_data1_nos %>%
  count(word, sort = TRUE)


# convert all words to their root form
stemmed_data1 <- c_data1_nos %>%
  mutate(word = wordStem(word))

stemmed_data1 %>%
  count(word, sort = TRUE)



# ---- Basic text analysis ---- 



# count most frequent words
stemmed_data1 %>%
  count(word, sort = TRUE) %>%
  filter(n > 120) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(n, word)) +
  geom_col(fill = "cadetblue") +
  labs(x = "amount", y = "words")


# word cloud without stemming + filter out all numbers
c_data1_nos %>%
  filter(str_detect(word, "[a-z]")) %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 50, scale = c(2.5,.5),
                 random.order = FALSE, colors = brewer.pal(8, "Dark2")))


# word cloud with stemming + filter out all numbers
stemmed_data1 %>%
  filter(str_detect(word, "[a-z]")) %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 50, scale = c(2.5,.5),
                 random.order = FALSE, colors = brewer.pal(8, "Dark2")))



# --- Sentiment analysis ---



# there are different kinds of sentiment lexicons
get_sentiments("bing")    # sentiments in binary values
get_sentiments("afinn")   # sentiments in value range -5 <-> +5 
get_sentiments("nrc")     # sentiments described with words



# --- Sentiment analysis with lexicon 'bing'



# safe 'bing' sentiment in new data frame
bing_word_count <- stemmed_data1 %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  ungroup()


# general contribution of sentiment 
bing_word_count %>%
  group_by(sentiment) %>%
  ggplot(aes(n, sentiment, fill = sentiment)) +
  geom_col() +
  scale_fill_manual("legend", values = c("positive" = "cadetblue3", "negative" = "firebrick"))


# contribution of words split by sentiment
bing_word_count %>%
  group_by(sentiment) %>%
  slice_max(n, n = 10) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(n, word, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(x = "Contribution of sentiment", y = NULL) +
  scale_fill_manual(values = c("positive" = "cadetblue3", "negative" = "firebrick"))



# overall sentiment using 'bing' lexicon 
stemmed_data1 %>%
  inner_join(get_sentiments("bing")) %>%
  count(index = line %/% 20, sentiment) %>%
  pivot_wider(names_from = sentiment, values_from = n, values_fill = 0) %>%
  mutate(sentiment = positive - negative) %>%
  ggplot(aes(index, sentiment)) +
  geom_col(show.legend = FALSE, fill = "cadetblue") +
  geom_col(data = . %>% filter(sentiment < 0), show.legend = FALSE, fill = "firebrick") +
  geom_hline(yintercept = 0, color = "goldenrod") +
  labs(title = "bing sentiment")




# --- Sentiment analysis with lexicon 'afinn'



# sentiment value of each word using 'afinn' lexicon
afinn_sentiment <- stemmed_data1 %>%
  inner_join(get_sentiments("afinn"))


afinn_color <- c("red4","red3", "red1", "cadetblue1", "cadetblue2","cadetblue3","cadetblue")

# contribution of sentiments
afinn_sentiment %>%
  count(value) %>%
  filter(n > 1) %>%
  ggplot(aes(value, n)) +
  geom_col(fill = afinn_color) + 
  labs(y = "amount")


# overall sentiment using lexicon 'afinn'
afinn_sentiment %>%
  group_by(index = line %/% 20) %>%
  summarise(sentiment = sum(value)) %>%
  ggplot(aes(index, sentiment)) +
  geom_col(show.legend = FALSE, fill = "cadetblue") +
  geom_col(data = . %>% filter(sentiment < 0), show.legend = FALSE, fill = "firebrick") +
  geom_hline(yintercept = 0, color = "goldenrod") +
  labs(title = "afinn sentiment")


# overall sentiment using lexicon 'afinn' and color palette
afinn_sentiment %>%
  group_by(index = line %/% 20) %>%
  summarise(sentiment = sum(value)) %>%
  ggplot(aes(index, sentiment)) +
  geom_col(aes(fill = cut_interval(sentiment, n = 5))) +
  geom_hline(yintercept = 0, color = "goldenrod") +
  scale_fill_brewer(palette = "RdYlBu", guide = FALSE)



# --- sentiment analysis with lexicon 'nrc'



# sentiment nrc 
nrc_sentiment <- stemmed_data1 %>%
  inner_join(get_sentiments("nrc"))


# overall contribution of sentiments 
nrc_color = c("firebrick", "cadetblue3", "firebrick", "cadetblue3", "cadetblue3", "firebrick", "firebrick", "cadetblue3", "firebrick", "cadetblue3")

nrc_sentiment %>%
  count(sentiment, sort = TRUE) %>%
  mutate(sentiment = reorder(sentiment, n)) %>%
  ggplot(aes(n, sentiment)) +
  geom_col(fill = nrc_color) +
  labs(x = "amount")


# overall sentiment using lexicon 'nrc', !only looking on sentiments like = postive & negative!
nrc_sentiment %>%
  count(index = line %/% 20, sentiment) %>%
  pivot_wider(names_from = sentiment, values_from = n, values_fill = 0) %>%
  mutate(sentiment = positive - negative) %>%
  ggplot(aes(index, sentiment)) +
  geom_col(show.legend = FALSE, fill = "cadetblue") +
  geom_col(data = . %>% filter(sentiment < 0), show.legend = FALSE, fill = "firebrick") +
  geom_hline(yintercept = 0, color = "goldenrod") +
  labs(title = "nrc sentiment")



#---- Creating an overall rating score of the video using all 3 sentiment lexicons



# proportion of negative and positive words (bing lexicon)
bing_proportion_table <- stemmed_data1 %>%
  inner_join(get_sentiments("bing")) %>%
  count(sentiment)

bing_proportion <- prop.table(bing_score_table$n)

bing_proportion_table <- cbind(bing_proportion_table, bing_proportion)


# proportion of values (afinn lexicon)
afinn_proportion_table <- stemmed_data1 %>%
  inner_join(get_sentiments("afinn")) %>%
  count(value)


# weight values corresponding to their sentiment value
afinn_proportion_table$weighted_n <- afinn_proportion_table$n * c(3,2,1,1,2,3,4,5) 

afinn_proportion <- prop.table(afinn_proportion_table$weighted_n)

afinn_proportion_table <- cbind(afinn_proportion_table, afinn_proportion)

afinn_proportion_table <- data.frame(sentiment = c("negative", "postive"), 
                                     weighted_n = c(
                                       sum(afinn_proportion_table$weighted_n[afinn_proportion_table$value < 0]),
                                       sum(afinn_proportion_table$weighted_n[afinn_proportion_table$value > 0])), 
                                     afinn_proportion = c(
                                       sum(afinn_proportion_table$afinn_proportion[afinn_proportion_table$value < 0]),
                                       sum(afinn_proportion_table$afinn_proportion[afinn_proportion_table$value > 0])
                                     ))


# proportion of sentiments (nrc lexicon)
nrc_proportion_table <- stemmed_data1 %>%
  inner_join(get_sentiments("nrc")) %>%
  count(sentiment)


# give sentiment values to determine overall sentiment proportion 
nrc_proportion_table$value <- c(-1,1,-1,-1,1,-1,1,-1,1,1)

nrc_proportion <- prop.table(nrc_proportion_table$n)

nrc_proportion_table <- cbind(nrc_proportion_table, nrc_proportion)

nrc_proportion_table <- data.frame(sentiment = c("negative", "positive"), 
                                   n = c(
                                     sum(nrc_proportion_table$n[nrc_proportion_table$value < 0]),
                                     sum(nrc_proportion_table$n[nrc_proportion_table$value > 0])),
                                   nrc_proportion = c(
                                     sum(nrc_proportion_table$nrc_proportion[nrc_proportion_table$value < 0]),
                                     sum(nrc_proportion_table$nrc_proportion[nrc_proportion_table$value > 0])
                                   ))


# creating score-table 
overall_proportion_table <- data.frame(lexicon = c("bing","afinn","nrc"), 
                                       proportion_negative = c(
                                         bing_proportion_table[1,3],
                                         afinn_proportion_table[1,3],
                                         nrc_proportion_table[1,3]
                                       ))

# using cut-function to assign score to sentiment proportion
overall_proportion_table$sentiment_score <- cut(overall_proportion_table$proportion_negative, 
                                                breaks = c(1, 0.925, 0.875, 0.825, 0.775, 0.725, 0.675, 0.625, 0.575, 0.525, 0.475, 0.425, 0.375, 0.325, 0.275, 0.225, 0.175, 0.125, 0.075, 0),
                                                labels = c(9,8,7,6,5,4,3,2,1,0,-1,-2,-3,-4,-5,-6,-7,-8,-9))


# converting the cut-function column to numeric values because sum() cant work with factor values. 
overall_proportion_table[,3] <- as.numeric(as.character(overall_proportion_table[,3]))

overall_proportion_table$sentiment_score %>%
  sum()



# --- Calculating and visualizing relationships and correlations between words ---



# --- Creating and analyzing bigrams



# create 'bigrams' = tokens with 2 words each 
comment_bigrams <- c_data1 %>%
  unnest_tokens(bigram, text, token = "ngrams", n = 2)


# most common bigrams
comment_bigrams %>%
  count(bigram, sort = TRUE)


# seperate bigrams to filter out uninteresting bigrams existing only out of stop words.
bigrams_sep <- comment_bigrams %>%
  separate(bigram, c("word1", "word2"), sep = " ")

bigrams_fil <- bigrams_sep %>%
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word)

bigrams_fil_count <- bigrams_sep_fil %>%
  count(word1, word2, sort = TRUE)



# --- Using bigrams to provide context in sentiment analysis 



# search for bigrams with 1st word 'not' or 'no', to find negations
bigrams_sep %>%
  filter(word1 == "not" | word1 == "no") %>%
  count(word1, word2, sort = TRUE)


# using afinn lexicon to examine most frequent words that were preceded by 'not' or 'no' and associated with a sentiment.
not_words <- bigrams_sep %>%
  filter(word1 == "not" | word1 == "no") %>%
  inner_join(get_sentiments("afinn"), by = c(word2 = "word")) %>%
  count(word2, value, sort = TRUE)


# visualize the words that contributed the most in the wrong sentiment direction
not_words %>%
  mutate(contribution = n * value) %>%
  arrange(desc(abs(contribution))) %>%
  head(15) %>%
  mutate(word2 = reorder(word2, contribution)) %>%
  ggplot(aes(n * value, word2, fill = n * value > 0)) +
  geom_col(show.legend = FALSE) +
  geom_col(data = . %>% filter(contribution > 0), show.legend = FALSE, fill = "firebrick2", alpha = 0.9) +
  geom_col(data = . %>% filter(contribution < 0), show.legend = FALSE, fill = "darkolivegreen3") +
  labs(x = "Sentiment afinn value * number of occurence",
       y = "Words preceded by \"not\" or \"no\"")


# search for bigrams with 1st or 2nd word wow, to find out if wow is used for a sentiment or for a shortcut(wow = World of Warcraft)
bigrams_sep %>%
  filter(word1 == "wow" | word2 == "wow") %>%
  count(word1, word2, sort = TRUE)

ar1 <- grid::arrow(type = "closed", length = unit(.05, "inches"))

bigrams_sep %>%
  filter(word1 == "wow" | word2 == "wow") %>%
  count(word1, word2, sort = TRUE) %>%
  filter(n > 8) %>%
  graph_from_data_frame() %>%
  ggraph(layout = "fr") +
  geom_edge_link(aes(edge_alpha = n), arrow = ar1, end_cap = circle(.07, "inches")) +
  geom_node_point(color = "darkolivegreen2", size = 4, shape = 19) +
  geom_node_text(aes(label = name), repel = TRUE) +
  theme_void()



#--- Network of bigrams 



# filter out common combinations & convert it to graph data
bigram_graph <- bigrams_fil_count %>%
  filter(n > 8) %>%
  na.omit %>%
  graph_from_data_frame()


# visualize graph + set.seed(17) to avoid random output
ar2 <- grid::arrow(type = "closed", length = unit(.15, "inches"))

set.seed(17)
ggraph(bigram_graph, layout = "fr") +
  geom_edge_link(aes(edge_alpha = n), show.legend = FALSE,
                 arrow = ar2, end_cap = circle(.07, "inches")) +
  geom_node_point(color = "darkolivegreen2", alpha = 0.7, size = 4, shape = 19) +
  geom_node_text(aes(label = name), repel = TRUE) +
  theme_void()



# --- Most used Trigrams 



set.seed(17)
c_data1 %>%
  unnest_tokens(trigram, text, token = "ngrams", n = 3) %>%
  separate(trigram, c("word1", "word2", "word3"), sep = " ") %>%
  filter(!word1 %in% stop_words$word,
         !word2 %in% stop_words$word,
         !word3 %in% stop_words$word) %>%
  count(word1, word2, word3, sort = TRUE) %>%
  filter(n > 5) %>%
  na.omit 



# --- Correlating pairs (co-occurring words in a comment)



# examine correlation among words in each comment using 'phi coefficient' + visualizing correlations as a network
set.seed(17)
c_data1 %>%
  unnest_tokens(word, text) %>%
  filter(str_detect(word, "[a-z]")) %>%
  anti_join(stop_words) %>%
  group_by(word) %>%
  filter(n() >= 20) %>%
  pairwise_cor(word, line, sort = TRUE) %>%
  filter(correlation > .25) %>%
  graph_from_data_frame() %>%
  ggraph(layout = "fr") +
  geom_edge_link(aes(edge_alpha = correlation), show.legend = FALSE) +
  geom_node_point(color = "darkolivegreen2", alpha = 0.7, size = 4, shape = 19) +
  geom_node_text(aes(label = name), repel = TRUE) +
  theme_void()
