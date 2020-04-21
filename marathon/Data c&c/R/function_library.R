# funciton to clean all the datasets extracted from wikipedia
woman_data_cleaning <- function(df){
  noc_country <- read.csv(file.path("Data", "noc_regions.csv"), stringsAsFactors = FALSE)[,c(1,2)]
  if(any(grepl("Note", colnames(df)))){
    df <- df[ ,-ncol(df)]
  }
  
  if(ncol(df) == 3){
    positions <- gregexpr("\\(([^}]+)\\)", df$Athlete)
    noc <- vector("character", length = nrow(df))
    names <- vector("character", length = nrow(df))
    
    for(i in 1:nrow(df)){
      start <- positions[[i]][1] + 1
      noc[i] <- substr(df$Athlete[i], start, start + 2)
      names[i] <- substr(df$Athlete[i], 0, start - 2)
    }
    
    country <- vector("character", length = nrow(df))
    for(i in 1:length(noc)){
      country[i] <- noc_country$region[match(noc[i], noc_country$NOC)]
    }
    
    df$Athlete <- names
    df$Nationality <- country
    
    colnames(df) <- c("Position", "Name", "Time", "Nationality")
    df <- df[, c("Position", "Name", "Nationality", "Time")]
    
  } else {
    colnames(df) <- c("Position", "Name", "Nationality", "Time")
  }
  
  df[1, 1] <- 1
  df[2, 1] <- 2
  df[3, 1] <- 3
  
  df$Position <- as.numeric(gsub("\\.", "", df$Position))
  return(df)
}

# Function to check whether there are two names matches in two different strings
match_names <- function(name1, year1 = 0, name2, year2){
  vec_name1 <- unlist(strsplit(name1, split = " "))
  vec_name2 <- unlist(strsplit(name2, split = " "))
  return(length(intersect(vec_name1, vec_name2)) >= 2 && year1 == year2)
}

# functions to express the race time in minutes and seconds
convert_to_mins <- function(time){
  return(as.numeric(format(time, "%H")) * 60 + as.numeric(format(time, "%M")) + as.numeric(format(time, "%OS"))/60)
}

convert_to_secs <- function(time){
  return(as.numeric(format(time, "%H")) * 3600 + as.numeric(format(time, "%M")) * 60 + as.numeric(format(time, "%OS")))
}

# determines the host country given the host city
host_country_determiner <- function(city){
  host.city <- unique(marathon$`Host city`)
  host.country <- c("South Korea", "Brazil", "UK", "Russia", "Spain", "Greece", "China", "Australia", "USA", "Germany", "Japan", "USA", "Italy", "Canada", "Mexico")
  return(host.country[match(city, host.city)])
}

# Labels cleaning
labels_cleaning <- function(df){
  colnames(df) <- c("Date", "Label", "Distance", "Competition", "Venue", "Country", "Men.s.winner", "Women.s.winner")
  return(df)
}

# computes time score (time in seconds)
time_score <- function(time){
  a = 0.0000191003	
  b = -15599.4039272134	
  c = 0.0084789663
  return(floor(a* (time + b)^2 + c))
}

# determine position score
place_score <- function(position, label){
  gold <- c(270, 220, 195, 175, 155, 145, 135, 125, 80, 70, 60, 50, 45, 40, 37, 34, 31, 29, 27, 25)
  silver <- c(170, 130, 115, 100, 85, 75, 65, 55, 45, 35, 25, 20)
  bronze <- c(140, 105, 90, 75, 60, 50, 40, 30, 25, 22, 19, 17)
  if (label == "Gold"){
    if (position > length(gold)){
      return(0)
    }
    else{
      return(gold[position])
    }
    
  }else if (label == "Silver"){
    if (position > length(silver)){
      return(0)
    }
    else{
      return(silver[position])
    }
    
  } else if (label == "Bronze"){
    if (position > length(bronze)){
      return(0)
    }
    else{
      return(bronze[position])
    }
  }
}


# Feature creation 
feature_creation <- function(df, name, year){
  # STEP 1 - filter only the observations happend before the 01-aug-year
  eventDate <- as.Date(paste0("01/08/", year), format =  "%d/%m/%Y")
  obs <- as.data.frame(df %>% filter(athlete == name) %>% filter(date < eventDate))
  
  # STEP 2 - if number of occurrences is 0 for the given year, return NA for every feature, else compute all the features
  if(nrow(obs) == 0 ){
    return(rep(list(NA),15))
  }else{
    marathons <- nrow(obs)
    Gmarathons <- nrow(obs %>% filter(label == "Gold"))
    Smarathons <- nrow(obs %>% filter(label == "Silver"))
    Bmarathons <- nrow(obs %>% filter(label == "Bronze"))
    avgTime <- mean(obs$TimeMins)
    avgTimeScore <- mean(obs$TimeScore)
    bestTime <- min(obs$TimeMins)
    dateBestTime <- obs$date[match(min(obs$TimeMins), obs$TimeMins)]
    bestTimeScore <- max(obs$TimeScore)
    avgPosition <- mean(obs$position)
    avgPositionScore <- mean(obs$position_score)
    bestPosition <- min(obs$position)
    bestPositionScore <- max(obs$position_score)
    avgPerformanceScore <- mean(obs$performance_score)
    bestPerformanceScore <- max(obs$performance_score)
    return(list(marathons, Gmarathons, Smarathons, Bmarathons, avgTime, avgTimeScore, bestTime, dateBestTime, bestTimeScore, avgPosition, avgPositionScore, bestPosition, bestPositionScore, avgPerformanceScore, bestPerformanceScore))
  }
}

# Feature to calculate number of months between raceDate and BestDate
monnb <- function(d){ 
  lt <- as.POSIXlt(as.Date(d, origin="1900-01-01"))
  return(lt$year*12 + lt$mon)
}

monthCalculator <- function(year, date2){
  date1 <- as.Date(paste0("01/08/", year), format =  "%d/%m/%Y")
    return(monnb(date1) - monnb(date2))
}

# Function to aggregate the sub regions
regionAggregator <- function(region){
  if(grepl("europe", region, ignore.case = T))
    return("Europe")
  else if (grepl("australia", region, ignore.case = T)){
    return("Oceania")
  } else if (grepl("melanesia", region, ignore.case = T)){
    return("Oceania")
  } else if (grepl("micronesia", region, ignore.case = T)){
    return("Oceania")
  } else if (grepl("polynesia", region, ignore.case = T)){
    return("Oceania")
  }  else if (grepl("europe", region, ignore.case = T)){
    return("Europe")
  }  else if (grepl("africa", region, ignore.case = T)){
    return("Africa")
  }  else if (grepl("asia", region, ignore.case = T)){
    return("Asia")
  } else{
    return(region)
  }
}


