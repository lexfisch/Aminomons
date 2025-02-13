#######################################################################################################################
# SettingsAndSupport.py
# This file contains general variables that we will use throughout our game. This file also includes import methods for
#   the game sprites and maps. It also contains general methods at the bottom for drawing bars, checking proximity, and
#   for the save/load function.
######################################################################################################################
import pygame
from pygame.math import Vector2 as vector 
from sys import exit
from os.path import join
from os import walk
from pytmx.util_pygame import load_pygame
import csv


#
# Static Variables for the window size, the tile size of the maps, the animation speed, and the width of the battle window.
#
WIN_WIDTH, WIN_HEIGHT = 1280, 720
TILESIZE = 64 
ANISPEED = 6
BATTLEWINDOW_WIDTH = 4

#
# These are set values to establish where the Aminomons will be placed within the battle overlay. We also have the layers
#   for the Battle Overlay graphics. Also, all choices available for battle with the associated icons.
#
PositionsInBattle = {
    'player': {'top': (900, 550)},
	'opp': {'top': (360, 260)}
}

BATTLEGRAPHICSLAYERS = {
    'outline': 0,
	'monster': 1,
	'name': 2,
	'effects': 3,
	'overlay': 4
}

ChoicesForBattle = {
        'fight':  {'pos' : vector(-40, -20), 'icon': 'sword'},
		'switch': {'pos' : vector(-40, 20), 'icon': 'arrows'},
		'catch':  {'pos' : vector(-30, 60), 'icon': 'hand'}
}

#
# The disctionary for colors that we use within the game
#
COLORS = {
    "white": "#f4fefa", 
	"pure white": "#ffffff",
	"dark": "#2b292c",
	"light": "#c8c8c8",
	"gray": "#3a373b",
	"gold": "#ffd700",
	"light-gray": "#4b484d",
	"fire":"#f8a060",
	"water":"#50b0d8",
	"earth": "#64a990", 
    "electric": "#ffff00",
	"black": "#000000", 
	"red": "#f03131",
	"blue": "#66d7ee",
	"normal": "#ffffff",
	"dark white": "#f0f0f0",
    "yellow": "#ffff00",
    "green": "#00ff00",
    'salmon': "#fa8072"
}

#
# World layers to properly set the surface layers within the main world. 
#
LAYERS = {
    "basement": 0,
    "bg": 1,
    "shadow": 2,
    "main": 3,
    "top": 4
}

#######################################################################################################################
#
# Importers for ease of access using folder navigation. We can use these to move through our file structure 
#   to load in specfiic images or tileset files.    
#

#
# This importer takes a path and format of the image (PNG). It will return the image at the file path location
#   as a surface variable. 
#
def importImage(*path, alpha = True, format = 'png'):
    full_path = join(*path) + f'.{format}'
    surf = pygame.image.load(full_path).convert_alpha() if alpha else pygame.image.load(full_path).convert()
    return surf

#
# This is folder importer, it takes the folder path and loops through the subfolder. This is used primarly
#   for the star animation.
#
def importFolder(*path):
    frames = []
    for folder_path, sub_folders, image_names in walk(join(*path)):
        for image_name in sorted(image_names, key = lambda name: int(name.split('.')[0])):
            full_path = join(folder_path, image_name)
            surf = pygame.image.load(full_path).convert_alpha()
            frames.append(surf)
    return frames

#
# This is a folder dictionary importer, it splits the image before the file type. It will return frames
#   containing the images in the subfolder.
#
def importFolderDict(*path):
    frames = {}
    for folder_path, sub_folders, image_names in walk(join(*path)):
        for image_name in image_names:
            full_path = join(folder_path, image_name)
            surf = pygame.image.load(full_path).convert_alpha()
            frames[image_name.split('.')[0]] = surf
    return frames

#
# Will loop through the SubFolders and call the folder import on that subfolder. It will return a 
#   variable called frames, containing the images in the subfolder.
# 
def importSubfolder(*path):
    frames = {}
    for _, sub_folders, __ in walk(join(*path)):
        if sub_folders:
            for sub_folder in sub_folders:
                frames[sub_folder] = importFolder(*path, sub_folder)
    return frames 

