#######################################################################################################################
# FightFightFight.py
# This file contains the battle logic. It takes in the player aminomons, the opponent aminomons, a background for the 
# fight, fonts, an end battle boolean, and NPC information
#
#
######################################################################################################################
from random import choice
import pygame.freetype
from TimerForTimingThings import *
from SettingsAndSupport import *
from BigBigData import *
from SpriteGroups import SpritesForFights
from Sprites import *

#
# This creates an instance of the Fight class.
#
class Fight:
    def __init__(self, player_monsters, opponent_monsters, monster_frames, bg_surf, fonts, end_battle, character):
        self.display_surface = pygame.display.get_surface()
        self.bg_surf = bg_surf
        self.monster_frames = monster_frames
        self.fonts = fonts
        self.monster_data = {'player': player_monsters, 'opponent': opponent_monsters}
        self.battle_over = False
        self.end_battle = end_battle
        self.character = character

        # Turn-based state: alternates between player and enemy turns
        self.phase = None  # 'player_turn' or 'enemy_turn'

        # Sets the groups for all the sprites used in battle.
        self.battle_sprites = SpritesForFights()
        self.player_sprites = pygame.sprite.Group()
        self.opponent_sprites = pygame.sprite.Group()

        # Initial selections are set to None, Player, and indexes are established. 
        self.current_monster = None
        self.selection_mode = None
        self.selected_attack = None
        self.selection_side = 'player'
        self.screen_state = "choose"

        self.indexes = {
            'choosing': 0,
            'monster': 0,
            'attacks': 0,
            'switch': 0,
            'target': 0
        }
        self.create_sides()
        self.start_player_turn()

    #
    # This sets up the battle positions for the Aminomons and will load the first Aminomon in the party.
    #
    def create_sides(self):
        for entity, monster in self.monster_data.items():
            for index, monster in {a:b for a,b in monster.items() if a < 1}.items():
                self.create_aminomon(monster, index, index, entity)

        for i in range(len(self.opponent_sprites)):
            del self.monster_data['opponent'][i]

    #
    # Helpers for turn-based flow
    #
    def get_active_sprite(self, side):
        group = self.player_sprites if side == 'player' else self.opponent_sprites
        if not group:
            return None
        sprites_by_pos = sorted(group.sprites(), key=lambda s: s.pos_index)
        return sprites_by_pos[0] if sprites_by_pos else None

    def start_player_turn(self):
        self.phase = 'player_turn'
        self.current_monster = self.get_active_sprite('player')
        self.selection_side = 'player'
        self.selection_mode = 'choosing'
        self.indexes = {k: 0 for k in self.indexes}

    def start_enemy_turn(self):
        self.phase = 'enemy_turn'
        self.current_monster = self.get_active_sprite('opponent')
        if self.current_monster:
            self.opponent_attack()
        # If battle didn't end during enemy action, return control to player
        if not self.battle_over:
            self.start_player_turn()

    #
    # This will create the Monster Sprite and Sprites for Name and Level of the Aminomon.
    #
    def create_aminomon(self, monster, index, pos_index, entity):
        monster.paused = False
        frames = self.monster_frames['monsters'][monster.name]
        outline_frames = self.monster_frames['outline'][monster.name]

        if entity == 'player':
            pos = list(PositionsInBattle['player'].values())[pos_index]
            groups = (self.battle_sprites, self.player_sprites)
           
        else: 
            pos = list(PositionsInBattle['opp'].values())[pos_index]
            groups = (self.battle_sprites, self.opponent_sprites)

        # Creates the Aminomon Sprite
        monster_sprite = AminomonSprites(pos, frames, groups, monster, index, pos_index, entity, self.apply_attack, self.create_aminomon)
        AminomonOutline(monster_sprite, self.battle_sprites, outline_frames)

        # Creates the Name and Level sprites for the Aminomon
        name_pos = monster_sprite.rect.midright + vector(10, -100) #if entity == 'player' else monster_sprite.rect.midright + vector(-40,-70)
        name_sprite = AminomonName(name_pos, monster_sprite, self.battle_sprites, self.fonts['regular'])
        level_pos = name_sprite.rect.bottomright #if entity == 'player' else name_sprite.rect.bottomright
        AminomonLevel(entity, level_pos, monster_sprite, self.battle_sprites, self.fonts['small'])
        AminomonStats(monster_sprite.rect.midbottom + vector(0,20), monster_sprite, (150,48), self.battle_sprites, self.fonts['small'])
    
    #
    # This handles the user input for the battle class (player turn only).
    #         
    def input(self):
        # Only process input during player's turn with an active monster
        if self.phase != 'player_turn' or not self.selection_mode or not self.current_monster:
            return

            keys = pygame.key.get_just_pressed()

            # Match statement for limiters. Each of our selections has a different number of options for selections and this will
            #   resolve using a large if statement for the Up and Down keys.
            match self.selection_mode:
                case 'choosing':
                    limiter = len(ChoicesForBattle)
                case 'attacks':
                    self._current_usable_attacks = self.current_monster.monster.get_skills(all = False)
                    limiter = len(self._current_usable_attacks)
                case 'switch':
                    limiter = len(self.available_monsters)
                case 'target':
                    limiter = len(self.opponent_sprites) if  self.selection_side == 'opponent' else len(self.player_sprites)

            # If there are no options in the current mode (e.g. no usable attacks), bail out safely
            if limiter == 0:
                if self.selection_mode == 'attacks':
                    self.selection_mode = 'choosing'
                    self.indexes['choosing'] = 0
                return

            if keys[pygame.K_DOWN]:
                self.indexes[self.selection_mode] = (self.indexes[self.selection_mode] + 1) % limiter
            
            if keys[pygame.K_UP]:
                if self.indexes[self.selection_mode] == 0: pass
                else: self.indexes[self.selection_mode] = (self.indexes[self.selection_mode] - 1) % limiter
            
            # This selects an action, whether we are on switch, attack, or in a target mode.
            if keys[pygame.K_SPACE]:
                
                # This will create the new Aminomon in a switch and kill the current display sprite
                if self.selection_mode == 'switch':
                    index, new_monster = list(self.available_monsters.items())[self.indexes['switch']]
                    self.current_monster.kill()
                    self.create_aminomon(new_monster, index, self.current_monster.pos_index, 'player')
                    self.selection_mode = None
                    # After switching, hand turn to the enemy
                    if not self.battle_over:
                        self.start_enemy_turn()
                
                # If the user selects an attack, this will start the Aminomon attack animation
                if self.selection_mode == 'attacks':
                    self.selection_mode = 'target'
                    # Use cached usable attacks to avoid recomputing and respect energy constraints
                    usable_attacks = getattr(self, '_current_usable_attacks', self.current_monster.monster.get_skills(all = False))
                    if not usable_attacks:
                        # No usable attacks; return to the main choice menu
                        self.selection_mode = 'choosing'
                        self.indexes['choosing'] = 0
                        self.indexes['attacks'] = 0
                        return
                    self.selected_attack = usable_attacks[self.indexes['attacks']]
                    self.selection_side = SKILLS_DATA[self.selected_attack]['target']
                    sprite_group = self.opponent_sprites if self.selection_side == 'opponent' else self.player_sprites
                    sprites = {sprite.pos_index: sprite for sprite in sprite_group}
                    monster_sprite = sprites[list(sprites.keys())[self.indexes['target']]]

                    if self.selected_attack:
                        # self.current_monster.check_speed
                        self.current_monster.activate_attack(monster_sprite, self.selected_attack)
                        self.selected_attack, self.current_monster, self.selection_mode = None, None, None

                # Handles the selection input while on the choosing menu; whether it is attack, switch, or capture
                if self.selection_mode == 'choosing':
                    if self.indexes['choosing'] == 0:
                        # Only enter attacks mode if there are usable skills
                        if self.current_monster.monster.get_skills(all = False):
                            self.selection_mode = 'attacks'

                    if self.indexes['choosing'] == 1:
                        self.selection_mode = 'switch'

                    if self.indexes['choosing'] == 2:
                        # Attempt to catch a wild Aminomon (only allowed in wild battles, not trainers)
                        if self.character is not None:
                            # Trainer battle; cannot catch their Aminomons
                            TempSprite(self.current_monster.rect.center, self.monster_frames['ui']['cross'], self.battle_sprites, 1000)
                        else:
                            self.selection_side = 'opponent'
                            sprite_group = self.opponent_sprites
                            if not sprite_group:
                                return
                            sprites = {sprite.pos_index: sprite for sprite in sprite_group}
                            monster_sprite = sprites[list(sprites.keys())[self.indexes['target']]]

                            # Require the target to be below 50% HP to catch
                            if monster_sprite.monster.health < monster_sprite.monster.get_single_stat('MAX_HEALTH') * 0.5:
                                if len(self.monster_data['player']) <= 5:
                                    self.monster_data['player'][len(self.monster_data['player'])] = monster_sprite.monster
                                    monster_sprite.delayed_kill(None)
                                else: 
                                    # Party full feedback
                                    TempSprite(monster_sprite.rect.center, self.monster_frames['ui']['cross'], self.battle_sprites, 1000) 
                            else:
                                # Too much health to catch
                                TempSprite(monster_sprite.rect.center, self.monster_frames['ui']['cross'], self.battle_sprites, 1000)

                self.indexes = {k: 0 for k in self.indexes}

            # Will return to a previous window if the user is in the attack menu, switch menu, or targeting option.
            if keys[pygame.K_ESCAPE]:
                if self.selection_mode in ('attacks', 'switch', 'target'):
                    self.selection_mode = 'choosing'

    #
    # This will take in two monsters and two attacks and then calculate which is 
    #   faster and apply the attacks in a specific area. This is an unfinished method to move the battle
    #   sequence from Initiative based to one that uses direct speed comparisons
    #
    def check_order(self): #monster1, monster1_attack, monster2, monster2attack
        pass
        # compare speed and decide order
        # if monster1.monster.get_single_stat['speed'] >= monster2.monster.get_single_stat['speed']:
            # 

        # apply attack 1
        # check end battle
        # apply attack 2
        # check end battle
        # self.screen_state = "choose" 
    
    #
    # This creates a sprite for a selected attack. It handles the battle logic when applying an attack from 
    #   one of the Aminomon in battle. If it is an attack, it will calulate damage, apply damage, and then check if the
    #   Aminomon has died. If it is an attack it will calculate the recovery amount.
    #
    def apply_attack(self, target_sprite, attack, amount):
        AnimatedAttack(target_sprite.rect.center, self.monster_frames['attacks'][SKILLS_DATA[attack]['animation']], self.battle_sprites)
        attack_element = SKILLS_DATA[attack]['element']
        target_element = target_sprite.monster.element

        # This checks to see if there is a type advantage
        if attack_element == 'fire' and target_element == 'earth' or \
           attack_element == 'water' and target_element == 'fire' or \
           attack_element == 'electric' and target_element == 'water' or \
           attack_element == 'earth' and target_element == 'electric':
            amount *= 2

        # This check to see if there is a type disadvantage
        if attack_element == 'fire' and target_element == 'water' or \
           attack_element == 'water' and target_element == 'electric' or \
           attack_element == 'electric' and target_element == 'earth' or \
           attack_element == 'earth' and target_element == 'fire':
            amount *= 0.5

        target_defense = 1 - target_sprite.monster.get_single_stat('defense')/1000
        target_defense = max(0, min(1, target_defense))

        if attack == 'heal':
            target_sprite.monster.health += amount
        
        else:
            target_sprite.monster.health -= amount * target_defense
        self.check_death()

    #
    # This checks to see if an Aminomon has been beaten. If the health drops below 0 it will select the next monster from the 
    #   players Aminomon party if it was a player Aminomon; otherwise, it will select another Aminomon from the opponent and
    #   update the experience of the Aminomon in battle.
    #
    def check_death(self):
        for monster_sprite in self.opponent_sprites.sprites() + self.player_sprites.sprites():
            if monster_sprite.monster.health <= 0:
                if self.player_sprites in monster_sprite.groups():
                    active_monsters = [(monster_sprite.index, monster_sprite.monster) for monster_sprite in self.player_sprites.sprites()]
                    available_monsters = [(index, monster) for index, monster in self.monster_data['player'].items() if monster.health > 0 and (index, monster) not in active_monsters]

                    if available_monsters:
                        new_monster_data = [(monster, index, monster_sprite.pos_index, 'player') for index, monster in available_monsters][0]
                    else:
                        new_monster_data = None
                
                else:
                    new_monster_data = (list(self.monster_data['opponent'].values())[0], monster_sprite.index, monster_sprite.pos_index, 'opponent') if self.monster_data['opponent'] else None
                    if self.monster_data['opponent']:
                        del self.monster_data['opponent'][min(self.monster_data['opponent'])]
                    
                    xp_amount = monster_sprite.monster.level * 100 / len(self.player_sprites)
                    for player_sprite in self.player_sprites:
                        player_sprite.monster.add_xp(xp_amount)

                monster_sprite.delayed_kill(new_monster_data)

    #
    # This will select a random attack from the abilities of the opponent Aminomon. It will then activate the
    #   selected ability.
    #
    def opponent_attack(self):
        if self.current_monster is None:
            return

        # Only choose skills the opponent can currently pay the energy cost for
        usable_skills = self.current_monster.monster.get_skills(all = False)
        if not usable_skills:
            return

        ability = choice(usable_skills)

        if not self.player_sprites or not self.opponent_sprites:
            return

        # Target depends on skill's target side
        if SKILLS_DATA[ability]['target'] == 'player':
            random_target = choice(self.player_sprites.sprites())
        else:
            random_target = choice(self.opponent_sprites.sprites())

        self.current_monster.activate_attack(random_target, ability)
        # return (target, ability)

    #
    # Checks whether there are still Aminomons to be used in battle. If no, then it will end the fight 
    #   if the player has won or quits the game without saving if the player loses.
    #
    def check_end_battle(self):
        if len(self.opponent_sprites) == 0 and not self.battle_over:
            self.battle_over = True
            self.end_battle(self.character)
            for monster in self.monster_data['player'].values():
                monster.initiative = 0
            
        if len(self.player_sprites) == 0 and not self.battle_over:
            # Player lost the battle; hand control back to the main game instead of quitting outright
            self.battle_over = True
            self.end_battle(None)

    #
    # This calls specific draw functions depending on what the Player selects. 
    #
    def draw_interface(self):
        if self.current_monster:
            if self.selection_mode == 'choosing':
                self.draw_choosing()
            if self.selection_mode == 'attacks':
                self.draw_attacks()
            if self.selection_mode == 'switch':
                self.draw_enchange()

    #
    # When there is no selection yet, this will display the options available to the Player.
    #
    def draw_choosing(self):
        for index, (option, data_dict) in enumerate(ChoicesForBattle.items()):        
            if index == self.indexes['choosing']:
                surf = self.monster_frames['ui'][f"{data_dict['icon']}_highlight"]
            else:
                surf = pygame.transform.grayscale(self.monster_frames['ui'][data_dict['icon']])
            rect = surf.get_frect(center = self.current_monster.rect.midleft + data_dict['pos'])
            self.display_surface.blit(surf, rect)

    #
    # If the player selects attack, this will display the attacks available to the Player's Aminomons.
    #    It will color code the attack name to the element type of the attack.
    #
    def draw_attacks(self):
        abilities = self.current_monster.monster.get_skills(all = False)
        width, height = 150, 200
        visible_attacks = 5
        item_height = height / visible_attacks
        #v_offset = 0 if self.indexes['attacks'] < visible_attacks else -(self.indexes['attack'] - visible_attacks + 1) * item_height
        bg_rect = pygame.FRect((0,0), (width, height)).move_to(midleft = self.current_monster.rect.midright + vector(20,0))
        pygame.draw.rect(self.display_surface, COLORS['white'], bg_rect, 0, 5)

        for index, ability in enumerate(abilities):
            selected = index == self.indexes['attacks'] 
            if selected:
                element = SKILLS_DATA[ability]['element']
                text_color = COLORS[element] if element != 'normal' else COLORS['black']
            else:
                text_color = COLORS['light']
            
            text_surf = self.fonts['regular'].render(ability, False, text_color)
            text_rect = text_surf.get_frect(center = bg_rect.midtop + vector(0, item_height/2 + index * item_height))
            text_bg_rect = pygame.FRect((0,0), (width, height)).move_to(center = text_rect.center)
            self.display_surface.blit(text_surf, text_rect)

    #
    # If the Player selects to switch out their current Aminomon, this is the method that draws the switch selections.
    #
    def draw_enchange(self):
        width, height = 300, 320
        visable_monsters = 4
        item_height = height/visable_monsters
        v_offset = 0 if self.indexes['switch'] < visable_monsters else -(self.indexes['switch'] - visable_monsters +1)* item_height
        bg_rect = pygame.FRect((0,0), (width, height)).move_to(midright = self.current_monster.rect.midleft + vector(-20,0))
        pygame.draw.rect(self.display_surface, COLORS['white'], bg_rect, 0, 5)

        active_monsters = [(monster_sprite.index, monster_sprite.monster) for monster_sprite in self.player_sprites]
        self.available_monsters = {index: monster for index, monster in self.monster_data['player'].items() if (index, monster) not in active_monsters and monster.health > 0}

        for index, monster in enumerate(self.available_monsters.values()):
            selected = index == self.indexes['switch']
            item_bg_rect = pygame.FRect((0,0), (width, item_height)).move_to(midleft = (bg_rect.left, bg_rect.top + item_height / 2 + index * item_height + v_offset))

            #icon_surf = self.monster_frames['icons'][monster.name]
            #icon_rect = icon_surf.get_frect(midleft = bg_rect.topleft + vector(10,item_height / 2 + index * item_height + v_offset))
            text_surf = self.fonts['regular'].render(f'{monster.name} ({monster.level})', False, COLORS['red'] if selected else COLORS['black'])
            text_rect = text_surf.get_frect(midleft = bg_rect.topleft + vector(10,item_height / 2 + index * item_height + v_offset))

            if selected:
                if item_bg_rect.collidepoint(bg_rect.topleft):
                    pygame.draw.rect(self.display_surface, COLORS['dark white'], item_bg_rect, 0, 0, 5, 5)
                elif item_bg_rect.collidepoint(bg_rect.midbottom + vector(0,-1)):
                    pygame.draw.rect(self.display_surface, COLORS['dark white'], item_bg_rect, 0,0,0,0,5,5)
                else:
                    pygame.draw.rect(self.display_surface, COLORS['dark white'], item_bg_rect)

            if bg_rect.collidepoint(item_bg_rect.center):
                self.display_surface.blit(text_surf, text_rect)
                health_rect = pygame.FRect((text_rect.bottomleft + vector(0,4)), (100,4))
                energy_rect = pygame.FRect((health_rect.bottomleft + vector(0,2)), (80,4))
                draw_bars(self.display_surface, health_rect, monster.health, monster.get_single_stat('MAX_HEALTH'), COLORS['green'], COLORS['black'])
                draw_bars(self.display_surface, energy_rect, monster.energy, monster.get_single_stat('MAX_ENERGY'), COLORS['yellow'], COLORS['black'])

    #
    # Update method for the battle class
    #
    def update(self, dt):
        # First checks if the battle is over
        self.check_end_battle()

        # Then checks user inputs, updates timers, updates the battle sprites, and then checks if any Aminomon has aa 
        #   initiative over 100.
        self.input()
        self.update_timers()
        self.battle_sprites.update(dt)
        self.check_active()

        # Blits and draws the battle scene to the display surface, then displays the user selections.
        self.display_surface.blit(self.bg_surf, (0,0))
        self.battle_sprites.draw(self.current_monster, self.selection_side, self.selection_mode, self.indexes['target'], self.player_sprites, self.opponent_sprites)
        self.draw_interface()