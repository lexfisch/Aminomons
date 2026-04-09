#######################################################################################################################
# Main.py
#   This is the main game file. This is how the game begins and initially creates an instance of the Game Class. We set
#   up the initial variables of the game, loads in teams, and handles general run logic.
#
######################################################################################################################
from pytmx.util_pygame import load_pygame
from os.path import join
from random import randint, choice

from SettingsAndSupport import *
from BigBigData import *
from Sprites import *
from GameObjects import Player, NPC
from SpriteGroups import WorldSprites
from Dialog import DialogSel   
from AminoIndex import *
from FightFightFight import *
from TimerForTimingThings import *
from FusionMethods import *
from AminoMons import *
from PeptideDex import *
from HomePage import *
from PauseMenu import *
from PartyScreen import *
from StorageMenu import *

#
# This is to initate the game loop. When called, one instance of the game class is created.
#
class Game:
    def __init__(self):
        # Initates pygame, sets the display surface, and clock. Starts timers, sets new game and game active variables
        #   creates empty dictionaries for the player and storage.
        pygame.init()
        self.display_surface = pygame.display.set_mode((WIN_WIDTH, WIN_HEIGHT))  
        self.clock = pygame.time.Clock()
        pygame.display.set_caption("AminoMons!")
        self.encounter_timer = Timer(2000, func = self.wild_aminomon)
        self.game_active = False
        self.new_game = False
        self.file = None
        self.player_monsters = {}
        self.player_storage = {}
        self.valid_aminomon_starters = [name for name, info in peptideDex.items() if info['id'] % 3 == 1]

        # This is where we import all the sprite groups. We instantialize all the groups that we will need in this game.
        #   We create WorldSprites for all the world sprites, collisions sprites that will block the player into the map, character
        #   sprites for  
        self.all_sprites = WorldSprites()
        self.collision_sprites = pygame.sprite.Group()
        self.character_sprites = pygame.sprite.Group()
        self.transition_sprites = pygame.sprite.Group()
        self.monster_sprites = pygame.sprite.Group()

        # This is where we set the transition and tint variables
        self.transition_target = None
        self.tint_surf = pygame.Surface((WIN_WIDTH, WIN_HEIGHT))
        self.tint_mode = "untint"
        self.tint_progress = 0
        self.tint_direction = -1
        self.tint_speed = 600

        #  These import all the associated files for the game. We also pass arguments
        #     into the map creation function after using our importer functions
        self.import_game_files()
        self.map_creation(self.tmx_maps['firstlab'], "world")   

        # This sets up our screen overlays like the dialog tree, battle screens, and fusion events
        self.dialog_tree = None
        self.index_open = False
        self.peptide_dex_open = False
        self.pause_menu_open = False
        self.team_open = False
        self.storage_open = False
        self.battle = None
        self.fusion = None
        self.unfusion = None
    
        # Creates all the Menus that we will use in the game
        self.pause_menu = PauseScreen(self.fonts, self.player_monsters, self.monster_frames, self.player_storage)
        self.teamScreen = PartyScreen(self.fonts, self.player_monsters, self.monster_frames)
        self.storageBox = StorageBox(self.fonts, self.player_monsters, self.monster_frames, self.player_storage)
        self.start_screen = StartScreen(self.fonts)
         #self.monster_index = AminoIndex(self.player_monsters, self.fonts, self.monster_frames)
        #self.peptide_dex = PeptideDex(self.fonts)
        #self.pause_menu = PauseScreen(self.fonts, self.player_monsters, self.index_open, self.peptide_dex_open, self.monster_frames)

    #
    # This method creates the team for the player. It will either load in the trainer data from a saved CSV
    #   or if the file doesnt exist or is a new game, will create between 2 and 4 random single Aminomons
    #
    def create_team(self):
        if self.new_game:
            for i in range(randint(2,4)):
                self.player_monsters[i] = Aminomons(choice(self.valid_aminomon_starters), 5, 0)
        else:
            transfer = load_trainer_data()
            if transfer:
                for index, amino, level, xp_amount in transfer:
                    self.player_monsters[index] = Aminomons(amino, level, xp_amount)
            else: 
                for i in range(randint(2,4)):
                    self.player_monsters[i] = Aminomons(choice(self.valid_aminomon_starters), 5, 0)

    #
    # This method loads in a saved storage box from a previous game file.
    #
    def create_storage(self):
        transfer_box = load_storage_data()
        if transfer_box:
            for index, amino, level, xp_amount in transfer_box:
                self.player_storage[index] = Aminomons(amino, level, xp_amount)

    #
    # Sets up frames and sprites, this calls the import functions from our
    #   "SettingsAndSupport" file.
    #
    def import_game_files(self):
        #Map Files
        self.tmx_maps = importTMX('data', 'mapfile')
        #print(self.tmx_maps)

        # Frames for all the NPCs
        self.overworld_frames = {
            'characters': allCharImporter('images', 'characters')
        }

        # Any frames dealing with Aminomons and battle (Aminomon Icons, Aminomon Sprite Sheets, UI Images, and Attack sprite sheets)
        self.monster_frames = {
            'icons': importFolderDict('images', 'iconsAminos'),
            'monsters': importMonster(4,2,'images', 'monsAminos'),
            'ui': importFolderDict('images', 'ui'),
            "attacks": importAttacks('images','attacks')
        }

        self.monster_frames['outline'] = outline_creator(self.monster_frames['monsters'], 4)

        # Loads in the different fonts we use in the game
        self.fonts = {
            "dialog": pygame.font.Font(join('images', 'fonts', 'MatrixType-Regular.ttf'), 30),
            "regular": pygame.font.Font(join('images', 'fonts', 'MatrixType-Regular.ttf'), 18),
            "small": pygame.font.Font(join('images', 'fonts', 'MatrixTypeDisplay-Regular.ttf'), 14),
            "bold": pygame.font.Font(join('images', 'fonts', 'MatrixType-Bold.ttf'), 20),
            "medium": pygame.font.Font(join('images', 'fonts', 'MatrixType-Bold.ttf'), 25),
            "large": pygame.font.Font(join('images', 'fonts', 'MatrixType-Bold.ttf'), 30),
            "very large": pygame.font.Font(join('images', 'fonts', 'MatrixType-Bold.ttf'), 40),
            "huge": pygame.font.Font(join('images', 'fonts', 'MatrixType-Bold.ttf'), 60)
        }

        self.bg_frames = importFolderDict('images', 'backgrounds')
        self.start_animation_frames = importFolder('images', 'other', 'star animation')


    #
    # Called during the start of the game and anytime the player moves from map to map, map to battle, or battle to map
    #
    def map_creation(self, tmx_map, player_start_pos):
        #
        # This will clear the screen before we import another map ontop of it
        #
        for group in (self.all_sprites, self.collision_sprites, self.transition_sprites, self.character_sprites, self.monster_sprites):
            group.empty()
        
        # Loads the TMX Layer for the map tiles.
        for layer in ['Terrain', "Terrain Top"]:
            for x, y, surf in tmx_map.get_layer_by_name(layer).tiles():
                Sprite((x* TILESIZE, y * TILESIZE), surf, self.all_sprites, LAYERS['bg'])

        # Loads the TMX Layer for transitions
        for transit in tmx_map.get_layer_by_name('Transition'):
            TransitionSprite((transit.x, transit.y), (transit.width, transit.height), (transit.properties['target'], transit.properties['pos']), self.transition_sprites)

        # Loads the TMX Layer for Collisions (keep the player within the bounds of the map)
        for colls in tmx_map.get_layer_by_name('Collisions'):
            BorderSprite ((colls.x, colls.y), pygame.Surface((colls.width, colls.height)), self.collision_sprites)

        # Loads the TMX Layer for the Chemical spills on the maps (spawns wild amino acids)
        for patchy in tmx_map.get_layer_by_name('ChemicalSpills'):
            ChemicalSpillSprite((patchy.x, patchy.y), patchy.image, (self.all_sprites, self.monster_sprites), patchy.properties['classroom'], patchy.properties['aminos'], patchy.properties['level'])
            #print(f'{patchy}')
            #print(f'{patchy.properties}')

        # Loads in the TMX Layer for GameObjects. These are the NPC and the Player characters.
        for obj in tmx_map.get_layer_by_name("GameObjects"):
            if obj.name == 'Player':
                if obj.properties['pos'] == player_start_pos:
                    self.player = Player(
                        pos = (obj.x, obj.y),
                        frames = self.overworld_frames['characters']['player'],
                        groups  = self.all_sprites,
                        facing_direction = obj.properties['direction'],
                        collision_sprites = self.collision_sprites
                    )
                    self.player.unblock()
                    
            else:
                NPC(
					pos = (obj.x, obj.y), 
					frames = self.overworld_frames['characters'][obj.properties['graphic']], 
					groups = (self.all_sprites, self.collision_sprites, self.character_sprites),
					facing_direction = obj.properties['direction'],
					character_data = TrainerInfo[obj.properties['character_id']],
					player = self.player,
					start_dialog = self.start_dialog,
					collision_sprites = self.collision_sprites,
					radius = obj.properties['radius'],
					healer = obj.properties['character_id'] == 'healer',
                    fuser = obj.properties ['character_id'] == 'fuser',
                    unfuser = obj.properties['character_id'] == 'unfuser',
                    storagePC = obj.properties['character_id'] == 'storage'
                    )

    #
    # Handles the user input to interact with NPCs, open the Pause Menu, currently opens the Storage Box for troubleshooting, 
    #   and can exit the game if you hit 1.
    def input(self):
        if not self.dialog_tree and not self.battle:
            keys = pygame.key.get_just_pressed()
        
            if self.pause_menu_open: self.player.block()
            if self.storage_open: self.player.block()
            if self.fusion: self.player.block()
            if self.unfusion: self.player.block()
            if self.battle: self.player.block()

            if keys[pygame.K_SPACE]:
                for character in self.character_sprites:
                    if check_if_touching(100, self.player, character):
                        self.player.block()
                        self.start_dialog(character)

            #if keys[pygame.K_RETURN]:
            #    self.index_open = not self.index_open
            #    self.player.blocked = not self.player.blocked

            #if keys[pygame.K_0]:
            #    self.peptide_dex_open = not self.peptide_dex_open
            #    self.player.blocked = not self.player.blocked 

            if keys[pygame.K_1]:
                pygame.quit()
                exit()

            #if keys[pygame.K_s]:
            #    save_trainer_data(self.player_monsters)

            #if keys[pygame.K_t]:
            #    self.team_open = not self.team_open
            #    self.player.blocked = not self.player.blocked

            if keys[pygame.K_p]:
                self.pause_menu_open = not self.pause_menu_open
                self.player.blocked = not self.player.blocked

            if keys[pygame.K_s]:
                self.storage_open = not self.storage_open
                self.player.blocked = not self.player.blocked

    #
    # Handles character dialog when the player is interacting with them
    #
    def start_dialog(self, character):
        if not self.dialog_tree:
            self.dialog_tree = DialogSel(character, self.player, self.all_sprites, self.fonts['dialog'], self.stop_dialog)

    #
    # Handles logic for interacting with NPCs. This is for the Healer, Fuser, Unfuser, Storage Box, and interacting with a fightable
    #   trainer. 
    #
    def stop_dialog(self, character):
        self.dialog_tree = None
        if character.healer:
            for monster in self.player_monsters.values():
                monster.health = monster.get_single_stat('MAX_HEALTH')
                monster.energy = monster.get_single_stat('MAX_ENERGY')

                self.player.unblock()

        if character.fuser:
            self.check_fusion()
            self.player.unblock()

        if character.unfuser:
            self.check_unfusion()
            self.player.unblock()

        if character.storagePC:
            self.storage_open = not self.storage_open
            self.player.unblock()

        elif not character.character_data['defeated'] and not (character.healer or character.fuser or character.unfuser or character.storagePC):
            self.transition_target = Fight(
                player_monsters = self.player_monsters,
                opponent_monsters = character.monsters,
                monster_frames = self.monster_frames,
                bg_surf = self.bg_frames[character.character_data['classroom']],
                fonts = self.fonts,
                end_battle = self.end_battle,
                character = character
            )
            self.tint_mode = 'tint'
            #self.player.unblock()
        
        else:
            self.player.unblock()
            #self.check_fusion()

    #
    # Checks if the player has collided with a transition sprite. If so, it will move the player to the next map.
    #
    def transition_check(self):
        sprites = [sprite for sprite in self.transition_sprites if sprite.rect.colliderect(self.player.hitbox)]
        if sprites:
            self.player.block()
            self.transition_target = sprites[0].target
            self.tint_mode = 'tint'
        
    #
    # This handles the tinting the screen. It will tint between maps and when going into and leaving a battle.
    #
    def tint_screen(self,dt):
        if self.tint_mode == "untint":
            self.tint_progress -= self.tint_speed * dt

        if self.tint_mode == "tint":
            self.tint_progress += self.tint_speed * dt
            if self.tint_progress >= 255:
                if type(self.transition_target) == Fight:
                    self.battle = self.transition_target
                elif self.transition_target == "level":
                    self.battle = None
                else:
                    self.map_creation(self.tmx_maps[self.transition_target[0]], self.transition_target[1])
                
                self.tint_mode = "untint"
                self.transition_target = None
                
        self.tint_progress = max(0, min(self.tint_progress, 255))
        self.tint_surf.set_alpha(self.tint_progress) #sets the alpha value/ transparency of the surface
        self.display_surface.blit(self.tint_surf, (0,0))

    #
    # This handles the end of battle logic. It sends the Player back to the map from battle and start the end
    #   battle dialog from the NPC.
    #
    def end_battle(self, character):
        self.transition_target = 'level'
        self.tint_mode = 'tint'
        if character:
            character.character_data['defeated'] = True
            self.start_dialog(character)
        elif not self.fusion:
            self.player.unblock()
            #self.check_fusion()

    #
    # This checks if an Aminoacid meets the level requirements to fuse into a higher oligo state
    #
    def check_fusion(self):
        for index, monster in self.player_monsters.items():
            if monster.fusion:
                if monster.level >= monster.fusion[1]:
                    self.player.block()
                    self.fusion = Fusion(self.monster_frames['monsters'], monster.name, monster.fusion[0], self.fonts['bold'], self.end_fusion, self.start_animation_frames)
                    self.player_monsters[index] = Aminomons(monster.fusion[0], monster.level, 0)
    
    #
    # This unblocks the character after the fusion animation sequence 
    #
    def end_fusion(self):
        self.fusion = None
        self.player.unblock()

    #
    # This checks if an Aminoacid is in a higher oligo state and then unfuses them.
    #
    def check_unfusion(self):
        for index, monster in self.player_monsters.items():
            if monster.unfusion:
                self.player.block()
                self.unfusion = Unfusing(self.monster_frames['monsters'], monster.name, monster.unfusion, self.fonts['bold'], self.end_unfusion, self.start_animation_frames)
                self.player_monsters[index] = Aminomons(monster.unfusion, monster.level, 0) 

    #
    # This unblocks the character after the unfusion animation.
    #
    def end_unfusion(self):
        self.unfusion = None
        self.player.unblock()
        
    #
    # This checks if the player is colliding with a sprite for the chemical patches. If so, it will start a timer to
    #   for a wild Aminoacid to spawn.
    #
    def check_monster(self):
        if [sprite for sprite in self.monster_sprites if sprite.rect.colliderect(self.player.hitbox)] and not self.battle and self.player.direction:
            if not self.encounter_timer.active:
                self.encounter_timer.turnOn()

    #
    # This is a function for the Checmical Spills on the maps. If you walk over them, it will check for collisions and if so
    #   starts the encounter timer. If the timer runs out, it will send the player into a Battle with the amino acids. It will 
    #   assign the sprites a random increase or decrease from the base level on the map file.
    #
    def wild_aminomon(self):
        sprites = [sprite for sprite in self.monster_sprites if sprite.rect.colliderect(self.player.hitbox)]
        if sprites and self.player.direction:
            self.encounter_timer.duration = randint(800,2500)
            self.player.block()

            self.transition_target = Fight(
                player_monsters = self.player_monsters, 
				opponent_monsters = {index:Aminomons(monster, sprites[0].level + randint(-2,2), 0) for index, monster in enumerate(sprites[0].monsters)}, 
				monster_frames = self.monster_frames, 
				bg_surf = self.bg_frames[sprites[0].classroom], 
				fonts = self.fonts, 
				end_battle = self.end_battle,
				character = None
            )
            self.tint_mode = 'tint'

    #
    # This is called on game. It will start our clock (using dt), it will then check if the game is active. This starts as False
    #   to send us to the Home Screen. When we select start or load, it will start the game and if load, then it will load in 
    #   the saved csv.
    #
    def run(self):
        while True:
            dt = self.clock.tick() / 1000
            self.display_surface.fill('black')

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    exit()

            #
            # This checks if the game is active. It it is, it will update the game functions. We start a timer, takes an input, 
            #   checks if the player is going from one map to another, updates the All Sprites group, checks whether we're on a 
            #   chemical spill patch, then checks if we have any overlays to update: the dialog, the pause menu, the battle, fusion
            #   and unfusion, whether the team screen is open, whether the storage is open, and then updates the tint screen timer.
            #
            if self.game_active:

                self.encounter_timer.update()
                self.input()
                self.transition_check()
                self.all_sprites.update(dt)
                self.check_monster()
                self.all_sprites.draw(self.player)
            
                #if self.index_open: self.monster_index.update(dt)  # No longer needed here, this will only open from the pause menu
                #if self.peptide_dex_open: self.peptide_dex.update(dt) # No longer needed here, this will only open from the pause menu
                if self.dialog_tree: self.dialog_tree.update()
                if self.pause_menu_open: self.pause_menu.update(dt)
                if self.battle: self.battle.update(dt)
                if self.fusion: self.fusion.update(dt)
                if self.unfusion: self.unfusion.update(dt)
                if self.team_open: self.teamScreen.update(dt)
                if self.storage_open: self.storageBox.update()
                self.tint_screen(dt)
            
            # If the game is not active, it will 
            else:
                self.start_screen.update(dt)
                self.game_active = self.start_screen.game_active
                self.new_game = self.start_screen.new_game
                if self.game_active:
                    self.create_team()
                    self.create_storage()
                
            # This updates the screen while running. Since we pass no arguments, it updates the 
            #   entire screen.
            pygame.display.update()
            
#
# This to what starts the Game Class. It will create one instance of the Game class.
#
if __name__ == '__main__':
    newGame = Game()
    newGame.run()


    






        
