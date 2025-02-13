#######################################################################################################################
# PartyScreen.py
# This is the file that contains the PartyScreen Class. This class will open up a menu of the current team of Aminomons.
#   It will stagger them slightly and allow the player to move their order for battle purposes or check them out with 
#   access to the Aminomon Index.
#
######################################################################################################################

import pygame.freetype
from BigBigData import *
from SettingsAndSupport import *
from AminoIndex import *

#
# This is the class for the party screen that opens from the pause menu. It will create two columns to display the 
#   Aminomons and then stagger them across the two columns. The user can move the order that these are displayed or
#   can open the Aminomon Index from here. 
#
class PartyScreen:
    def __init__(self, fonts, monsters, all_monster_frames):
        self.display_surface = pygame.display.get_surface()
        self.fonts = fonts
        self.monsters = monsters
        self.frame_index = 0
        self.party_screen_blocked = False
        self.aminoindex_open = False
        self.all_monster_frames = all_monster_frames
        self.monster_index = AminoIndex(self.monsters, self.fonts, self.all_monster_frames)

        # Main rect and width, height information
        self.main_rect = pygame.FRect(0, 0, WIN_WIDTH * 0.5, WIN_HEIGHT * 0.7).move_to(center=(WIN_WIDTH / 2, WIN_HEIGHT / 2))
        self.visible_items = 6
        self.list_width = self.main_rect.width/2
        self.item_height = self.main_rect.height / self.visible_items

        # Loads in the icons for the display
        self.icon_frames = all_monster_frames["icons"]

        # Submenu options for the user
        self.options = ["Open", "Move", "Cancel"]
        self.colors = {
            "selected": COLORS["red"],
            "unselected": COLORS["black"],
            "background": COLORS["light"],
        }

        self.indexes = {"team": 0, "options": 0}
        self.selection_mode = "team"
        self.selected_index = None

    #
    # This handles player input and moves the index
    #
    def input(self, dt):
        keys = pygame.key.get_just_pressed()

        #if self.party_screen_blocked:
        if keys[pygame.K_RETURN]:
                self.party_screen_blocked = False
                self.aminoindex_open = False


        #else:
        if self.selection_mode == "team":
            if keys[pygame.K_UP]:
                self.indexes["team"] = (self.indexes["team"] - 1) % len(self.monsters)
            if keys[pygame.K_DOWN]:
                self.indexes["team"] = (self.indexes["team"] + 1) % len(self.monsters)
            if keys[pygame.K_RETURN]:
                self.selection_mode = "options"
        

        elif self.selection_mode == "options":
            if keys[pygame.K_UP]:
                self.indexes["options"] = (self.indexes["options"] - 1) % len(self.options)
            if keys[pygame.K_DOWN]:
                self.indexes["options"] = (self.indexes["options"] + 1) % len(self.options)
            if keys[pygame.K_RETURN]:
                self.selection_option()
                #self.indexes = {k: 0 for k in self.indexes}
            if keys[pygame.K_ESCAPE]:
                self.selection_mode = "team"

    #
    # This handles the logic for the selection options
    #
    def selection_option(self):
        current_option = self.options[self.indexes["options"]]
        if current_option == "Open":
            self.aminoindex_open = not self.aminoindex_open
            self.party_screen_blocked = not self.party_screen_blocked

        elif current_option == "Move":
            if self.selected_index is not None:
                self.monsters[self.indexes["team"]], self.monsters[self.selected_index] = (
                    self.monsters[self.selected_index],
                    self.monsters[self.indexes["team"]],
                )
                self.selected_index = None
            else:
                self.selected_index = self.indexes["team"]
                self.selection_mode = "team"

        elif current_option == "Cancel":
            self.selection_mode = "team"
            self.selected_index = None

    #
    # This displays the team, it staggers them into two columns and colors the selected index when moving an Aminomon
    #
    def display_team(self):
        bg_rect = pygame.FRect(self.main_rect.topleft, (self.main_rect.width+20, self.main_rect.height*.69))
        pygame.draw.rect(self.display_surface, COLORS['salmon'], bg_rect, 0, 0, 12, 0, 12, 0)        

        for index, monster in self.monsters.items():
            bg_color = COLORS['gray'] if self.indexes['team'] != index else COLORS['light']
            text_color = COLORS['white'] if self.selected_index != index else COLORS['gold']

            if index == 0:
                top = self.main_rect.top + 10 + index * self.item_height
                item_rect = pygame.FRect(self.main_rect.left, top, self.list_width, self.item_height)
            elif not index % 2: 
                top = self.main_rect.top + 10 + ((index * 0.5)  * self.item_height) + 10*(index * 0.5)
                item_rect = pygame.FRect(self.main_rect.left, top, self.list_width, self.item_height)
            else: 
                top = self.main_rect.top + 10 + ((index * 0.5)  * self.item_height) + 10*(index * 0.5)
                item_rect = pygame.FRect(self.main_rect.left+self.list_width+20, top, self.list_width, self.item_height)

            text_surf = self.fonts['regular'].render(monster.name, False, text_color)
            text_rect = text_surf.get_frect(midleft = item_rect.midleft + vector(90,-20))

            icon_surf = self.icon_frames[monster.name]
            icon_rect = icon_surf.get_frect(midleft = item_rect.midleft + vector(15,-10))

            level_surf = self.fonts['small'].render(f'Lvl: {monster.level}', False, text_color)
            level_rect = level_surf.get_frect(bottomleft = icon_rect.bottomleft + vector(0, 25))

            pygame.draw.rect(self.display_surface, bg_color, item_rect, 0, 0, 12, 0, 12, 0)

            self.display_surface.blit(text_surf, text_rect)
            self.display_surface.blit(icon_surf, icon_rect)
            self.display_surface.blit(level_surf, level_rect)
                #self.display_surface.blit(hp_text, hp_rect)
                #self.display_surface.blit(ep_text, ep_rect)

            bar_data = {
            'width': item_rect.width * 0.5,
            'height': 10,
            }
   
            healthbar_rect = pygame.FRect((0,0), (bar_data['width'],bar_data['height'])).move_to(topleft = text_rect.bottomleft + vector(0,0))
            draw_bars(self.display_surface, healthbar_rect, monster.health, monster.get_single_stat('MAX_HEALTH'), COLORS['green'], COLORS['black'], 2)
            
            energybar_rect = pygame.FRect((0,0), (bar_data['width'],bar_data['height'])).move_to(topleft = healthbar_rect.bottomleft + vector(0,10))
            draw_bars(self.display_surface, energybar_rect, monster.energy, monster.get_single_stat('MAX_ENERGY'), COLORS['yellow'], COLORS['black'], 2)

    #
    # This displays the options when selecting an Amino.
    #
    def display_options(self):
        for index, option in enumerate(self.options):
            color = self.colors["selected"] if self.indexes["options"] == index else self.colors["unselected"]
            text_surf = self.fonts["regular"].render(option, False, color)
            top = self.main_rect.top + 10 + index * self.item_height
            item_rect = pygame.FRect(self.main_rect.left + self.list_width + 20, top, self.list_width, self.item_height)
            pygame.draw.rect(self.display_surface, COLORS["light"], item_rect)
            self.display_surface.blit(text_surf, item_rect.topleft)

    #
    # Update function 
    #
    def update(self,dt):
        self.input(dt)
        if self.aminoindex_open:
            self.monster_index.update(dt)

        if not self.aminoindex_open:
            self.display_team()
            if self.selection_mode == "options":
                self.display_options()


