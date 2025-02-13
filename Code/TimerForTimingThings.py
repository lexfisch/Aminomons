###################################################################################
# TimerforTimingThings.py
# This file contains the class functions for our timers.
#
###################################################################################

from pygame.time import get_ticks


#
# We use Timers frequently in this project. This is the Timer class we create. It contains an 
#   activate, deactivate, and update function.
#
class Timer:
    def __init__(self, duration, repeat = False, autostart = False, func = None):
        self.duration = duration
        self.startTime = 0
        self.active = False
        self.repeat = repeat
        self.func = func
        if autostart:
            self.turnOn()

    #
    # This function will turn the timer on and start counting.
    #
    def turnOn(self):
        self.active = True
        self.start_time = get_ticks()

    #
    # This function stops the timer and resets the start time to zero. It will then reactivate
    #   if the timer is repeated.
    #
    def turnOff(self):
        self.active = False
        self.start_time = 0
        if self.repeat:
            self.turnOn()

    #
    # This is the update function for our timer. It will check against the duration of the timer
    #   and if longer, then call the timer's associated function. It will then call for the timer to
    #   deactivate.
    #
    def update(self):
        if self.active:
            current_time = get_ticks()
            if current_time - self.start_time >= self.duration:
                if self.func: self.func()
                self.turnOff()
