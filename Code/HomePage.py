#######################################################################################################################
# HomePage.py
# This file contains the information for the display when the player launches the game. It gives the option to either 
#    start a new game file or load in the previous file. We don't have save state selections, the player can only have
#    one game file at a time. If they select new game, it will not overwrite the save file until the player saves the game.
#
######################################################################################################################

from SettingsAndSupport import *
from BigBigData import peptideDex

#
# This is the class for our StartScreen. This is what will be dispalyed when the player launches the game
#
class StartScreen:
    def __init__(self, fonts):
        self.display_surface = pygame.display.get_surface()
        self.fonts = fonts
        self.back_color = COLORS['blue']
        self.main_rect = pygame.FRect(0,0, WIN_WIDTH * 0.6, WIN_HEIGHT *0.8).move_to(center = (WIN_WIDTH/2, WIN_HEIGHT/2))
        self.main_image_rect = pygame.FRect(0,0,WIN_WIDTH, WIN_HEIGHT)
        self.index = 0
        self.game_active = False
        self.new_game = True
        self.bg_frames = importFolderDict('images', 'backgrounds')
        self.scrollFrames = importMonster(4,2, 'images', 'monsAminos')
        self.sorted_peptide_dex = sorted(peptideDex.items(), key=lambda item: item[1]['id']) 
        self.visible_items = 10
        self.list_width = self.main_rect.width * 0.3
        self.item_height = self.main_rect.height / self.visible_items
        self.index = 0

    #
    # This function sets what we will display on our Home Page. It will indicate which index is selected
    #   by increasing the font size.
    #
    def display_message(self):
        #bg_rect = pygame.FRect(self.main_rect.topleft, (WIN_WIDTH/4, WIN_HEIGHT/3))

        background_surf = self.bg_frames["startscreenimage"]
        background_rect = background_surf.get_frect(topleft = self.main_image_rect.topleft)
        self.display_surface.blit(background_surf, background_rect)

        title_surf = self.fonts['huge'].render('AMINOMONS!',False,COLORS['black'])
        title_rect = title_surf.get_frect(topleft = background_rect.topleft + vector((WIN_WIDTH*0.35),0))
        self.display_surface.blit(title_surf, title_rect)

        game_message_surf = self.fonts['very large'].render('Select Option with Space',False,COLORS['black'])
        game_message_rect = game_message_surf.get_frect(topleft = title_rect.bottomleft + vector(-100,20))
        self.display_surface.blit(game_message_surf, game_message_rect)

        newgame_surf = self.fonts['very large' if self.index == 0 else "large"].render('New Game',False,COLORS['black'])
        newgame_rect = newgame_surf.get_frect(topleft = game_message_rect.bottomleft)
        self.display_surface.blit(newgame_surf, newgame_rect)

        savedfile_surf = self.fonts['very large' if self.index == 1 else "large"].render('Load Game',False,COLORS['black'])
        savedfile_rect = savedfile_surf.get_frect(topright = game_message_rect.bottomright)
        self.display_surface.blit(savedfile_surf, savedfile_rect)


    #
    # This is how we handle player inputs to move between and select New/Load game.
    #
    def input(self):
        keys = pygame.key.get_just_pressed()
        if keys[pygame.K_LEFT]:
            self.index = (self.index - 1) % 2
        if keys[pygame.K_RIGHT]:
            self.index = (self.index + 1) % 2
        if keys[pygame.K_SPACE]:
            if self.index == 0:
                self.game_active = True
                self.new_game = True
            else: 
                self.game_active = True
                self.new_game = False
        
    #
    # This updates the display message so we can see what is selected.
    #
    def update(self,dt):
        self.input()
        #self.displayScroll(dt)
        self.display_message()
        

