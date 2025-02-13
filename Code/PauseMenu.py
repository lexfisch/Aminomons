#######################################################################################################################
# PauseMenu.py
# This file contains information for the PauseMenu. We will be presented with options for Peptide Dex, Team, Save, and
#   quit.
#
######################################################################################################################

from SettingsAndSupport import *
from PeptideDex import *
from AminoIndex import *
from PartyScreen import *


#
# This is the Pause Menu class. It has methods for selection options (peptide dex, team, save, or quit), it has a display
#   function, an input, and an update method.
#
class PauseScreen():
    #def __init__(self, fonts, current_monsters, aminoindex_open, peptidedex_open, aminomon_frames):
    def __init__(self, fonts, current_monsters, aminomon_frames, player_storage):
        self.display_surface = pygame.display.get_surface()
        self.fonts = fonts
        self.pause_index = 0
        self.pause_menu_blocked = False
        self.player_monsters = current_monsters
        self.aminoindex_open = False
        self.peptide_dex_open = False
        self.team_open = False
        self.aminomon_frames = aminomon_frames
        self.storage_box = player_storage

        # Creates an instance of the Party Screen and the Peptide Dex
        self.party_screen = PartyScreen(self.fonts, self.player_monsters, self.aminomon_frames )
        self.peptide_dex = PeptideDex(self.fonts)

        # Creates the main rect that this will display within, sets the height and width of the list
        self.main_rect = pygame.FRect(0,0, WIN_WIDTH * 0.15, WIN_HEIGHT *0.4).move_to(center = (WIN_WIDTH/2, WIN_HEIGHT/2))
        self.list_width = self.main_rect.width * 0.95
        self.item_height = self.main_rect.height / 5
        self.selected_index = None

        # These are the options for our selections on this menu
        self.options = ['peptideDex', 'Team', 'Save', 'Quit']

    #
    # This handles the logic to determine what to do after a selection is made
    #
    def selection_option(self):
        if self.options[self.pause_index] == 'peptideDex':
            self.peptide_dex_open = not self.peptide_dex_open
            self.pause_menu_blocked = not self.pause_menu_blocked
        elif self.options[self.pause_index] == 'Team':
            self.team_open = not self.team_open
            self.pause_menu_blocked = not self.pause_menu_blocked
        elif self.options[self.pause_index] == 'Save':
            save_trainer_data(self.player_monsters, self.storage_box)
        elif self.options[self.pause_index] == 'Quit':
            pygame.quit()
            exit()

    #
    # This will display the menu and options
    #
    def display_menu(self, dt):
        pygame.draw.rect(self.display_surface,COLORS['light'], self.main_rect, border_radius=10)

        # Iterate through our menu options and render them
        for index, option in enumerate(self.options):
            color = COLORS["red"] if self.pause_index == index else COLORS['black']
            surf = self.fonts['regular'].render(option, False, color)
            
            # Position each option with the adde left padding
            item_rect = surf.get_frect(midleft=(self.main_rect.left + 20, self.main_rect.top + (index + 1) * self.item_height))

            self.display_surface.blit(surf, item_rect)

    #
    # This handles the user input
    #
    def input(self):
        keys = pygame.key.get_just_pressed()
        if keys[pygame.K_UP]:
            if self.pause_menu_blocked: pass
            else: self.pause_index = (self.pause_index - 1) % (len(self.options))
        if keys[pygame.K_DOWN]:
            if self.pause_menu_blocked: pass
            else: self.pause_index = (self.pause_index + 1) % (len(self.options))
        if keys[pygame.K_SPACE]:
            if self.aminoindex_open:
                self.aminoindex_open = False
                self.pause_menu_blocked = False
            elif self.peptide_dex_open:
                self.peptide_dex_open = False
                self.pause_menu_blocked = False
            else:
                self.selection_option()

    #
    # Update function to keep taking input
    #
    def update(self, dt):
        self.input()
        if self.team_open:
            self.party_screen.update(dt)
        elif self.peptide_dex_open:
            self.peptide_dex.update(dt)
        else:
            self.display_menu(dt)