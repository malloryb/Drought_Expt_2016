#Author: Mallory Barnes
#Date: 12/29/2016
#The purpose of this code is to add addtional licor files to the big dataset I'm using for analysis: 
#currently located in: all_data <- read.csv("C:/Users/Mallory/Dropbox/Drought_Expt_2016/all_data.csv") in the 
#09_merged_and_analysis file in this Rstudio project 
#Two steps: 
#1) Get the first observation of "photo", "cond", and "Trrmmol" files into a dataframe for analysis
#2) Merge these files with the 'all_data' file
#Input: Non-QA-QCed Licor files containing all licor observations, 'all_data' file (step 2)
#Output: Big data file containing the additional licor variables

library(corrr)
library(dplyr)

#load Licor files and get first observation for each----------------------------

Licor_files <- read.csv("C:/Users/Mallory/Dropbox/QC_9_1_2016_bad_and_good.csv")

#Quandry! First observation is what we want, however, several have a QC of '-1' so debating whether
#to use the 2nd observation if the first observation is of poor quality, or just use the 1st observation 
#no matter what - seems like the latter is a better plan because the 2nd point won't even be indicative 
#Keep the QC flag in case it ends up being relevant

str(Licor_files)
#Subset relevant variables: 
Licor_subset <- subset(Licor_files, select=c('fname', 'Obs', 'HHMMSS', 'Ci', 'Trmmol', 'Cond', 'Photo', 'QC'))

#Need to get 'Plant_ID' and 'Date' properly formatted 
#Some of the filnames have dashes instead of underscores - to fix: 
Licor_subset$fname <- gsub('-','_', Licor_subset$fname)
#Get plant_ID
Licor_subset$Plant_ID <- substr(Licor_subset$fname, 8,10)
#Get date
Licor_subset$date <- as.Date(substr(Licor_subset$fname, 19,28), "%m_%d_%Y")
#Create uniqueID column
Licor_subset$uniqueID <- with(Licor_subset, paste(Licor_subset$Plant_ID, Licor_subset$date, sep="-" ))
#Get only first observation of each A/Ci curve (should be 13-ish obs total)
Licor_firstobs <- subset(Licor_subset, Obs==1)
str(Licor_firstobs)
Licor_firstobs
#Lots of QC=-1s...hard to know how much to trust these observations

#merge with analysis file -------------------------------------------
all_data <- read.csv("C:/Users/Mallory/Dropbox/Drought_Expt_2016/all_data.csv")
str(all_data)
data_plus_photo <- merge(all_data, Licor_firstobs, by="uniqueID")
str(data_plus_photo)
#we lost 14 observations...why? where'd they go?

#clean_up
data_plus_photo  <- subset(data_plus_photo, select=-c(Plant_ID.x,Plant_ID.y, HHMMSS, X, Date.x, fname.y))
str(data_plus_photo)
cor(data_plus_photo$Vcmax, data_plus_photo$Jmax)
write.csv(data_plus_photo, "C:/Users/Mallory/Dropbox/Drought_Expt_2016/All_with_more_licor_vars.csv")

#Exploring corrr package in R
#Base function: 'correlate'

#Need to get rid of non-numeric variables: Genotype, obs, QC, date, Date.y, fname.x, uniqueID
str(data_plus_photo)
all_for_corr <- subset(data_plus_photo, select=-c(Genotype, Obs, QC, date, Date.y, fname.x, uniqueID, Plant_ID))
str(all_for_corr)
#Now use correlate function to get correlation matrix - corrr package then uses pipes for filtering
#And various operations
c <- correlate(all_for_corr)

#Filter by correlation higher than 0.7
c %>% filter(Vcmax> .7)  %>% 
        select(rowname, Jmax, Cond, Photo) %>% print(n=40)

c %>% focus(Vcmax, Jmax)%>% print(n=40)

c %>% focus(Cond, Photo)%>% print(n=40)

#Checking on Vcmax/Jmax Correlations --------------------------------
cor(data_plus_photo$Vcmax, data_plus_photo$Jmax)
qplot(data_plus_photo$Vcmax, data_plus_photo$Jmax) + geom_smooth(method="lm")
