#######################################################################################################################
# StorageBox.py
# This will be an index of all the Aminomons currently in the storage box. We will pull up both the storage (on the left)
#   and the current team (on the right).
#    
# THIS FILE IS NOT FULLY FUNCTIONAL YET
######################################################################################################################

import pygame.freetype
from BigBigData import *
from SettingsAndSupport import *


#
# This is the class for the StorageBox, this currently only displays two lists, one on the left for the storage list 
#   and one on the right for current team.
#
class StorageBox:
    def __init__ (self, fonts, team_aminos, monster_frames, storage_aminos):
        self.display_surface = pygame.display.get_surface()
        self.fonts = fonts
        self.current_monsters = team_aminos
        self.storage_aminos = storage_aminos
        self.frame_storage_index = 0
        self.selection_side = "player"

        #
        # Setting up the frames list we will use. We will need three, the first for the Aminomon Icon, 
        #   the second for all the Aminomon Animations, and the third is for the Stats Images.
        #
        self.icon_frames = monster_frames['icons']

        #
        # This is for our tint surface
        #
        self.tint_surf = pygame.Surface((WIN_WIDTH, WIN_HEIGHT))
        self.tint_surf.set_alpha(200)


        #
        # This will set the overall dimensions of the Storage Box
        #
        self.main_rect = pygame.FRect(0,0, WIN_WIDTH * 0.6, WIN_HEIGHT *0.7).move_to(center = (WIN_WIDTH/2, WIN_HEIGHT/2))


        #
        # Lists for the number of Aminomons to display, the width of the list, the height of each Aminomon Entry,
        #   a index for which Aminomon is currently selected, and the Indexed Aminomon if selected
        #
        self.visible_items = 6
        self.list_width = self.main_rect.width * 0.35
        self.item_height = self.main_rect.height / self.visible_items
        self.selected_storage_index = None
        self.storage_index = 0
        self.player_amino_index = 0
        self.player_amino_selected_index = 0
        # self.storage_index = {
        #     "player": 0,
        #     "storage": 0
        # }


    #
    # This is how we will navigate the Aminomon Index. We can move through the list and
    #   select entries to move.
    #
    def input(self):
        keys = pygame.key.get_just_pressed()
        if keys[pygame.K_UP]:
            if self.storage_index == 0:
                self.storage_index = len(self.storage_aminos)
            else:
                self.storage_index -= 1
        if keys[pygame.K_DOWN]:
            if self.storage_index == len(self.storage_aminos):
                self.storage_index = 0
            else:
                self.storage_index += 1
        if keys[pygame.K_RETURN]:
            if self.selected_storage_index != None:
                selected_monster = self.storage_aminos[self.selected_storage_index]
                current_monster = self.storage_aminos[self.storage_index]
                self.storage_aminos[self.storage_index] = selected_monster
                self.storage_aminos[self.selected_storage_index] = current_monster
                self.selected_storage_index = None
            else:
                self.selected_storage_index = self.storage_index
        #if keys[pygame.K_ESCAPE]:
        #    pass

        if keys[pygame.K_RIGHT]:
            self.selection_side = 'player'

        if keys[pygame.K_LEFT]:
            self.selection_side = 'storage'

        self.storage_index = self.storage_index % len(self.storage_aminos)

    #
    # This method sets up the Storage Box information and displays the current stored Aminos. This list
    #   will contain the Aminomons stored. 
    #
    def display_storage_box(self):
        bg_rect = pygame.FRect(self.main_rect.topleft, (self.list_width, self.main_rect.height))
        pygame.draw.rect(self.display_surface, COLORS['gray'], bg_rect, 0, 0, 12, 0, 12, 0)

        v_offset = 0 if self.storage_index < self.visible_items else -(self.storage_index - self.visible_items +1) * self.item_height
        

        for ind, monster in self.storage_aminos.items():
            
            #
            # This will set up the colors that we will use within the Storage Box. We will make a rect for 
            #  each entry. We will then make surfaces and partner rects for the display text and Aminomon Icon  
            #
            bg_color = COLORS['gray'] if self.storage_index != ind else COLORS['light']
            text_color = COLORS['white'] if self.selected_storage_index != ind else COLORS['gold']


            top = self.main_rect.top + ind * self.item_height + v_offset
            item_rect = pygame.FRect(self.main_rect.left, top, self.list_width, self.item_height)

            text_surf = self.fonts['regular'].render(monster.name, False, text_color)
            text_rect = text_surf.get_frect(midleft = item_rect.midleft + vector(90,0))


            icon_surf = self.icon_frames[monster.name]
            icon_rect = icon_surf.get_frect(center = item_rect.midleft + vector(45,0))

            #
            # This section will check for corner collisions of the entries.
            #
            if item_rect.colliderect(self.main_rect):
                if item_rect.collidepoint(self.main_rect.topleft):
                    pygame.draw.rect(self.display_surface, bg_color, item_rect, 0, 0, 12)
                elif item_rect.collidepoint(self.main_rect.bottomleft + vector(1,-1)): 
                    pygame.draw.rect(self.display_surface, bg_color, item_rect, 0,0,0,0,12,0)
                else:
                    pygame.draw.rect(self.display_surface, bg_color, item_rect)

                self.display_surface.blit(text_surf, text_rect)
                self.display_surface.blit(icon_surf, icon_rect)

        #
        # We will then use this to draw lines around each of the entries. 
        #
        for i in range(1, min(self.visible_items, len(self.storage_aminos))):
            y = self.main_rect.top + self.item_height * i
            left = self.main_rect.left
            right = self.main_rect.left + self.list_width
            pygame.draw.line(self.display_surface, COLORS['light-gray'], (left, y), (right, y))


   

    #
    # This method will fill the right side of the screen with the Aminomons currently in the team
    #
    def display_player_aminomons(self):
        bg_rect = pygame.FRect(self.main_rect.topright-vector(self.list_width,0), (self.list_width, self.main_rect.height))
        pygame.draw.rect(self.display_surface, COLORS['gray'], bg_rect, 0, 0, 12, 0, 12, 0)

        v_offset = 0 if self.storage_index < self.visible_items else -(self.storage_index - self.visible_items +1) * self.item_height

        for sel, monster in self.current_monsters.items():
            
            #
            # This will set up the colors that we will use within the Storage Box. We will make a rect for 
            #  each entry. We will then make surfaces and partner rects for the display text and Aminomon Icon  
            #
            bg_color = COLORS['gray'] if self.player_amino_selected_index != sel else COLORS['light']
            text_color = COLORS['white'] if self.player_amino_selected_index != sel else COLORS['gold']

            top = self.main_rect.top + sel * self.item_height + v_offset
            item_rect = pygame.FRect(self.main_rect.right-self.list_width, top, self.list_width, self.item_height)

            text_surf = self.fonts['regular'].render(monster.name, False, text_color)
            text_rect = text_surf.get_frect(midleft = item_rect.midleft + vector(90,0))

            icon_surf = self.icon_frames[monster.name]
            icon_rect = icon_surf.get_frect(center = item_rect.midleft + vector(45,0))

            #
            # This section will check for corner collisions of the entries.
            #
            if item_rect.colliderect(self.main_rect):
                if item_rect.collidepoint(self.main_rect.topleft):
                    pygame.draw.rect(self.display_surface, bg_color, item_rect, 0, 0, 12)
                elif item_rect.collidepoint(self.main_rect.bottomleft + vector(1,-1)): 
                    pygame.draw.rect(self.display_surface, bg_color, item_rect, 0,0,0,0,12,0)
                else:
                    pygame.draw.rect(self.display_surface, bg_color, item_rect)

                self.display_surface.blit(text_surf, text_rect)
                self.display_surface.blit(icon_surf, icon_rect)

        #
        # We will then use this to draw lines around each of the entries. 
        #
        for i in range(1, min(self.visible_items, len(self.storage_aminos))):
            y = self.main_rect.top + self.item_height * i
            left = self.main_rect.left
            right = self.main_rect.left + self.list_width
            pygame.draw.line(self.display_surface, COLORS['light-gray'], (left, y), (right, y))





    #
    # This is the Storage Box update function. It checks for input and then calls our display functions.
    #
    def update(self):
        self.input()
        self.display_surface.blit(self.tint_surf, (0,0))
        self.display_storage_box()
        self.display_player_aminomons()
                

