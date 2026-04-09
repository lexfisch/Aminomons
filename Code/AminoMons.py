#######################################################################################################################
# Aminomon.py
# This is the file for the Aminomon class. When an Aminomon is created, it takes a name, level, and xp_amount.
#    Then it will load in base stats from the peptideDex for that specific monster and multiplies it by the given level.
#    The class takes an xp_amount from a load file so that you do not lose your progress between sessions. This file
#    includes methods to get a string representation of the name, get stats or get stat directly, abilities, battle calculations, 
#    a limiter so that neither health nor energy push over 100%.
#
######################################################################################################################
from  BigBigData import *
from random import randint

#
# This method will instantiate an AminoAcid Mob
# It will read in general info from the peptideDex within bigBigData
# It will unpack base level stats into the object, then scale it per mob level.
#
class Aminomons(): 
    def __init__(self, name, level, xp_amount):
        self.name, self.level = name, level
        self.paused = False
        self.element = peptideDex[name]['stats']['element']
        self.base_stats = peptideDex[name]['stats']
        self.health = self.base_stats['MAX_HEALTH'] * self.level
        self.energy = self.base_stats['MAX_ENERGY'] * self.level
        self.initiative = 0
        self.abilities = peptideDex[name]['ability']
        self.defending = False
        self.xp = xp_amount
        self.level_up = self.level * 150
        #self.update_xp(xp_amount)
        self.fusion = peptideDex[self.name]['fusion']
        self.unfusion = peptideDex[self.name]['unfusion']

    #
    # Returns an f string of the Aminomon name and level, this was useful for troubleshooting
    #
    def __repr__(self):
        return f'monster: {self.name}, lvl: {self.level}'
    
    #
    # Returns a single selected base state 
    #
    def get_single_stat(self,stat):
        return self.base_stats[stat] * self.level
    
    #
    # Returns all of the stats for a given Aminomon.
    #
    def get_all_stats(self):
        return {
            'health': self.get_single_stat('MAX_HEALTH'),
            'energy': self.get_single_stat('MAX_ENERGY'),
            'attack': self.get_single_stat('attack'),
            'defense': self.get_single_stat('defense'),
            'speed': self.get_single_stat('speed'),
            'recovery': self.get_single_stat('recovery')
        }
    
    #
    # Returns the skills of the Aminomon
    #
    def get_skills(self, all = True):
        if all:
            return [ability for level, ability in self.abilities.items() if self.level >= level]
        else:
            return [ability for level, ability in self.abilities.items() if self.level >= level and SKILLS_DATA[ability]['cost'] < self.energy]

    #
    # Returns tuples of the health and its max, the energy and its max, and initiative with a max of 100
    #
    def get_info(self):
        return (
			(self.health, self.get_single_stat('MAX_HEALTH')),
			(self.energy, self.get_single_stat('MAX_ENERGY')),
			(self.initiative, 100)
			)

    #
    # After using an ability, this function will subtract the cost of the ability from the Aminomons energy
    #    
    def subtract_cost(self, attack):
        self.energy -= SKILLS_DATA[attack]['cost']

    #
    # This returns the amount of damage or healing depending on the skill used and the stat
    #   of the Aminomon using it.
    #
    def get_attack_value(self, attack):
        if attack == 'heal': return self.get_single_stat('recovery') * SKILLS_DATA[attack]['amount']
        else: return self.get_single_stat('attack') * SKILLS_DATA[attack]['amount']

    #
    # This updates the experience points that the Aminomon has, it its over the threshold,
    #   the Aminomon will level up.
    #
    def add_xp(self, amount):
        self.xp += amount
        while self.xp >= self.level_up:
            self.xp -= self.level_up
            self.level += 1
            self.level_up = self.level * 150

    #
    # Set the limiter for Health and Energy so that they never go below 0 or above 100%.
    #
    def health_energy_limiter(self):
        self.health = max(0, min(self.health, self.get_single_stat('MAX_HEALTH')))
        self.energy = max(0, min(self.energy, self.get_single_stat('MAX_ENERGY')))
        
    #
    # This is the update function for the Aminomons.
    #
    def update(self, dt):
        self.health_energy_limiter()
        if not self.paused:
            self.initiative += self.get_single_stat('speed') * dt