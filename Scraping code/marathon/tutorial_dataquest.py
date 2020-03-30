import requests

# We perform a HTTP get method. We retrieve a response object.
# A response object can be used for inspecting the results retrieved by the request.
# A response object has a status code, this code indicates whether the page was successfully downloaded.
# A status code of 200 indicates that the page was downloaded successfully
page = requests.get("http://dataquestio.github.io/web-scraping-pages/simple.html")
page.status_code

# Printing out the HTML content of the page
page.content


# Now as we have the HTML content, the next step is to 'parse' this content by the use of BeautifulSoup
# First thing is to create a beautifulsoup object of the HTML page, this is done with the BeautifulSoup constructed
# This constructer asks two elements: 1) html file 2) parser
# There are different parsers we can chose from:  "html.parser", "lxml", "lxml-xml"
from bs4 import BeautifulSoup
soup = BeautifulSoup(page.content, "html.parser")

