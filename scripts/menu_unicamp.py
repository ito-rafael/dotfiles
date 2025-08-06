#!/usr/bin/env python
import requests
from bs4 import BeautifulSoup
import datetime

link = 'https://sistemas.prefeitura.unicamp.br/apps/cardapio/index.php'
res = requests.get(link)
soup = BeautifulSoup(res.text, 'html.parser')
