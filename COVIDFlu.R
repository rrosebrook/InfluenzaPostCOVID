rm(list=ls()) 


library(dplyr)
library(naniar)
library(stringr)
library(tidyverse)
library(ggplot2)
library(zoo)
library(forecast)
library(smooth)


# Respiratory infection data from FluView Interactive
# Obtained from the CDC 
# https://www.cdc.gov/flu/weekly/fluviewinteractive.htm
oldLabs <- read.csv("WHO_NREVSS_Combined_prior_to_2015_16.csv")
clinical <- read.csv("WHO_NREVSS_Clinical_Labs.csv")
publicLabs <- read.csv("WHO_NREVSS_Public_Health_Labs.csv")

# Flu mortality data from Influenza/Pnemonia Mortality by Starte
# Obtained from the CDC
# https://www.cdc.gov/nchs/pressroom/sosmap/flu_pneumonia_mortality/flu_pneumonia.htm
mortality <- read.csv("data-table.csv")


# Flu records are taken on a weekly basis while the public health data 
# summarizes by season.  To compensate, we must sum the weekly entries we have,
# where the flu season begins on the 40th week and ends on the 39th.

clinical2 <- clinical %>% 
  mutate(Season = clinical$YEAR)
clinical2 <- clinical %>% 
  mutate(Season = ifelse(WEEK >= 40, clinical2$Season + 1, clinical2$Season))
clinical2 <- clinical2 %>%
  mutate(Season = Season - 1)

oldLabs <- oldLabs %>% 
  mutate(Season = oldLabs$YEAR)
oldLabs <- oldLabs %>% 
  mutate(Season = ifelse(WEEK >= 40, 
                         oldLabs$Season + 1, oldLabs$Season))
oldLabs <- oldLabs %>%
  mutate(Season = Season - 1)

# For the public labs, we just need to clean up the column name.

publicLabs$SEASON_DESCRIPTION <- str_sub(publicLabs$SEASON_DESCRIPTION, 8, -4)


# We have very few NA values and when they do appear, we generally have no 
# values for any other year.  For this reason, we have chosen to 
# manage NA values by omitting them. In later exploratory analysis it was 
# discovered that entries for Virgin Islands were all 0.  As such, they've 
# been eliminated as well.

clinical2[clinical2 == "X"] <- NA
clinical2 <- clinical2 %>%
  na.omit()


publicLabs[publicLabs == "X"] <- NA
publicLabs <- publicLabs %>%
  na.omit()


oldLabs[oldLabs == "X"] <- NA
oldLabs <- oldLabs %>%
  na.omit()


# Combining A and B types as each report different sets of A and B

clinical2 <- transform(clinical2, TOTAL.A = as.numeric(TOTAL.A))
clinical2 <- transform(clinical2, TOTAL.B = as.numeric(TOTAL.B))

clinical2 <- clinical2 %>%
  group_by(REGION, Season) %>% 
  summarize(A = sum(TOTAL.A), B = sum(TOTAL.B))

publicLabs <- publicLabs[-c(1,4, 11)]
publicLabsnum <- publicLabs[2:8]
publicLabsnum <- mutate_all(publicLabsnum, function(x) as.numeric(as.character(x)))
publicLabs <- cbind(publicLabs$REGION, publicLabsnum)


colnames <- c("REGION", "Season",
              "A1", "A2", "A3", 
              "B1", "B2", "B3")
colnames(publicLabs) <- colnames

publicLabs <- publicLabs %>%
  group_by(REGION, Season) %>% 
  summarize(A = sum(A1, A2, A3), B = sum(B1, B2, B3))


oldLabs <- oldLabs[-c(1, 3:6, 13)]
oldLabs <- oldLabs[,c(1,8,2:7)]
oldLabsnum <-oldLabs[,2:8]
oldLabsnum <- mutate_all(oldLabsnum, function(x) as.numeric(as.character(x)))
oldLabs2 <- cbind(oldLabs$REGION, oldLabsnum)

