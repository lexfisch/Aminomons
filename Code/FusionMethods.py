#######################################################################################################################
# Fusion.py
# This file is for the Fusion and Unfusion class. This handles Animation from one Aminomon to another, but does not
#   handle the logic that the game uses for Fusion Checks.
#
######################################################################################################################

from TimerForTimingThings import *
from SettingsAndSupport import *

#
# This is the Fusion class. When talking to the fuser, if an Aminomon is above the level
#   threshold, this will replace the Aminoacid with its x2 or x3 oligo. This handles the 
#   animation that appears and will display the message when finished.
#
class Fusion:
    def __init__(self, frames, start_monster, end_monster, font, end_fusion, star_frames):
        # Loads in the Aminomons for the start and end of the fusion.
        self.display_surface = pygame.display.get_surface()
        self.start_monster_surf = pygame.transform.scale2x(frames[start_monster]['idle'][0])
        self.end_monster_surf = pygame.transform.scale2x(frames[end_monster]['idle'][0])
        self.timers = {
            'start': Timer(800, autostart = True),
            'end': Timer(1000, func = end_fusion)
        }
        
        # Saves the star animation frames
        self.star_frames = [pygame.transform.scale2x(frame) for frame in star_frames]
        self.frame_index = 0

        self.tint_surf = pygame.Surface(self.display_surface.get_size())
        self.tint_surf.set_alpha(200)

        self.start_monster_surf_white = pygame.mask.from_surface(self.start_monster_surf).to_surface()
        self.start_monster_surf_white.set_colorkey('black')
        self.tint_amount = 0
        self.tint_speed = 80
        self.start_monster_surf_white.set_alpha(self.tint_amount)

        self.start_text_surf = font.render(f'{start_monster} is fusing', False, COLORS['black'])
        self.end_text_surf = font.render(f'{start_monster} fused into {end_monster}', False, COLORS['black'])

    #
    # Starts the star animation sequence 
    #
    def star_animation(self, dt):
        self.frame_index += 20 *dt
        if self.frame_index < len(self.star_frames):
            frame = self.star_frames[int(self.frame_index)]
            rect = frame.get_frect(center = (WIN_WIDTH/2, WIN_HEIGHT/2))
            self.display_surface.blit(frame, rect)

    #
    # Update method for the fusion class
    #
    def update(self, dt):
        for timer in self.timers.values():
            timer.update()

        if not self.timers['start'].active:
            self.display_surface.blit(self.tint_surf, (0,0))
            
            if self.tint_amount < 255:
                rect = self.start_monster_surf.get_frect(center = (WIN_WIDTH/2, WIN_HEIGHT/2))
                self.display_surface.blit(self.start_monster_surf, rect)
                    
                self.tint_amount += self.tint_speed *dt
                self.start_monster_surf_white.set_alpha(self.tint_amount)
                self.display_surface.blit(self.start_monster_surf_white, rect)

                text_rect = self.start_text_surf.get_frect(midtop = rect.midbottom + vector(0,20))
                pygame.draw.rect(self.display_surface, COLORS['white'], text_rect.inflate(20,20),0,5)
                self.display_surface.blit(self.start_text_surf, text_rect)

            else:
                rect = self.end_monster_surf.get_frect(center = (WIN_WIDTH/2, WIN_HEIGHT/2))
                self.display_surface.blit(self.end_monster_surf, rect)

                text_rect = self.end_text_surf.get_frect(midtop = rect.midbottom + vector(0,20))
                pygame.draw.rect(self.display_surface, COLORS['white'], text_rect.inflate(20,20),0,5)
                self.display_surface.blit(self.end_text_surf, text_rect)
                self.star_animation(dt)

                if not self.timers['end'].active:
                    self.timers['end'].turnOn()



#
# This is the Unfusing class. When talking to the Unfuser, if an Aminomon is the x2 or x3 oligo, 
#   it will reduce to its original Aminomon. This handles the animation that appears and will 
#   display the message when finished.
#
class Unfusing:
    def __init__(self, frames, start_monster, end_monster, font, end_unfusion, star_frames):
        # Loads in the Aminomons for the start and end of the unfusion.
        self.display_surface = pygame.display.get_surface()
        self.start_monster_surf = pygame.transform.scale2x(frames[start_monster]['idle'][0])
        self.end_monster_surf = pygame.transform.scale2x(frames[end_monster]['idle'][0])
        self.timers = {
            'start': Timer(800, autostart = True),
            'end': Timer(1000, func = end_unfusion)
        }

        # Saves the star frames and sets index to zero
        self.star_frames = [pygame.transform.scale2x(frame) for frame in star_frames]
        self.frame_index = 0

        self.tint_surf = pygame.Surface(self.display_surface.get_size())
        self.tint_surf.set_alpha(200)

        self.start_monster_surf_white = pygame.mask.from_surface(self.start_monster_surf).to_surface()
        self.start_monster_surf_white.set_colorkey('black')
        self.tint_amount = 0
        self.tint_speed = 80
        self.start_monster_surf_white.set_alpha(self.tint_amount)

        self.start_text_surf = font.render(f'{start_monster} is unfusing!', False, COLORS['black'])
        self.end_text_surf = font.render(f'{start_monster} unfused into {end_monster}', False, COLORS['black'])

    #
    # Starts the star animation sequence 
    #
    def star_animation(self, dt):
        self.frame_index += 20 *dt
        if self.frame_index < len(self.star_frames):
            frame = self.star_frames[int(self.frame_index)]
            rect = frame.get_frect(center = (WIN_WIDTH/2, WIN_HEIGHT/2))
            self.display_surface.blit(frame, rect)

    #
    # Update method for the fusion class
    #
    def update(self, dt):
        for timer in self.timers.values():
            timer.update()

        if not self.timers['start'].active:
            self.display_surface.blit(self.tint_surf, (0,0))
            
            if self.tint_amount < 255:
                rect = self.start_monster_surf.get_frect(center = (WIN_WIDTH/2, WIN_HEIGHT/2))
                self.display_surface.blit(self.start_monster_surf, rect)
                    
                self.tint_amount += self.tint_speed *dt
                self.start_monster_surf_white.set_alpha(self.tint_amount)
                self.display_surface.blit(self.start_monster_surf_white, rect)

                text_rect = self.start_text_surf.get_frect(midtop = rect.midbottom + vector(0,20))
                pygame.draw.rect(self.display_surface, COLORS['white'], text_rect.inflate(20,20),0,5)
                self.display_surface.blit(self.start_text_surf, text_rect)

            else:
                rect = self.end_monster_surf.get_frect(center = (WIN_WIDTH/2, WIN_HEIGHT/2))
                self.display_surface.blit(self.end_monster_surf, rect)

                text_rect = self.end_text_surf.get_frect(midtop = rect.midbottom + vector(0,20))
                pygame.draw.rect(self.display_surface, COLORS['white'], text_rect.inflate(20,20),0,5)
                self.display_surface.blit(self.end_text_surf, text_rect)
                self.star_animation(dt)

                if not self.timers['end'].active:
                    self.timers['end'].turnOn()