#######################################################################################################################
# GameObjects.py
# This file contains the Game Object class and child classes NPC and Player. This file sets up the Player Character
#   and the Non-Player Characters in the overworld.
#
######################################################################################################################
from random import choice
from TimerForTimingThings import Timer
from SettingsAndSupport import *
from AminoMons import Aminomons

#
# This is the game object class. It inherits from the pygaeme Sprite class.
#
class GameObject(pygame.sprite.Sprite):
    def __init__ (self, pos, frames, groups, facing_direction):
        super().__init__(groups)
        self.z = LAYERS['main']
        self.frame_index, self.frames = 0, frames
        self.facing_direction = facing_direction
        self.direction = vector()
        self.speed = 250
        self.blocked = False
        self.image = self.frames[self.get_animation_state()][self.frame_index]
        self.rect = self.image.get_frect(center = pos)
        self.hitbox = self.rect.inflate(-self.rect.width /2, -60)
        self.y_sort = self.rect.centery

    # Animates the Game Object
    def animate(self, dt):
        self.frame_index += ANISPEED * dt
        self.image = self.frames[self.get_animation_state()][int(self.frame_index % len(self.frames[self.get_animation_state()]))]

    # If the Game Object is moving it will show different animation frames depending on which direction the player is looking.
    #   If the Object is not moving, it will set an idle state frame.
    def get_animation_state(self):
        moving = bool(self.direction)
        if moving:
            if self.direction.x != 0:
                self.facing_direction = "right" if self.direction.x > 0 else "left"
            if self.direction.y != 0:
                self.facing_direction = "down" if self.direction.y > 0 else "up"
        return f"{self.facing_direction}{'' if moving else '_idle'}"
        
    def block(self):
        self.blocked = True
        self.direction = vector(0,0)

    def unblock(self):
        self.blocked = False


#
# This is the NPC class, it inherits from the GameObject class. It will save variables from the trainer info in the
#   BigBigData folder. 
#
class NPC(GameObject):
    def __init__(self, pos, frames, groups, facing_direction, character_data, player, start_dialog, collision_sprites, radius, healer, fuser, unfuser, storagePC):
        super().__init__(pos, frames, groups, facing_direction)

        #
        # Sets all the character inforamtion from the dictionary in the BigBigData file.
        #
        self.character_data = character_data.copy()
        self.player = player
        self.start_dialog = start_dialog
        self.collision_rect = [sprite.rect for sprite in collision_sprites if sprite is not self]
        self.healer = healer
        self.monsters = {i: Aminomons(name, lvl, 0) for i, (name, lvl) in character_data['monsters'].items()} if 'monsters' in character_data else None
        self.fuser = fuser
        self.unfuser = unfuser
        self.storagePC = storagePC
        self.radius = int(radius)
        self.view_directions = character_data['directions']
        self.character_data['defeated'] = False

    # Returns the dialog of the NPC depending on if they lost a battle or if they are interacting with the Player
    def charDialog(self):
        return self.character_data['dialog'][f"{'defeated' if self.character_data['defeated'] else 'default'}"]
    



#
# This is for the player class which inhereits the GameObject parent. This is the Player
#   character for the game. It handels movement, blocks overlaps of NPCs, and takes in user
#   inputs. 
#
class Player(GameObject):
    def __init__(self, pos, frames, groups, facing_direction, collision_sprites):
        super().__init__(pos, frames, groups, facing_direction)
        self.collision_sprites = collision_sprites
        self.noticed = False

    #
    # Handles the user input for the Player
    #
    def input(self):
        keys = pygame.key.get_pressed()
        input_vector = vector()
        if not self.blocked:
            if keys[pygame.K_UP]:
                input_vector.y -= 1
            if keys[pygame.K_DOWN]:
                input_vector.y += 1
            if keys[pygame.K_LEFT]:
                input_vector.x -= 1
            if keys[pygame.K_RIGHT]:
                input_vector.x += 1

        self.direction = input_vector.normalize() if input_vector else input_vector

    # Moves the player character
    def move(self, dt):
        self.rect.centerx += self.direction.x * self.speed * dt
        self.hitbox.centerx = self.rect.centerx
        self.player_collisions('horizontal')

        self.rect.centery += self.direction.y * self.speed * dt
        self.hitbox.centery = self.rect.centery
        self.player_collisions('vertical')

    #
    # Check the player sprite to see if it is colliding with another sprite and positions them so the
    #   player will not overlap with the NPCs.
    #
    def player_collisions(self, axis):
        for sprite in self.collision_sprites:
            if sprite.hitbox.colliderect(self.hitbox):
                if axis == 'horizontal':
                    if self.direction.x > 0:
                        self.hitbox.right = sprite.hitbox.left
                    if self.direction.x < 0:
                        self.hitbox.left = sprite.hitbox.right
                    self.rect.centerx = self.hitbox.centerx
                else:
                    if self.direction.y > 0:
                        self.hitbox.bottom = sprite.hitbox.top
                    if self.direction.y < 0:
                        self.hitbox.top = sprite.hitbox.bottom
                    self.rect.centery = self.hitbox.centery
    
    #
    # Update for the plaer class. 
    #
    def update(self, dt):
        self.y_sort = self.rect.centery
        if not self.blocked:
            self.input()
            self.move(dt)
        self.animate(dt)