colnames(oldLabs2) <- colnames

oldLabs2 <- oldLabs2 %>%
  group_by(REGION, Season) %>% 
  summarize(A = sum(A1, A2, A3), B = sum(B1, B2, B3))



# Before merging, it's helpful to transform everything 
# into a data frame.

publicLabs <- as.data.frame(publicLabs)
clinical2 <- as.data.frame(clinical2)
oldLabs2 <- as.data.frame(oldLabs2)


# Merging our respiratory data into one file

totalNew <- merge(publicLabs, clinical2, by = c("REGION", "Season"))
totalNew <- totalNew %>%
  group_by(REGION, Season) %>%
  summarize(A = sum(A.x, A.y), B = sum(B.x, B.y))
totalNew <- as.data.frame(totalNew)


total <- merge(totalNew, oldLabs2, by = c("REGION", "Season"), 
               all = TRUE)
total[is.na(total)] <- 0
total <- total %>%
  group_by(REGION, Season) %>%
  summarize(A = sum(A.x, A.y), B = sum(B.x, B.y), All = sum(A, B))
total <- as.data.frame(total)


##### EDA
# Looking at our present data

ggplot(data = total, aes(x = factor(Season), y = A, color = REGION)) +
  geom_line(aes(group = REGION)) + geom_point() +
  xlab("Year") + ylab("Number of Infections") +
  ggtitle("Influenza A Infections") + 
  theme_light() + theme(legend.position = "none")

ggplot(data = total, aes(x = factor(Season), y = B, color = REGION)) +
  geom_line(aes(group = REGION)) + geom_point() +
  xlab("Year") + ylab("Number of Infections") +
  ggtitle("Influenza B Infections") + 
  theme_light() + theme(legend.position = "none")

ggplot(data = total, aes(x = factor(Season), y = All, color = REGION)) +
  geom_line(aes(group = REGION)) + geom_point() +
  xlab("Year") + ylab("Number of Infections") +
  ggtitle("All Influenza Infections") +
  theme_light() + theme(legend.position = "none")

# Five number summaries for each region for our data

fivenumA <- total %>%
  group_by(REGION) %>%
  summarise(n = n(), 
            min = fivenum(A)[1],
            Q1 = fivenum(A)[2],
            median = fivenum(A)[3],
            Q3 = fivenum(A)[4],
            max = fivenum(A)[5])

fivenumA

fivenumB <- total %>%
  group_by(REGION) %>%
  summarise(n = n(), 
            min = fivenum(B)[1],
            Q1 = fivenum(B)[2],
            median = fivenum(B)[3],
            Q3 = fivenum(B)[4],
            max = fivenum(B)[5])

fivenumAll <- total %>%
  group_by(REGION) %>%
  summarise(n = n(), 
            min = fivenum(All)[1],
            Q1 = fivenum(All)[2],
            median = fivenum(All)[3],
            Q3 = fivenum(All)[4],
            max = fivenum(All)[5])

# Looking at the few states whose minimums were not 2020

minNot2020 <- total %>%
  group_by(REGION) %>%
  slice_min(order_by = ) %>%
  filter(Season != 2020) 

minNot2020

lowStatelist <- total %>%
  filter(REGION %in% minNot2020$REGION)

lowStatelist %>%
  group_by(REGION) %>%
  summarise(n = n(), 
            min = fivenum(All)[1],
            Q1 = fivenum(All)[2],
            median = fivenum(All)[3],
            Q3 = fivenum(All)[4],
            max = fivenum(All)[5])


# Removing the places we found to contain no valuable data

total <- total %>% 
  group_by(REGION) %>%
  filter(REGION != "Florida" & 
           REGION != "Virgin Islands" &
           REGION != "District of Columbia")
total <- as.data.frame(total)

# Looking at the rolling averages of the data 
# up until COVID


preCOVID <- total %>%
  filter(Season < 2020)

test <- total %>%
  filter(Season >= 2020)

