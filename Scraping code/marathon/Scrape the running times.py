########################################
#######################################
# Script: Scraping race times of http://www.olympicgamesmarathon.com/results.php
########################################
#######################################
import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
url = "http://www.olympicgamesmarathon.com/results.php"
site = requests.get(url)
soup = BeautifulSoup(site.content, "html.parser")

# link.attrs can be used to obtain a dictionary with the key and value of all the attributes a tag has
# obtain all olympiad.php's
# find method returns -1 in case the substring is not found
links = []
for link in soup.find_all("a"):
    if link.attrs["href"].find("olympiad") >= 0:
        links.append(link.attrs["href"])

# Same link occurs multiple times, make the list unique
links = set(links)

# add 'http://www.olympicgamesmarathon.com/' in front of each element of the list
full_links = []
prefix = 'http://www.olympicgamesmarathon.com/'
for link in links:
    full_links.append(prefix + link)

link = full_links[0]
page = requests.get(link)
soup = BeautifulSoup(page.content, "html.parser")

for link in full_links:
    page = requests.get(link)
    soup = BeautifulSoup(page.content, "html.parser")

# Assign dfName to variable
dfName = 'Runtimes_' + re.search("\d+", link).group() + '.csv'

# find the indices where the table containing the racers starts and ends
start = 0
end = 0
for index, value in enumerate(soup.find_all("td")):
    if value.text == "1°":
        start = index
    if value.text == "Did not finish":
        end = index - 1
        break

# Creating an empty Dataframe with column names only
dfObj = pd.DataFrame(columns=['Position', 'FirstName', "LastName", "Nationality", "Time"])

# each inner list is one specific racer with it results
racers = []
l = 0
for i in range(5, end + 4, 5):
    racers.append(soup.find_all("td")[start:end][l:i])
    l += 5

# converting attributes to text
for racer in racers:
    if len(racer) == 0:
        break
    else:
        for i in range(5):
            if i == 0:
                racer[i] = racer[i].text[:-1]
            else:
                racer[i] = racer[i].text

# filling in the dataframe
for racer in racers:
    if len(racer) == 0:
        break
    else:
        dfObj = dfObj.append(
            {'Position': racer[0], 'FirstName': racer[1], 'LastName': racer[2], 'Nationality': racer[3],
             'Time': racer[4]}, ignore_index=True)

# write the pandas dataframe to csv file with correct name
dfObj.to_csv(
    r'C:\Users\BrechtDewilde\Documents\UGENT -  statistical data analysis\STATISTICAL DATA ANALYSIS\thesis\R analysis\Data\scraped