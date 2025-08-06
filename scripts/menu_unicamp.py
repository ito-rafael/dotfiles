#!/usr/bin/env python
import requests
from bs4 import BeautifulSoup
import datetime

link = 'https://sistemas.prefeitura.unicamp.br/apps/cardapio/index.php'
res = requests.get(link)
soup = BeautifulSoup(res.text, 'html.parser')

class Menu(object):
    def __init__(self, main, menu_description):
        # change text to title case
        menu = menu_description.get_text(strip=True, separator="\n").splitlines()
        self.menu = [self.title_case(item) for item in menu[:5]]
        self.main = self.title_case(main)

        # store attributes
        self.base = self.menu[0]
        self.side = self.menu[1]
        self.salad = self.menu[2]
        self.dessert = self.menu[3]
        self.juice = self.menu[4]
        self.obs = menu[5:8]
        self.availability = menu[8:]
