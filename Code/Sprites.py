######################################################################################################################
# Sprites.py
# This file contains all the class information and functions for Sprites that we wil use.
#
######################################################################################################################

from SettingsAndSupport import *
from TimerForTimingThings import Timer
from random import uniform


#
# Section: World
# This first section will contain all the sprites that we will use for the world. 
#

#
# This is the general Sprite class. It will create shared variables and call super using 
#   the parent class  "groups." It uses the position, surface, group that the sprite is associated with, 
#   and assigns the z layer to Main. It creates a rect using the surface, then creates a hitbox for collisions
#   using the sprite rect.
#
class Sprite(pygame.sprite.Sprite):
    def __init__(self, pos, surf, groups, z = LAYERS['main']):
        super().__init__(groups)
        self.image = surf
        self.rect = self.image.get_frect(topleft = pos)
        self.z = z
        self.y_sort = self.rect.centery
        self.hitbox = self.rect.copy()


#
# This is the class for Wall Border sprites; it inherits the Sprite class as a parent. This class is for
#   the collisions layer within the TMX map. It creates the structure for our map surface, blocking the 
#   player character from running through the walls into the void.  
#
class BorderSprite(Sprite):
    def __init__(self, pos, surf, groups):
        super().__init__(pos, surf, groups)
        self.hitbox = self.rect.copy()

#
# This is the class for map Transition sprites; it inherits the Sprite class as a parent. This class is for
#   the transition layer within the TMX map. This creates surfaces that when collided with use the 
#   target variable to call the next map file. This is essentially the door into the next map.
#
class TransitionSprite(Sprite):
    def __init__(self, pos, size, target, groups):
        surf = pygame.Surface(size)
        super().__init__(pos, surf, groups)
        self.target = target


#
# This is the class for map Chemical Spills sprites; it inherits the Sprite class as a parent. This class is for
#   the Chemical Spill layer within the TMX map. This creates surfaces that when walked on can trigger
#   an encounter with a wild Aminomon. These appear visually as different colored chemical spills within the labs.
#   It pulls in the associated properties from each patch: Classroom PNG used for battle overlays, the Aminomons 
#   that can be spawned within the patch, and the base level of the Aminomon that can be spawned.
#
class ChemicalSpillSprite(Sprite):
    def __init__(self, pos, surface, groups, classroom, aminos, level):
        self.classroom = classroom
        super().__init__(pos, surface, groups, LAYERS['main'])
        self.y_sort -= 40
        self.classroom = classroom
        self.monsters = aminos.split(",")
        self.level = int(level)

#
# This is the class for Sprite Animation; it inherits the Sprite class as a parent. This class
#   initaties the frame index to zero and saves the frames for the animated sprite. It has 
#   an animation function that cycles through the frames to animate the sprite. It has
#   an update class that calls the animation function.
#
class SpriteAnimation(Sprite):
	def __init__(self, pos, frames, groups, z = LAYERS['main']):
		self.frame_index, self.frames = 0, frames
		super().__init__(pos, frames[self.frame_index], groups, z)

	def animate(self, dt):
		self.frame_index += ANISPEED * dt
		self.image = self.frames[int(self.frame_index % len(self.frames))]

	def update(self, dt):
		self.animate(dt)




########################################################################################################################
#
# Section: Battle
# This second section will contain all the sprites that we will use for battle.
#


