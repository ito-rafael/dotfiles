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
        # sanity checks
        if (self.obs[0] != 'Observações:'):
            raise
        if (self.availability[0] != 'O cardápio vegano será servido no RU, RA, RS e HC.'):
            raise


    def __str__(self):
        return f'{self.main}\n{self.side}\n{self.base}\n{self.salad}\n{self.dessert}'

    def title_case(self, text: str):
        # define replacements
        replacements = {
            ' E ': ' e ',
            ' Ao ': ' ao ',
            ' De ': ' de ',
            ' Em ': ' em ',
            ' Na ': ' na ',
            ' Com ': ' com ',
        }

        # convert to title case
        text = text.title()

        # apply replacements
        for k, v in replacements.items():
            text = text.replace(k, v)
        return text

#=================================================
# Lunch
#=================================================

# find the h2 tag with text "Almoço Vegano"
lunch_menu = soup.find('h2', class_='menu-section-title', string='Almoço Vegano')

if lunch_menu:
    # get its parent (div.menu-section) and extract the related content
    lunch_menu_section = lunch_menu.find_parent('div', class_='menu-section')
    lunch_menu_main = lunch_menu_section.find('div', class_='menu-item-name').get_text()
    lunch_menu_item = lunch_menu_section.find('div', class_='menu-item-description')
    lunch = Menu(lunch_menu_main, lunch_menu_item)

#=================================================
# Dinner
#=================================================

# find the h2 tag with text "Jantar Vegano"
dinner_menu = soup.find('h2', class_='menu-section-title', string='Jantar Vegano')

if dinner_menu:
    # get its parent (div.menu-section) and extract the related content
    dinner_menu_section = dinner_menu.find_parent('div', class_='menu-section')
    dinner_menu_main = dinner_menu_section.find('div', class_='menu-item-name').get_text()
    dinner_menu_item = dinner_menu_section.find('div', class_='menu-item-description')
    dinner = Menu(dinner_menu_main, dinner_menu_item)
   
#=================================================

# print information
print(lunch_menu.text)
print(lunch)
print()
print(dinner_menu.text)
print(dinner)
