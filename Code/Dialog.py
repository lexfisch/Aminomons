#######################################################################################################################
# Dialog.py
# This file is for the DialogSel class and the associated sprites. This handles the dialog option when talking with 
#   non-player characters. 
#
######################################################################################################################

from SettingsAndSupport import *
from TimerForTimingThings import Timer

#
# This is for the Dialog class. This handles user input and timers for the dialog.
#
class DialogSel:
    def __init__(self, character, player, all_sprites, font, stop_dialog):
        self.player = player
        self.character = character
        self.all_sprites = all_sprites
        self.font = font
        self.stop_dialog = stop_dialog
        self.dialog = character.charDialog()
        self.dialog_num = len(self.dialog)
        self.dialog_index = 0
        self.currentDialog = DialogSprite(self.dialog[self.dialog_index], self.character, self.all_sprites, self.font)
        self.dialogTimer = Timer(500, autostart = True)

    #
    # Handles user input during the dialog selection
    #
    def input(self):
        keys = pygame.key.get_just_pressed()
        if keys[pygame.K_SPACE] and not self.dialogTimer.active:
            self.currentDialog.kill()
            self.dialog_index += 1
            if self.dialog_index < self.dialog_num:
                self.currentDialog = DialogSprite(self.dialog[self.dialog_index], self.character, self.all_sprites, self.font)
                self.dialogTimer.turnOn()
            else:
                self.stop_dialog(self.character)

    #
    # Update method on the dialog selection
    #
    def update(self):
        self.dialogTimer.update()
        self.input()


#
# Creates a sprite for the dialog to be displayed. This inherits from the pygame Sprite class.
#
class DialogSprite(pygame.sprite.Sprite):
    def __init__(self, message, character, groups, font):
        super().__init__(groups)
        self.z = LAYERS['top']
    
        # This is what will actually be displayed.
        textSurf = font.render(message, False, COLORS['black'])
        padding = 5
        width = max(30, textSurf.get_width() + padding*2)
        height = textSurf.get_height() + padding*2

        # This sets up a "window" behind the message that is displayed. 
        bgSurf = pygame.Surface((width, height), pygame.SRCALPHA)
        bgSurf.fill((0,0,0,0))
        pygame.draw.rect(bgSurf, COLORS['pure white'], bgSurf.get_frect(topleft = (0,0)),0,4)
        bgSurf.blit(textSurf, textSurf.get_frect(center = (width/2, height/2)))
        self.image = bgSurf
        self.rect = self.image.get_frect(midbottom = character.rect.midtop + vector(0, -10))