#
# This is the class for Aminomon sprites used in battle; it inherits the Sprite class as a parent. This class is for
#   the Aminomon that gets displayed.   
#
class AminomonSprites(pygame.sprite.Sprite):
    def __init__(self, pos, frames, groups, monster, index, pos_index, entity, apply_attack, create_monster):
        self.index = index 
        self.pos_index = pos_index
        self.entity = entity
        self.monster = monster
        self.frame_index, self.frames, self.state = 0, frames, 'idle'
        self.animation_speed = ANISPEED + uniform(-1,1)
        self.z = BATTLEGRAPHICSLAYERS['monster']
        self.highlight = False
        self.target_sprite = None
        self.current_attack = None
        self.apply_attack = apply_attack
        self.create_monster = create_monster

        #
        # Assigns the frames to the image using the "idle" or "attack" state.
        #
        super().__init__(groups)
        self.image = self.frames[self.state][self.frame_index]
        self.rect = self.image.get_frect(center = pos)

        #
        # These are Timers that we will use for sprites. They will be used in functions
        #   for removing an outline (highlight) and removing timed sprites.
        #
        self.timers = {
            'remove highlight': Timer(300, func = lambda: self.set_highlight(False)), 
            'kill': Timer(600, func = self.destroy) 
        }

    #
    # This function is used to move through the sprite frames after selecting whether the
    #   sprite is in an 'idle' or 'attack' state.
    #
    def animate(self, dt):
        self.frame_index += ANISPEED * dt
        if self.state == 'attack' and self.frame_index >= len(self.frames['attack']):
            self.apply_attack(self.target_sprite, self.current_attack, self.monster.get_attack_value(self.current_attack))
            self.state = 'idle'

        self.adjusted_frame_index = int(self.frame_index % len(self.frames[self.state]))
        self.image = self.frames[self.state][self.adjusted_frame_index]

        if self.highlight:
            white_surface = pygame.mask.from_surface(self.image).to_surface()
            white_surface.set_colorkey('black')
            self.image = white_surface

    #
    # This will outline an Aminomon. This is used in battle to show the active Aminomon
    #   in battle. 
    #
    def set_highlight(self, value):
        self.highlight = value
        if value:
            self.timers['remove highlight'].turnOn()
    
    #
    # This will set parameters for attacking in battle. It change the Aminomon state, 
    #   sets and index, sets targets and the current attack. Then it will call a function to 
    #   substract the ability energy cost from the monsters energy.  
    #
    def activate_attack(self, target_sprite, attack):
        self.state = 'attack'
        self.frame_index = 0
        self.target_sprite = target_sprite
        self.current_attack = attack
        self.monster.subtract_cost(attack)

    #
    # This will turn the kill timer on when an Aminomon is defeated. It will set the next monster 
    #   and set the timer to remove the associated sprite to replace it with the next Aminomon in the team.
    #
    def delayed_kill(self, new_monster):
        if not self.timers['kill'].active:
            self.next_monster_data = new_monster
            self.timers['kill'].turnOn()

    #
    # This will be the function that changes the Aminomon from the defeated to the next in the party
    #
    def destroy(self):
        if self.next_monster_data:
            self.create_monster(*self.next_monster_data)
        self.kill()

    #
    # This function will update the animation so we can cycle through the Aminomon animation sprites
    #
    def update(self, dt):
        for timer in self.timers.values():
            timer.update()
        self.animate(dt)
        self.monster.update(dt)

#
# This is the class for battle Aminomon Outline sprites; it inherits the Sprite class as a parent. This class is for
#   the outline that will show up around the Aminomon when it is selected.
#
class AminomonOutline(pygame.sprite.Sprite):
    def __init__(self, monster_sprite, groups, frames):
        super().__init__(groups)
        self.z = BATTLEGRAPHICSLAYERS['outline']
        self.monster_sprite = monster_sprite
        self.frames = frames

        self.image = self.frames[self.monster_sprite.state][self.monster_sprite.frame_index]
        self.rect = self.image.get_frect(center = self.monster_sprite.rect.center)
        
        def update(self, _):
            self.image = self.frames[self.monster_sprite.state][self.monster_sprite.adjusted_frame_index]
            if not self.monster_sprite.groups():
                self.kill() 


#
# This is the class for the battle Aminomon Name sprites; it inherits the Sprite class as a parent. This class is for
#   the name of the Aminomon that gets displayed in battle.
#
class AminomonName(pygame.sprite.Sprite):
    def __init__(self, pos, monster_sprite, groups, font):
        super().__init__(groups)
        self.monster_sprite = monster_sprite
        self.z = BATTLEGRAPHICSLAYERS['name']

        text_surface = font.render(monster_sprite.monster.name, False, COLORS['black'])
        padding = 10

        self.image = pygame.Surface((text_surface.get_width() + 2 * padding, text_surface.get_height() +2 * padding))
        self.image.fill(COLORS['white'])
        self.image.blit(text_surface, (padding, padding))
        self.rect = self.image.get_frect(midtop = pos)
    
    # Update function to kill sprite if we switch Aminomons or one dies in battle.
    def update(self, _):
        if not self.monster_sprite.groups():
            self.kill()