avgA <- preCOVID %>% 
  group_by(REGION) %>%
  mutate(count = 1) %>%
  mutate(rollavgA = cumsum(A)/cumsum(count)) %>%
  select(-count)

avgB <- avgA %>% 
  group_by(REGION) %>%
  mutate(count = 1) %>%
  mutate(rollavgB = cumsum(B)/cumsum(count)) %>%
  select(-count)

avgAll <- avgA %>% 
  group_by(REGION) %>%
  mutate(count = 1) %>%
  mutate(rollavgAll = cumsum(All)/cumsum(count)) %>%
  select(-count)


ggplot(data = avgA, aes(x = factor(Season), y = rollavgA, color = REGION)) +
  geom_line(aes(group = REGION)) + geom_point() +
  ggtitle("Rolling Averages, Type-A, Pre-COVID") + 
  xlab("Flu Season") + ylab("Rolling Average of Infections") +
  theme_light() + theme(legend.position = "none")

ggplot(data = avgB, aes(x = factor(Season), y = rollavgB, color = REGION)) +
  geom_line(aes(group = REGION)) + geom_point() +
  ggtitle("Rolling Averages, Type-B, Pre-COVID") + 
  xlab("Flu Season") + ylab("Rolling Average of Infections") +
  theme_light() + theme(legend.position = "none")

ggplot(data = avgAll, aes(x = factor(Season), y = rollavgAll, color = REGION)) +
  geom_line(aes(group = REGION)) + geom_point() +
  xlab("Flu Season") + ylab("Rolling Average of Infections") +
  ggtitle("Rolling Averages, A & B, Pre-COVID") + 
  theme_light() + theme(legend.position = "none")


# We can only use states that have enough date, as such we are chosing 
# to include only the states with all years of data

states <- unique(avgAll$REGION)

for (i in states) {
  filteredfile <- preCOVID %>%
    filter(REGION == i)
  print(i)
  print(dim(filteredfile))
}

shortstates <- c("Alaska", 
                 "Disctric;of;Columbia", 
                 "New;Hampshire", 
                 "Puerto;Rico", 
                 "Virgin;Islands", 
                 "Wyoming")

bigstates <- states[! states %in% shortstates]

for (i in bigstates) {
  filteredtest <- test %>%
    filter(REGION == i)
  n_test <- nrow(filteredtest)
  if (n_test != 2) {
    print(i)
  }
}

shortcovidstates <- c("Delaware", 
                      "Nevada", 
                      "New Hampshire",
                      "North Carolina",
                      "North Dakota",
                      "Utah")

bigcovidstates <- bigstates[! bigstates %in% shortcovidstates]



# Create graphs and an accuracy reports of MASE
# for all 40 states which we have a full 12 years of data
# With the ARIMA model

for (i in bigcovidstates) {
  filteredfile <- preCOVID %>%
    filter(REGION == i)
  filteredcol <- filteredfile$All
  filteredcol.ts <- ts(filteredcol, freq = 1, start = c(2010, 1))
  filteredcol.arima <- auto.arima(filteredcol.ts)
  filteredtest <- test %>%
    filter(REGION == i)
  filteredtestcol <- filteredtest$All
  filteredtest.ts <- ts(filteredtestcol, freq = 1, start = c(2020, 1))
  n_test <- length(filteredtest)
  multi.fc <- filteredcol.arima %>%
    forecast(h = n_test)
  val = accuracy(multi.fc, x = filteredtest.ts)
  place = paste(i, "MASE:", sep = " ")
  write(place,file="ARIMAAccuracy.txt",append=TRUE)
  write(val[12],file="ARIMAAccuracy.txt",append=TRUE)
  png(filename = paste("ARIMA",i,"All.png"), width=800, height=600)
  p = autoplot(multi.fc) +
    ggtitle(i, " ARIMA") +
    xlab("Flu Season") + ylab("Infections") +
    theme_light() +
    geom_line(
      aes(
        x = as.numeric(time(filteredtest.ts)),
        y = as.numeric(filteredtest.ts)
      ), 
      col = "red"
    )
  print(p)
  dev.off()
}