#
# This is a importer that gets called from Char Import. This is used to cut out the sprite sheets
#   and return them as a series of frames.
#
def importTilemap(cols, rows, *path):
    frames = {}
    surf = importImage(*path)
    cell_width, cell_height = surf.get_width()/cols, surf.get_height()/rows
    for col in range(cols):
        for row in range(rows):
            cutout_rect = pygame.Rect(col * cell_width, row * cell_height, cell_width, cell_height)
            cutout_surf = pygame.Surface((cell_width, cell_height))
            cutout_surf.fill('green')
            cutout_surf.set_colorkey('green')
            cutout_surf.blit(surf, (0,0), cutout_rect)
            frames[(col, row)] = cutout_surf
    return frames

#
# This is used for Character and Players, it assigns them a facing direction. Then if its the first column
#   within ehe sprite sheet, assigns that image as the "Idle" state.
#
def charImporter(cols, rows, *path):
    frame_dict = importTilemap(cols, rows, *path)
    new_dict = {}
    for row, direction in enumerate(("down", "left", "right", "up")):
        new_dict[direction] = [frame_dict[(col, row)] for col in range(cols)]
        new_dict[f'{direction}_idle'] = [frame_dict[(0, row)]]
    return new_dict

#
# This is a function called from the setup of the overworld frames, it will call a subfunction
#   charImporter. This is where we set the column and rows for the sprite sheet. It returns
#   a dictionary of character frames.
#
def allCharImporter(*path):
    charDict ={}
    for _, __, image_names in walk(join(*path)):
        for image in image_names:
            image_name = image.split(".")[0]
            charDict[image_name] = charImporter(4,4, *path, image_name)
    return charDict

#
# This is a function that is called when loading a TMX map file.
#   it returns a tmx map.
#
def importTMX(*path):
    tmxDict ={}
    for folder_path, sub_folder, file_names in walk(join(*path)):
        for file in file_names:
            tmxDict[file.split(".")[0]] = load_pygame(join(folder_path, file))
    return tmxDict

#
# This is a function to import the Aminomon sprite sheet. It loads in a 4x2 sprite sheet
#   it uses the first row as a series of "idle" animations and the second row as the "attcack"
#   animation frames.
#
def importMonster(cols, rows, *path):
    monster_dict = {}
    for folder_path, sub_folder, image_names in walk(join(*path)):
        for image in image_names:
            image_name = image.split('.')[0]
            monster_dict[image_name] = {}
            frame_dict = importTilemap(cols, rows, *path, image_name)
            for row, key in enumerate(("idle", "attack")):
                monster_dict[image_name][key] = [frame_dict[(col,row)] for col in range(cols)]

    return monster_dict


#
# This imports a tile sheet that should be used for attack animations. All the attack
#   sprite sheets will be 4x1.
#
def importAttacks(*path):
	attack_dict = {}
	for folder_path, _, image_names in walk(join(*path)):
		for image in image_names:
			image_name = image.split('.')[0]
			attack_dict[image_name] = list(importTilemap(4,1,folder_path, image_name).values())
	return attack_dict
            
#######################################################################################################################
#
# These are some general functions that are used in the game. Check If Touching will check the relative position between
#   two objects. Draw Bars creates a bar that can be used for either progress or stat values depending on where its 
#   called. We also have our save and load game functions; either saving the current team, of Aminomons to a
#   csv save game file or will load in the trainer Aminomon data from a previous save state. This game only supports
#   one save file at a time. 
# 

