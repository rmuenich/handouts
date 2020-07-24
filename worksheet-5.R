## RegEx - extract patterns from strings (video 1)

library(stringr)

str_extract_all('Email info@sesync.org or tweet @SESYNC for details!',
                '\\b\\S+@\\S+') # extracts email string

library(tm)

enron <- VCorpus(DirSource("data/enron")) #load enron email data
email <-enron[[1]] #assign first element of enron to email object
meta(email)
content(email)

match <- str_match(content(email), '^From: (.*)') #searching for 'from'
head(match)


#txt <- ...
#str_match(txt, '...')

## Data Extraction

enron <- tm_map(enron, function(email) { #assigns from as author in metadata
  body <- content(email)
  match <- str_match(body, '^From: (.*)')
  match <- na.omit(match)
  meta(email, 'author') <- match[[1, 2]]
  return(email)
})

## Relational Data Extraction (video 2)

get_to <- function(email) { #extracts "to" information from emails
  body <- content(email)
  match <- str_detect(body, '^To:')
  if (any(match)) {
    to_start <- which(match)[[1]]
    match <- str_detect(body, '^Subject:')
    to_end <- which(match)[[1]] - 1
    to <- paste(body[to_start:to_end], collapse = '')
    to <- str_extract_all(to, '\\b\\S+@\\S+\\b')
    return(unlist(to))
  } else {
    return(NA)
  }
}

email<-enron[[2]]
get_to(email) #run function on the one email



edges <- lapply(enron, FUN = function(email) { #loops through all emails and extracts author and from and to lines
  from <- meta(email, 'author') 
  to <- get_to(email)
  return(cbind(from, to))
})
edges <- do.call(rbind, edges)
edges <- na.omit(edges)
attr(edges, 'na.action') <- NULL

dim(edges) #tells how many relationships there are; 10,493 rows and 2 columns between to and from

library(network) #to visualize relationships

g <- network(edges)
plot(g) #visualizing network between to and from email recipients

## Text Mining (Video 3)

enron <- tm_map(enron, function(email) { 
  body <- content(email)
  match <- str_detect(body, '^X-FileName:')
  begin <- which(match)[[1]] + 1
  match <- str_detect(body, '^[>\\s]*[_\\-]{2}')
  match <- c(match, TRUE)
  end <- which(match)[[1]] - 1
  content(email) <- body[begin:end]
  return(email)
})

email <-enron[[2]]
content(email)

## Cleaning Text

library(magrittr)

enron_words <- enron %>% #clean with predefined functions; gives only words in email object
  tm_map(removePunctuation) %>%
  tm_map(removeNumbers) %>%
  tm_map(stripWhitespace)

email <- enron_words[[2]] #redfine email object
content(email)

remove_links <- function(body) { #create new function to remove links
  match <- str_detect(body, '(http|www|mailto)')
  body[!match]
}

enron_words <- enron_words %>%
  tm_map(content_transformer(remove_links))



## Stopwords and Stems; remove 'a' 'the' etc or stems link 'ing'

enron_words <- enron_words %>%
  tm_map(stemDocument) %>%
  tm_map(removeWords, stopwords("english"))

## Bag-of-Words; analyzing text to give count of frequency

dtm <- DocumentTermMatrix(enron_words)

## Long Form - so we can analyze bag of words

library(tidytext)
library(dplyr)
dtt <- tidy(dtm)
words <- dtt %>%
  group_by(term) %>%
  summarise(
    n = n(),
    total = sum(count)) %>%
  mutate(nchar = nchar(term))

library(ggplot2)
ggplot(words, aes(x=nchar)) +
  geom_histogram(binwidth = 1) #histogram of frequency of the number of characters in each word

dtt_trimmed <- words %>% #words with many characters are usually not words so need to trim
  filter(
    nchar < 16, #filter out any word with more than 16 characters
    n > 1,
    total > 3) %>%
  select(term) %>%
  inner_join(dtt)

dtm_trimmed <- dtt_trimmed %>% #didn't understand this step
  cast_dtm(document, term, count)

## Term Correlations

word_assoc <- findAssocs(dtm_trimmed, 'ken', 0.6) #correlations betwen ken (CEO of enron) and other terms
word_assoc <- data.frame(
  word = names(word_assoc[[1]]),
  assoc = word_assoc,
  row.names = NULL)

library(ggwordcloud)

ggplot(word_assoc,
       aes(label = word, size = ken)) +
  geom_text_wordcloud_area()

## Latent Dirichlet allocation (Video 4)
##conceptuallly similar to PCA; but LDA requires you to determine number of topics in advance
library(topicmodels)

seed = 12345 
fit = LDA(dtm_trimmed, k = 5, control = list(seed=seed)) #k=5 means there are 5 topics
terms(fit,20) #top 20 terms in topics

email_topics <- as.data.frame(
  posterior(fit, dtm_trimmed)$topics)
head(email_topics) #see numerical weights of terms


topics <- tidy(fit) %>%
  filter(beta > 0.004) #weight greater than .004

ggplot(topics, #word clouds of each topic; if get size warning increase size of plot frame & rerun code
  aes(size = beta, label = term)) +
  geom_text_wordcloud_area(rm_outside = TRUE) +
  facet_wrap(vars(topic))