#
# This is the class for the battle Aminomon Level sprites; it inherits the Sprite class as a parent. This class is for
#   the level of the Aminomon that gets displayed in battle.
#
class AminomonLevel(pygame.sprite.Sprite):
    def __init__(self, entity, pos, monster_sprite, groups, font):
        super().__init__(groups)
        self.monster_sprite = monster_sprite
        self.font = font
        self.z = BATTLEGRAPHICSLAYERS['name']

        self.image = pygame.Surface((90,28))
        self.rect = self.image.get_frect(topright = pos) #if entity  == 'player' else self.image.get_frect(topright = pos)
        self.xp_rect = pygame.FRect(0, self.rect.height -2, self.rect.width, 2)

    # Update function that will display the current XP, this will visually update when your Aminomon defeats another in battle.
    def update(self, _):
        self.image.fill(COLORS['white'])

        text_surface = self.font.render(f'Level {self.monster_sprite.monster.level}', False, COLORS['black'])
        text_rect = text_surface.get_frect(center = (self.rect.width / 2, self.rect.height / 2))
        self.image.blit(text_surface, text_rect)

        draw_bars(self.image, self.xp_rect, self.monster_sprite.monster.xp, self.monster_sprite.monster.level_up, COLORS['black'], COLORS['white'], 0)
       
        if not self.monster_sprite.groups():
            self.kill()

#
# This is the class for the Aminomon Stat sprites; it inherits the Sprite class as a parent. This class is for
#   the Health, Energy, and initiative for the monster.
#
class AminomonStats(pygame.sprite.Sprite):
    def __init__(self, pos, monster_sprite, size, groups, font):
        super().__init__(groups)
        self.monster_sprite = monster_sprite
        self.image = pygame.Surface(size)
        self.rect = self.image.get_frect(midbottom = pos)
        self.font = font
        self.z = BATTLEGRAPHICSLAYERS['overlay']

    # This update function changes the displayed health, energy, and initiative bars
    def update(self, _):
        self.image.fill(COLORS['white'])

        for index, (value, max_value) in enumerate(self.monster_sprite.monster.get_info()):
            color = (COLORS['green'], COLORS['yellow'], COLORS['gray'])[index]
            if index < 2:
                text_surf = self.font.render(f'{int(value)}/{max_value}', False, COLORS['black'])
                text_rect = text_surf.get_frect(topleft = (self.rect.width * 0.05,index * self.rect.height / 2))
                bar_rect = pygame.FRect(text_rect.bottomleft + vector(0,-2), (self.rect.width * 0.9, 4))

                self.image.blit(text_surf, text_rect)
                draw_bars(self.image, bar_rect, value, max_value, color, COLORS['black'], 2)

            else:
                init_rect = pygame.FRect((0, self.rect.height - 2), (self.rect.width, 2))
                draw_bars(self.image, init_rect, value, max_value, color, COLORS['white'], 0)

        if not self.monster_sprite.groups():
            self.kill()

#
# This is the class for battle Attack sprites; it inherits the Sprite class as a parent. This class is for
#   animating the attacks during battle.
#
class AnimatedAttack(SpriteAnimation):
    def __init__(self, pos, frames, groups):
        super().__init__(pos, frames, groups, BATTLEGRAPHICSLAYERS['overlay'])
        self.rect.center = pos

    def animate(self, dt):
        self.frame_index += ANISPEED * dt
        if self.frame_index < len(self.frames):
            self.image = self.frames[int(self.frame_index)]
        else:
            self.kill()
    
    def update(self, dt):
        self.animate(dt)

#
# This is the class for battle Timed sprites; it inherits the Sprite class as a parent. This class is for
#   a cross symbol during battle when the opponent Aminomon is not catchable.
#
class TempSprite(Sprite):
    def __init__(self, pos, surface, groups, duration):
        super().__init__(pos, surface, groups, z = BATTLEGRAPHICSLAYERS['overlay'])
        self.rect.center = pos
        self.death_timer = Timer(duration, autostart = True, func = self.kill)

    def update(self, _):
        self.death_timer.update()