#
# Outline Creater is a method that will take a series of frames for the Aminomons and shifts the image in eight 
#   directions to create a mask for the associated image that we can use as an Outline during battle.
#
def outline_creator(frame_dict, width):
    outline_frame_dict = {}
    for monster, monster_frames in frame_dict.items():
        outline_frame_dict[monster] = {}
        for state, frames in monster_frames.items():
            outline_frame_dict[monster][state] = []
            for frame in frames:
                dir_surf = pygame.Surface(vector(frame.get_size()) + vector(width *2), pygame.SRCALPHA)
                dir_surf.fill((0,0,0,0))
                white_frame = pygame.mask.from_surface(frame).to_surface()
                white_frame.set_colorkey('black')

                dir_surf.blit(white_frame, (0,0))
                dir_surf.blit(white_frame, (width,0))
                dir_surf.blit(white_frame, (width * 2,0))
                dir_surf.blit(white_frame, (width * 2,width))
                dir_surf.blit(white_frame, (width * 2,width * 2))
                dir_surf.blit(white_frame, (width,width * 2))
                dir_surf.blit(white_frame, (0,width * 2))
                dir_surf.blit(white_frame, (0,width))

                outline_frame_dict[monster][state].append(dir_surf)

    return outline_frame_dict

#
# This function will check the relative position of an object and target object.
#   It takes a radius to use, two objects, and a tolerance threshold for how
#   close the two objects need to be.
#
def check_if_touching(radius, entity, target, tolerance = 30):
    relativePos = vector(target.rect.center) - vector(entity.rect.center)
    if relativePos.length() < radius:
        if entity.facing_direction == 'left' and relativePos.x < 0 and abs(relativePos.y) < tolerance or\
		   entity.facing_direction == 'right' and relativePos.x > 0 and abs(relativePos.y) < tolerance or\
		   entity.facing_direction == 'up' and relativePos.y < 0 and abs(relativePos.x) < tolerance or\
		   entity.facing_direction == 'down' and relativePos.y > 0 and abs(relativePos.x) < tolerance:
           return True

#
# The Draw Bars functions creates a bar using a max value and current value for associated stat.
#   This will be used to monitor Health and Energy out of the total, compare relative stat value, 
#   show xp progress, and battle initiative. 
#
def draw_bars(surface, rect, value, max_value, color, bgColor, radius =1):
    ratio = rect.width / max_value
    bg_rect = rect.copy()
    progress = max(0, min(rect.width, value * ratio))
    progress_rect = pygame.FRect(rect.topleft, (progress, rect.height))
    pygame.draw.rect(surface, bgColor, bg_rect, 0, radius)
    pygame.draw.rect(surface, color, progress_rect, 0, radius)

#
# Takes the current Aminomon team and saves to a csv file using the index, Aminomon Name, and 
#   the Aminomons level.
#
def save_trainer_data(current_aminos, stored_aminos):
    file_path = join("data", "save", "player_aminos.csv")
    with open(file_path, mode='w', newline='') as file:
        write = csv.writer(file)

        write.writerow(['index', 'name', 'level', 'xp_amount'])
        
        # Write the monster data
        for index, monster in current_aminos.items():
            write.writerow([index, monster.name, monster.level, monster.xp])

    file_path = join("data", "save", "player_storage.csv")
    with open(file_path, mode='w', newline='') as file:
        write = csv.writer(file)

        write.writerow(['index', 'name', 'level', 'xp_amount'])
        
        # Write the monster data
        for index, monster in stored_aminos.items():
            write.writerow([index, monster.name, monster.level, monster.xp])

#
# This is a function that only can be called from the Home Screen when starting the game.
#   This loads in a previous team of Aminoacids stores in a csv file. The file has columns:
#   index, name, and level for each of the Aminomons. It returns a list of Tuples. 
#
def load_trainer_data():
    file_path = join("data", "save", "player_aminos.csv")
    saved_aminos = []
    
    try: 
        with open(file_path, mode='r') as file:
            reader = csv.DictReader(file)

            for row in reader:
                index = int(row['index'])
                name = row['name']
                level = int(row['level'])
                xp_amount = int(float(row['xp_amount']))

                saved_aminos.append([index, name, level, xp_amount])
    
    except FileNotFoundError:
        pass

    return saved_aminos

def load_storage_data():
    file_path = join("data", "save", "player_storage.csv")
    saved_aminos = []
    
    try: 
        with open(file_path, mode='r') as file:
            reader = csv.DictReader(file)

            for row in reader:
                index = int(row['index'])
                name = row['name']
                level = int(row['level'])
                xp_amount = int(float(row['xp_amount']))

                saved_aminos.append([index, name, level, xp_amount])
    
    except FileNotFoundError:
        pass

    return saved_aminos