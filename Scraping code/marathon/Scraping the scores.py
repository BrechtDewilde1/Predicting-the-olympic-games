from bs4 import BeautifulSoup
import pandas as pd
import requests

import re


# Function to replace multiple occurrences
# of a character by a single character
def replace(string, char):
    pattern = char + '{2,}'
    string = re.sub(pattern, char, string)
    return string

# List containing the different urls
url = "https://www.worldathletics.org/world-rankings/marathon/men?page="
url_list = []
for i in range(1,20):
    url_list.append(url+str(i))

# Create the empty dataFrame
dfObj = pd.DataFrame(columns=["Name", "Score"])

for url in url_list:
    # make GET request to url and obtain the HTML structure
    site = requests.get(url)

    # make the beautifulSoup tree of the HTML page
    soup = BeautifulSoup(site.content, "html.parser")

    # find the part of the HTML structure containing the particular data
    table_list = soup.find("table", class_="records-table")

    # subset only the necessary parts
    athlete_string = table_list.contents[3].text

    # obtain a list we can work with
    temp_list = replace(athlete_string, "\n")[1:-1].rstrip().split("\n")

    # strip each element of the list
    for index, value in enumerate(temp_list):
        temp_list[index] = value.strip()


    cleaned_list = list(filter(None, temp_list))
    for index, value in enumerate(cleaned_list):
        if value == "Marathon [Half Marathon]":
            cleaned_list[index] = "Marathon"

    # obtain a list containing the indices such that we can subset each athlete
    indices = []
    for index, value in enumerate(cleaned_list):
        if value == "Marathon":
            indices.append(index)

    # outer list contains innerlist whereby each list contains the athlete
    outer = []
    start = 0
    for index in indices:
        outer.append(cleaned_list[start:index + 1])
        start = index + 1

    # incase athlete doesn't contain a dayOfBirth add this such that we can easily subset the informative data
    for athlete in outer:
        if len(athlete) < 6:
            athlete.insert(2, "")

    # add all the data to the dataframe
    for athlete in outer:
        dfObj = dfObj.append(
            {'Name': athlete[1], 'Score': athlete[4]}, ignore_index=True)