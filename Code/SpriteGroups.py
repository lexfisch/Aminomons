######################################################################################################################
# SpriteGrous.py
# This file contains the information for the different groups we will assign our sprites into. We have two classes:
#   WorldSprites and SpritesForFights that handle drawing and updating sprites in the world and the battle scenes, respectively
#
######################################################################################################################

from SettingsAndSupport import *
from GameObjects import GameObject



#
# This defines the class WorldSprites. We inherit the parent class of Groups
#   from pygame.sprite. Instead of handling and manipulating Sprites directly,  
#   we assign the sprite to a group that handles the drawing updates to the world.
#
class WorldSprites(pygame.sprite.Group):
    def __init__(self):
        super().__init__()
        self.display_surface = pygame.display.get_surface()
        self.offset = vector()
        self.notice_surf = importImage("images", "ui", "notice")


    def draw(self, player):
        self.offset.x = -(player.rect.centerx - WIN_WIDTH / 2)
        self.offset.y = -(player.rect.centery - WIN_HEIGHT / 2)

        bg_sprites = [sprite for sprite in self if sprite.z < LAYERS["main"]]
        main_sprites = sorted([sprite for sprite in self if sprite.z == LAYERS["main"]], key = lambda sprite: sprite.y_sort)
        fg_sprites = [sprite for sprite in self if sprite.z > LAYERS["main"]]

        for layer in (bg_sprites, main_sprites, fg_sprites):
            for sprite in layer:
                self.display_surface.blit(sprite.image, sprite.rect.topleft + self.offset)
                if sprite == player and player.noticed:
                    rect = self.notice_surf.get_frect(midbottom = sprite.rect.midtop)
                    self.display_surface.blit(self.notice_surf, rect.topleft + self.offset)


#
# This is the class SpritesForFights. We inherit the parent class of Groups
#   from pygame.sprite. We use this group to hold the sprites that will be used in
#   a battle. The sprites do not get manipulated themselves, we use the assigned group
#   to handle drawing and updates.
#
class SpritesForFights(pygame.sprite.Group):
    def __init__(self):
        super().__init__()
        self.display_surface = pygame.display.get_surface()

    def draw (self, current_monster_sprite, side, mode, target_index, player_sprites, opponent_sprites):
        #
        # This will assign the sprites based on if they belong to the player or opponent
        #
        sprite_group = opponent_sprites if side == 'opponent' else player_sprites
        sprites = {sprite.pos_index: sprite for sprite in sprite_group}
        monster_sprite = sprites[list(sprites.keys())[target_index]] if sprites else None

        #
        # This handles how we Outline sprites during battle
        #
        for sprite in sorted(self, key = lambda sprite: sprite.z):
            if sprite.z == BATTLEGRAPHICSLAYERS['outline']:
                if sprite.monster_sprite == current_monster_sprite and not (mode == 'target' and side == 'player') or \
				   sprite.monster_sprite == monster_sprite and sprite.monster_sprite.entity == side and mode and mode == 'target':
                    self.display_surface.blit(sprite.image, sprite.rect)
            else:
                self.display_surface.blit(sprite.image, sprite.rect)