# With the naive linear regression model


for (i in bigcovidstates) {
  filteredfile <- preCOVID %>%
    filter(REGION == i)
  filteredcol <- filteredfile$All
  filteredcol.ts <- ts(filteredcol, freq = 1, start = c(2010, 1))
  filteredcol.fc <- naive(filteredcol.ts, h = 4)
  filteredtest <- test %>%
    filter(REGION == i)
  filteredtestcol <- filteredtest$All
  filteredtest.ts <- ts(filteredtestcol, freq = 1, start = c(2020, 1))
  val = accuracy(multi.fc, x = filteredtest.ts)
  place = paste(i, "MASE:", sep = " ")
  write(place,file="NaiveAccuracy.txt",append=TRUE)
  write(val[12],file="NaiveAccuracy.txt",append=TRUE)
  png(filename = paste("Naive",i,"All.png"), width=800, height=600)
  p = autoplot(filteredcol.fc) +
    ggtitle(i, " Naive") +
    xlab("Flu Season") + ylab("Infections") +
    theme_light() +
    geom_line(
      aes(
        x = as.numeric(time(filteredtest.ts)),
        y = as.numeric(filteredtest.ts)
      ), 
      col = "red"
    )
  print(p)
  dev.off()
}


# Adding the mortality data to our working dataframe


mortality$STATE <- state.name[match(mortality$STATE, state.abb)]

deaths <- mortality %>%
  group_by(STATE) %>%
  select(YEAR, STATE, DEATHS)
colnames(deaths) <- c("Season", "REGION", "DEATHS")
deaths <- as.data.frame(deaths)

bigstatesData <- preCOVID[preCOVID$REGION %in% bigcovidstates, ]


totalMortality <- merge(deaths, bigstatesData, 
                        by = c("REGION", "Season"), all = TRUE)

# This didn't introduce any noticeable new NAs, but just in case
totalMortality <- totalMortality %>%
  na.omit()

# Quick proof of concept
CO <- totalMortality %>%
  filter(REGION == "Colorado")

model <- lm(DEATHS ~ A, data = CO)
p <- summary(model)
print(p)
model2 <- lm(DEATHS ~ B, data = CO)
p2 <- summary(model2)
print(p2)

# I originally ran into a number of states which would error
# out if I tried to apply a linear regression model
# We chose to eliminate the erroneous states, as that still
# gives us plenty of states to work with

deathstates <- unique(totalMortality$REGION)

# The "bad" states would result in an error when we tried to apply a 
# linear regression model.

badstates = c("Alabama", "Arizona", "California", "Georgia", "Illinois", "Indiana", 
              "Kentucky","Ohio", "New York", "Missouri","Maryland", "Massachusetts", "Michigan",
              "Pennsylvania", "Tennessee", "Texas", "Virginia", "Washington","Wisconsin")

mortalitystates <- bigcovidstates[! bigcovidstates %in% badstates]


# Generating text output of the linear models for each flu type
# as well as "all" flu types.

sink("LinearModel-A.txt")

for (i in mortalitystates) {
  filteredfile <- totalMortality %>%
    filter(REGION == i)
  model <- lm(DEATHS ~ A, data = filteredfile)
  info = summary(model)
  print(i)
  print(info)
}

sink()

sink("LinearModel-B.txt")

for (i in mortalitystates) {
  filteredfile <- totalMortality %>%
    filter(REGION == i)
  model <- lm(DEATHS ~ B, data = filteredfile)
  info = summary(model)
  print(i)
  print(info)
}

sink()

sink("LinearModel-All.txt")

for (i in mortalitystates) {
  filteredfile <- totalMortality %>%
    filter(REGION == i)
  model <- lm(DEATHS ~ All, data = filteredfile)
  info = summary(model)
  print(i)
  print(info)
}

sink()


