#######################################################################################################################
# AminoIndex.py
# This will be an index of all the Aminomons currently in the team. We will be able to iterate through the current team 
#   of Aminomons and it will display information on the selected Aminomon on the center panel.   
#
######################################################################################################################

from BigBigData import *
from SettingsAndSupport import *

#
# This is the Aminomon Index class. It will show the
#
class AminoIndex:
    def __init__ (self, monsters, fonts, monster_frames):
        self.display_surface = pygame.display.get_surface()
        self.fonts = fonts
        self.monsters = monsters
        self.frame_index = 0

        # Setting up the frames list we will use. We will need three, the first for the Aminomon Icon, 
        #   the second for all the Aminomon Animations, and the third is for the Stats Images.
        self.icon_frames = monster_frames['icons']
        self.monster_frames = monster_frames['monsters']
        self.ui_frames = monster_frames['ui']

        # This is for our tint surface
        self.tint_surf = pygame.Surface((WIN_WIDTH, WIN_HEIGHT))
        self.tint_surf.set_alpha(200)

        # This will set the overall dimensions of the AminoIndex
        self.main_rect = pygame.FRect(0,0, WIN_WIDTH * 0.6, WIN_HEIGHT *0.8).move_to(center = (WIN_WIDTH/2, WIN_HEIGHT/2))

        # Lists for the number of Aminomons to display, the width of the list, the height of each Aminomon Entry,
        #   a index for which Aminomon is currently selected, and the Indexed Aminomon if selected
        self.visible_items = 6
        self.list_width = self.main_rect.width * 0.3
        self.item_height = self.main_rect.height / self.visible_items
        self.index = 0
        self.selected_index = None

        # This sets up a dictionary for us to store the Max Value in each of the stats. It will iterate through all
        #   the Aminomons in the peptide Index and store the largest for each of the values listed under stats, igoring
        #   the entry for the Element type. While scrolling we can use tis compare the base stats of all 
        #   Aminomons in the party relative to the highest base stat in the game. 
        self.max_stats = {}
        for data in peptideDex.values():
            for stat, value in data['stats'].items():
                if stat != 'element':
                    if stat not in self.max_stats:
                        self.max_stats[stat] = value
                    
                    else:
                        self.max_stats[stat] = value if value > self.max_stats[stat] else self.max_stats[stat]

        # This will remove the Max Health and Max Energy from the lists. We will not use these in the stat display.        
        self.max_stats['health'] = self.max_stats.pop('MAX_HEALTH')
        self.max_stats['energy'] = self.max_stats.pop('MAX_ENERGY')

    #
    # This is how we will navigate the Aminomon Index. We can move through the list and
    #   select entries to move.
    #
    def input(self):
        keys = pygame.key.get_just_pressed()
        if keys[pygame.K_UP]:
            if self.index == 0:
                self.index = len(self.monsters)
            else:
                self.index -= 1
        if keys[pygame.K_DOWN]:
            if self.index == len(self.monsters):
                self.index = 0
            else:
                self.index += 1
        if keys[pygame.K_RETURN]:
            pass
        if keys[pygame.K_ESCAPE]:
            pass

        self.index = self.index % len(self.monsters)

    #
    # This is the bulk of the Aminomon Index. We will display the animated Aminomon alonside it's name,
    #   level, Experience Bar, and its type. The background color will switch relative to the element of the  
    #   entry. Below that it will have the current Health and Energy. Last, it will show the stats, relative to the
    #   max base stat in the game, and any ability that the Aminomon has unlocked.
    #  
    def display_aminoindex(self, dt):
        # We load in a list of data for the selected entry.
        monster = self.monsters[self.index]

        # This will set up a rect on the right side of the Aminomon Index for us to work within. 
        rect = self.main_rect.copy()
        pygame.draw.rect(self.display_surface, COLORS['dark'], rect, 0, 12, 0, 12, 0)

        # This will set up the rect for the top section. This will be used for the animation display, 
        #   along with name, level, experierence bar, and element.
        top_rect = pygame.FRect(rect.topleft, (rect.width, rect.height * 0.4))
        pygame.draw.rect(self.display_surface, COLORS[monster.element], top_rect, 0, 0, 0, 12)

        # This will store and display the animation frames. We set up the surface and rect for the animation frames, it will
        #   frames, it will cycle through them at the animation speed.
        self.frame_index += ANISPEED * dt
        monster_surf = self.monster_frames[monster.name]['idle'][int(self.frame_index) % len(self.monster_frames[monster.name]['idle'])]
        monster_rect = monster_surf.get_frect(center = top_rect.center)
        self.display_surface.blit(monster_surf, monster_rect)

        # This will store and display the name of the Aminomon entry.
        name_surf = self.fonts['bold'].render(monster.name, False, COLORS['black'])
        name_rect = name_surf.get_frect(topleft = top_rect.topleft + vector(10,10))
        self.display_surface.blit(name_surf, name_rect)

        # This will store and display the level of the Aminomon entry.
        level_surf = self.fonts['regular'].render(f'Lvl: {monster.level}', False, COLORS['black'])
        level_rect = level_surf.get_frect(bottomleft = top_rect.bottomleft + vector(10,-16))
        self.display_surface.blit(level_surf, level_rect)
        
        # This will call our draw bar function. We will use this for the exerpeience bar. We use the value for current experience
        #   and the experience needed to level up.
        draw_bars(
            surface = self.display_surface,
            rect = pygame.FRect(level_rect.bottomleft, (100, 4)), 
            value = monster.xp,
            max_value = monster.level_up,
            color = COLORS['dark'],
            bgColor = COLORS['white']
            )

        # This will store and display the element of the Aminomon entry.
        element_surf = self.fonts['regular'].render(monster.element, False, COLORS['black'])
        element_rect = element_surf.get_frect(bottomright = top_rect.bottomright + vector(-10,-20))
        self.display_surface.blit(element_surf, element_rect)

        # This is a dictionary containing the coordinate information for our Health and Energy bars. 
        bar_data = {
            'width': rect.width * 0.45,
            'height': 30, 
            'top': top_rect.bottom + rect.width * 0.03,
            'left_side': rect.left + rect.width /4,
            'right_side': rect.left + rect.width * 3/4
        }

        # This is the health bar specific set up. We create the rect for the Healthbar and then call draw bar using the healthbar rect.
        #   We then make the Health Text and the Rect for Health Text. Then we blit them.
        healthbar_rect = pygame.FRect((0,0), (bar_data['width'],bar_data['height'])).move_to(midtop = (bar_data['left_side'], bar_data['top']))
        draw_bars(self.display_surface, healthbar_rect, monster.health, monster.get_single_stat('MAX_HEALTH'), COLORS['green'], COLORS['black'], 2)
        hp_text = self.fonts['regular'].render(f"HP: {int(monster.health)}/{int(monster.get_single_stat('MAX_HEALTH'))}", False, COLORS['black'])
        hp_rect = hp_text.get_frect(midleft = healthbar_rect.midleft + vector(10,0))
        self.display_surface.blit(hp_text, hp_rect)
            
        # This is the energy bar specific set up. We create the rect for the Energybar and then call draw bar using the energybar rect.
        #   We then make the Energy Text and the Rect for Energy Text. Then we blit them.
        energybar_rect = pygame.FRect((0,0), (bar_data['width'],bar_data['height'])).move_to(midtop = (bar_data['right_side'], bar_data['top']))
        draw_bars(self.display_surface, energybar_rect, monster.energy, monster.get_single_stat('MAX_ENERGY'), COLORS['yellow'], COLORS['black'], 2)
        ep_text = self.fonts['regular'].render(f"EP: {int(monster.energy)}/{int(monster.get_single_stat('MAX_ENERGY'))}", False, COLORS['black'])
        ep_rect = ep_text.get_frect(midleft = energybar_rect.midleft + vector(10,0))
        self.display_surface.blit(ep_text, ep_rect)

        # This sets up the sides and height data for our stats subsection window.
        sides = {'left': healthbar_rect.left, 'right': energybar_rect.left}
        info_height = rect.bottom - healthbar_rect.bottom

        # This will set up the rect to contain our stats subsection. We will also create the text surface
        #   and rect to display the subsection heading.
        stats_rect = pygame.FRect(sides['left'], healthbar_rect.bottom, healthbar_rect.width, info_height).inflate(0,-60).move(0,15)
        stats_text_surf = self.fonts['regular'].render('Stats', False, COLORS['white'])
        stats_text_rect = stats_text_surf.get_frect(bottomleft = stats_rect.topleft)
        self.display_surface.blit(stats_text_surf, stats_text_rect)

        # This stores the stats for each of the entry and sets a height based on the number of stats.
        monster_stats = monster.get_all_stats()
        stat_height = stats_rect.height / len(monster_stats)

        # For loop that will pull each the stats and value for the indexed entry. For each, it will set up the rect for a single stat.
        #   We create an icon surface and associated rect for the icon representing the stat. We then make the surface and rect for
        #   the text; this will be the name of the stat. Last, we will draw the stat bar, it will show the monster base stats relative to 
        #   the max value of that base stat across all Aminomons. 
        for index, (stat, value) in enumerate(monster_stats.items()):
            # This is rect that will contain that stat. It will use the index to move the rect down each time through the for loop.
            #   This will happen for each stat.
            single_stat_rect = pygame.FRect(stats_rect.left, stats_rect.top + index * stat_height, stats_rect.width, stat_height)

            # This is the surface and rect for each of the icons.
            icon_surf = self.ui_frames[stat]
            icon_rect = icon_surf.get_frect(midleft = single_stat_rect.midleft + vector(5,0))
            self.display_surface.blit(icon_surf, icon_rect)

            # This is the surface and rect for the text, it will use the iterated stat as the enerted text.
            text_surf = self.fonts['regular'].render(stat, False, COLORS['white'])
            text_rect = text_surf.get_frect(topleft = icon_rect.topleft + vector(30,-10))
            self.display_surface.blit(text_surf, text_rect)

            # This will create a rect for the iterated stat. We will then call the draw bar function using the max base stat value 
            #   and individual Aminomons base stat.
            bar_rect = pygame.FRect((text_rect.left, text_rect.bottom + 2), (single_stat_rect.width  - (text_rect.left - single_stat_rect.left),4))
            draw_bars(self.display_surface, bar_rect, value, self.max_stats[stat] * monster.level, COLORS['white'], COLORS['black'])

        # This sets up the rect that will contain the ability subsection of the Aminomon Index. This also creates the rect and surface
        #   for the Ability Subsection Heading.
        ability_rect = stats_rect.copy().move_to(left = sides['right'])
        ability_text_surf = self.fonts['regular'].render("Ability", False, COLORS['white'])
        ability_text_rect = ability_text_surf.get_frect(bottomleft = ability_rect.topleft)
        self.display_surface.blit(ability_text_surf, ability_text_rect)

        # This will iterate through the abilities for the indexed Aminomon. It will create a surface for the name of each ability and use the element
        #   of the indexed Aminomon to color the surface. We will use two columns to list the abilities in. We use 'mod 2' to distinguish which column
        #   to slot the ability. We then make a rect for the ability surface.
        for ind, ability in enumerate(monster.get_skills()):
            element = SKILLS_DATA[ability]['element']

            text_surf = self.fonts['regular'].render(ability, False, COLORS['black'])
            x = ability_rect.left + ind % 2 * ability_rect.width /2
            y = 20 + ability_rect.top + int(ind /2) * (text_rect.height + 20)
            rect = text_surf.get_frect(topleft = (x,y))
            pygame.draw.rect(self.display_surface, COLORS[element], rect.inflate(10,10), 0, 4)
            self.display_surface.blit(text_surf, rect)
            
    #
    # This is the Aminomon Index update function. It checks for input and then calls our display functions.
    #
    def update(self, dt):
        self.input()
        self.display_surface.blit(self.tint_surf, (0,0))
        self.display_aminoindex(dt)
                

