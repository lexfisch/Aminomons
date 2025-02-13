#######################################################################################################################
# BigBigData.py
# This is the BigBigData file. It contains all the information on available Aminomons in the game, the trainer data
#   and the information on monster abilities.  
#
#######################################################################################################################

#
# This is the Peptide Dex dictionary. It contains all the Aminomons in the game. It has their base stats (multiple by their 
#   level when they level up), their abilities, their fusion and unfusion information, their ID Number, and a Dictionary of science
#   facts containing Three Letter Code, One Letter Code, if its charged, if its polar, and a place for a desc.
#
peptideDex = {
    "alanine":{"stats": {"MAX_HEALTH": 42, "MAX_ENERGY":29, "attack": 5, "defense": 5, "speed": 51, "recovery": 6, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("alaninex2", 8),
                    'unfusion' : None, 
                    "id": 1, 
                    "sci": {"three_letter": "Ala", "single_letter": "A", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "alaninex2":{"stats": {"MAX_HEALTH": 52, "MAX_ENERGY":39, "attack": 7, "defense": 7, "speed": 61, "recovery": 8, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("alaninex3", 20),
                    'unfusion' : "alanine", 
                    "id": 2, 
                    "sci": {"three_letter": "Ala", "single_letter": "A", "charged": False, "polar": False, "desc": "This is the desc"}},
    "alaninex3":{"stats": {"MAX_HEALTH": 62, "MAX_ENERGY":49, "attack": 9, "defense": 9, "speed": 71, "recovery": 10, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "alaninex2", 
                    "id": 3, 
                    "sci": {"three_letter": "Ala", "single_letter": "A", "charged": False, "polar": False, "desc": "This is the desc"}},

    
    "arginine": {"stats": {"MAX_HEALTH": 20, "MAX_ENERGY":44, "attack": 6, "defense": 5, "speed": 89, "recovery": 5, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("argininex2", 8),
                    'unfusion' : None, 
                    "id": 4, 
                    "sci": {"three_letter": "Arg", "single_letter": "R", "charged": True, "polar": True, "desc": "This is the desc"}},  
    "argininex2": {"stats": {"MAX_HEALTH": 30, "MAX_ENERGY": 54, "attack": 8, "defense": 7, "speed": 99, "recovery": 7, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("argininex3", 20),
                    'unfusion' : "arginine", 
                    "id": 5, 
                    "sci": {"three_letter": "Arg", "single_letter": "R", "charged": True, "polar": True, "desc": "This is the desc"}},  
    "argininex3": {"stats": {"MAX_HEALTH": 40, "MAX_ENERGY":64, "attack": 10, "defense": 9, "speed": 109, "recovery": 9, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "argininex2", 
                    "id": 6, 
                    "sci": {"three_letter": "Arg", "single_letter": "R", "charged": True, "polar": True, "desc": "This is the desc"}}, 
    
    
    "asparagine": {"stats": {"MAX_HEALTH": 31, "MAX_ENERGY":59, "attack": 2, "defense": 5, "speed": 48, "recovery": 4, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("asparaginex2", 8),
                    'unfusion' : None, 
                    "id": 7, 
                    "sci": {"three_letter": "Asn", "single_letter": "N", "charged": False, "polar": True, "desc": "This is the desc"}}, 
    "asparaginex2": {"stats": {"MAX_HEALTH": 41, "MAX_ENERGY":69, "attack": 4, "defense": 7, "speed": 58, "recovery": 6, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("asparaginex3", 20),
                    'unfusion' : "asparagine", 
                    "id": 8, 
                    "sci": {"three_letter": "Asn", "single_letter": "N", "charged": False, "polar": True, "desc": "This is the desc"}}, 
    "asparaginex3": {"stats": {"MAX_HEALTH": 51, "MAX_ENERGY":79, "attack": 6, "defense": 9, "speed": 68, "recovery": 8, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "asparaginex2", 
                    "id": 9, 
                    "sci": {"three_letter": "Asn", "single_letter": "N", "charged": False, "polar": True, "desc": "This is the desc"}}, 


    "aspartic": {"stats": {"MAX_HEALTH": 19, "MAX_ENERGY":43, "attack": 5, "defense": 6, "speed": 93, "recovery": 5, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("asparticx2", 8),
                    'unfusion' : None, 
                    "id": 10, 
                    "sci": {"three_letter": "Asp", "single_letter": "D", "charged": True, "polar": True, "desc": "This is the desc"}}, 
    "asparticx2": {"stats": {"MAX_HEALTH": 29, "MAX_ENERGY":33, "attack": 7, "defense": 8, "speed": 103, "recovery": 7, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("asparticx3", 20),
                    'unfusion' : "aspartic", 
                    "id": 11, 
                    "sci": {"three_letter": "Asp", "single_letter": "D", "charged": True, "polar": True, "desc": "This is the desc"}},  
    "asparticx3": {"stats": {"MAX_HEALTH": 39, "MAX_ENERGY":63, "attack": 9, "defense": 10, "speed": 113, "recovery": 9, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "asparticx2", 
                    "id": 12, 
                    "sci": {"three_letter": "Asp", "single_letter": "D", "charged": True, "polar": True, "desc": "This is the desc"}},  


    "cysteine": {"stats": {"MAX_HEALTH": 30, "MAX_ENERGY":46, "attack": 4, "defense": 8, "speed": 28, "recovery": 5, "element": "earth"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("cysteinex2", 8),
                    'unfusion' : None, 
                    "id": 13, 
                    "sci": {"three_letter": "Cys", "single_letter": "C", "charged": False, "polar": False, "desc": "This is the desc"}},  
    "cysteinex2": {"stats": {"MAX_HEALTH": 40, "MAX_ENERGY":56, "attack": 6, "defense": 10, "speed": 38, "recovery": 7, "element": "earth"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("cysteinex3", 20),
                    'unfusion' : "cysteine", 
                    "id": 14, 
                    "sci": {"three_letter": "Cys", "single_letter": "C", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "cysteinex3": {"stats": {"MAX_HEALTH": 50, "MAX_ENERGY":66, "attack": 8, "defense": 12, "speed": 48, "recovery": 9, "element": "earth"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "cysteinex2", 
                    "id": 15, 
                    "sci": {"three_letter": "Cys", "single_letter": "C", "charged": False, "polar": False, "desc": "This is the desc"}}, 

    
    "glutamic":{"stats": {"MAX_HEALTH": 22, "MAX_ENERGY":45, "attack": 4, "defense": 6, "speed": 90, "recovery": 4, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("glutamicx2", 8),
                    'unfusion' : None, 
                    "id": 16, 
                    "sci": {"three_letter": "Glu", "single_letter": "E", "charged": True, "polar": True, "desc": "This is the desc"}}, 
    "glutamicx2":{"stats": {"MAX_HEALTH": 32, "MAX_ENERGY":55, "attack": 6, "defense": 8, "speed": 100, "recovery": 6, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("glutamicx3", 20),
                    'unfusion' : "glutamic", 
                    "id": 17, 
                    "sci": {"three_letter": "Glu", "single_letter": "E", "charged": True, "polar": True, "desc": "This is the desc"}}, 
    "glutamicx3":{"stats": {"MAX_HEALTH": 42, "MAX_ENERGY":65, "attack": 8, "defense": 10, "speed": 110, "recovery": 8, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "glutamicx2", 
                    "id": 18, 
                    "sci": {"three_letter": "Glu", "single_letter": "E", "charged": True, "polar": True, "desc": "This is the desc"}}, 

    
    "glutamine": {"stats": {"MAX_HEALTH": 33, "MAX_ENERGY":57, "attack": 3, "defense": 4, "speed": 47, "recovery": 6, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("glutaminex2", 8),
                    'unfusion' : None, 
                    "id": 19, 
                    "sci": {"three_letter": "Gln", "single_letter": "Q", "charged": False, "polar": True, "desc": "This is the desc"}}, 
    "glutaminex2": {"stats": {"MAX_HEALTH": 43, "MAX_ENERGY":67, "attack": 5, "defense": 6, "speed": 57, "recovery": 8, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("glutaminex3", 20),
                    'unfusion' : "glutamine", 
                    "id": 20, 
                    "sci": {"three_letter": "Gln", "single_letter": "Q", "charged": False, "polar": True, "desc": "This is the desc"}}, 
    "glutaminex3": {"stats": {"MAX_HEALTH": 53, "MAX_ENERGY":77, "attack": 7, "defense": 8, "speed": 67, "recovery": 10, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "glutaminex2", 
                    "id": 21, 
                    "sci": {"three_letter": "Gln", "single_letter": "Q", "charged": False, "polar": True, "desc": "This is the desc"}}, 

    
    "glycine": {"stats": {"MAX_HEALTH": 44, "MAX_ENERGY":30, "attack": 9, "defense": 3, "speed": 50, "recovery": 4, "element": "fire"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("glycinex2", 8),
                    'unfusion' : None, 
                    "id": 22, 
                    "sci": {"three_letter": "Gly", "single_letter": "G", "charged": False, "polar": False, "desc": "This is the desc"}},
    "glycinex2": {"stats": {"MAX_HEALTH": 54, "MAX_ENERGY":40, "attack": 11, "defense": 5, "speed": 60, "recovery": 6, "element": "fire"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("glycinex3", 20),
                    'unfusion' : "glycine", 
                    "id": 23, 
                    "sci": {"three_letter": "Gly", "single_letter": "G", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "glycinex3": {"stats": {"MAX_HEALTH": 64, "MAX_ENERGY":50, "attack": 13, "defense": 7, "speed": 70, "recovery": 8, "element": "fire"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "glycinex2", 
                    "id": 24, 
                    "sci": {"three_letter": "Gly", "single_letter": "G", "charged": False, "polar": False, "desc": "This is the desc"}},   
    

    "histidine": {"stats": {"MAX_HEALTH": 21, "MAX_ENERGY":40, "attack": 4, "defense": 6, "speed": 85, "recovery": 5, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("histidinex2", 8),
                    'unfusion' : None,
                    "id": 25, 
                    "sci": {"three_letter": "His", "single_letter": "H", "charged": True, "polar": True, "desc": "This is the desc"}},
    "histidinex2": {"stats": {"MAX_HEALTH": 31, "MAX_ENERGY":50, "attack": 6, "defense": 8, "speed": 95, "recovery": 7, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("histidinex3", 20),
                    'unfusion' : "histidine", 
                    "id": 26, 
                    "sci": {"three_letter": "His", "single_letter": "H", "charged": True, "polar": True, "desc": "This is the desc"}}, 
    "histidinex3": {"stats": {"MAX_HEALTH": 41, "MAX_ENERGY":60, "attack": 8, "defense": 10, "speed": 105, "recovery": 9, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "histidinex2", 
                    "id": 27, 
                    "sci": {"three_letter": "His", "single_letter": "H", "charged": True, "polar": True, "desc": "This is the desc"}}, 

    
    "isoleucine": {"stats": {"MAX_HEALTH": 41, "MAX_ENERGY":26, "attack": 5, "defense": 4, "speed": 53, "recovery": 5, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("isoleucinex2", 8),
                    'unfusion' : None, 
                    "id": 28, 
                    "sci": {"three_letter": "Ile", "single_letter": "I", "charged": False, "polar": False, "desc": "This is the desc"}},
    "isoleucinex2": {"stats": {"MAX_HEALTH": 51, "MAX_ENERGY":36, "attack": 7, "defense": 6, "speed": 63, "recovery": 7, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("isoleucinex3", 20),
                    'unfusion' : "isoleucine", 
                    "id": 29, 
                    "sci": {"three_letter": "Ile", "single_letter": "I", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "isoleucinex3": {"stats": {"MAX_HEALTH": 61, "MAX_ENERGY":46, "attack": 9, "defense": 8, "speed": 73, "recovery": 9, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "isoleucinex2", 
                    "id": 30, 
                    "sci": {"three_letter": "Ile", "single_letter": "I", "charged": False, "polar": False, "desc": "This is the desc"}},   

    
    "leucine": {"stats": {"MAX_HEALTH": 30, "MAX_ENERGY":43, "attack": 5, "defense": 9, "speed": 30, "recovery": 4, "element": "earth"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("leucinex2", 8),
                    'unfusion' : None, 
                    "id": 31, 
                    "sci": {"three_letter": "Leu", "single_letter": "L", "charged": False, "polar": False, "desc": "This is the desc"}},
    "leucinex2": {"stats": {"MAX_HEALTH": 40, "MAX_ENERGY":53, "attack": 7, "defense": 11, "speed": 40, "recovery": 6, "element": "earth"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("leucinex3", 20),
                    'unfusion' : "leucine", 
                    "id": 32, 
                    "sci": {"three_letter": "Leu", "single_letter": "L", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "leucinex3": {"stats": {"MAX_HEALTH": 50, "MAX_ENERGY":63, "attack": 9, "defense": 13, "speed": 50, "recovery": 8, "element": "earth"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None, 
                    'unfusion' : "leucinex2",
                    "id": 33, 
                    "sci": {"three_letter": "Leu", "single_letter": "L", "charged": False, "polar": False, "desc": "This is the desc"}}, 

    
    "lysine": {"stats": {"MAX_HEALTH": 18, "MAX_ENERGY":41, "attack": 7, "defense": 6, "speed": 95, "recovery": 5, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("lysinex2", 8),
                    'unfusion' : None, 
                    "id": 34, 
                    "sci": {"three_letter": "Lys", "single_letter": "K", "charged": True, "polar": True, "desc": "This is the desc"}},
    "lysinex2": {"stats": {"MAX_HEALTH": 28, "MAX_ENERGY":51, "attack": 9, "defense": 8, "speed": 105, "recovery": 7, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("lysinex3", 20),
                    'unfusion' : "lysinex2", 
                    "id": 35, 
                    "sci": {"three_letter": "Lys", "single_letter": "K", "charged": True, "polar": True, "desc": "This is the desc"}},
    "lysinex3": {"stats": {"MAX_HEALTH": 38, "MAX_ENERGY":61, "attack": 11, "defense": 10, "speed": 115, "recovery": 9, "element": "electric"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "lysinex2", 
                    "id": 36, 
                    "sci": {"three_letter": "Lys", "single_letter": "K", "charged": True, "polar": True, "desc": "This is the desc"}},  
    

    "methionine": {"stats": {"MAX_HEALTH": 43, "MAX_ENERGY":27, "attack": 8, "defense": 3, "speed": 48, "recovery": 6, "element": "fire"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("methioninex2", 8),
                    'unfusion' : None, 
                    "id": 37, 
                    "sci": {"three_letter": "Met", "single_letter": "M", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "methioninex2": {"stats": {"MAX_HEALTH": 53, "MAX_ENERGY":37, "attack": 10, "defense": 5, "speed": 58, "recovery": 8, "element": "fire"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("methioninex3", 20),
                    'unfusion' : "methionine", 
                    "id": 38, 
                    "sci": {"three_letter": "Met", "single_letter": "M", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "methioninex3": {"stats": {"MAX_HEALTH": 63, "MAX_ENERGY":47, "attack": 12, "defense": 7, "speed": 68, "recovery": 10, "element": "fire"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "methioninex2", 
                    "id": 39, 
                    "sci": {"three_letter": "Met", "single_letter": "M", "charged": False, "polar": False, "desc": "This is the desc"}}, 

    
    "phenylalanine": {"stats": {"MAX_HEALTH": 40, "MAX_ENERGY":30, "attack": 4, "defense": 4, "speed": 65, "recovery": 6, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("phenylalaninex2", 8),
                    'unfusion' : None, 
                    "id": 40, 
                    "sci": {"three_letter": "Phe", "single_letter": "F", "charged": False, "polar": False, "desc": "This is the desc"}},
    "phenylalaninex2": {"stats": {"MAX_HEALTH": 50, "MAX_ENERGY":40, "attack": 6, "defense": 6, "speed": 75, "recovery": 8, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("phenylalaninex3", 20),
                    'unfusion' : "phenylalanine", 
                    "id": 41, 
                    "sci": {"three_letter": "Phe", "single_letter": "F", "charged": False, "polar": False, "desc": "This is the desc"}},
    "phenylalaninex3": {"stats": {"MAX_HEALTH": 60, "MAX_ENERGY":50, "attack": 8, "defense": 8, "speed": 85, "recovery": 10, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "phenylalaninex2", 
                    "id": 42, 
                    "sci": {"three_letter": "Phe", "single_letter": "F", "charged": False, "polar": False, "desc": "This is the desc"}},

    
    "proline": {"stats": {"MAX_HEALTH": 34, "MAX_ENERGY":45, "attack": 5, "defense": 10, "speed": 28, "recovery": 8, "element": "earth"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("prolinex2", 8),
                    'unfusion' : None, 
                    "id": 43, 
                    "sci": {"three_letter": "Pro", "single_letter": "P", "charged": False, "polar": False, "desc": "This is the desc"}},
    "prolinex2": {"stats": {"MAX_HEALTH": 44, "MAX_ENERGY":55, "attack": 7, "defense": 12, "speed": 38, "recovery": 8, "element": "earth"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("prolinex3", 20),
                    'unfusion' : "proline", 
                    "id": 44, 
                    "sci": {"three_letter": "Pro", "single_letter": "P", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "prolinex3": {"stats": {"MAX_HEALTH": 54, "MAX_ENERGY":65, "attack": 9, "defense": 14, "speed": 48, "recovery": 12, "element": "earth"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "prolinex2", 
                    "id": 45, 
                    "sci": {"three_letter": "Pro", "single_letter": "P", "charged": False, "polar": False, "desc": "This is the desc"}}, 

    
    "serine": {"stats": {"MAX_HEALTH": 32, "MAX_ENERGY":60, "attack": 4, "defense": 6, "speed": 61, "recovery": 5, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("serinex2", 8),
                    'unfusion' : None, 
                    "id": 46, 
                    "sci": {"three_letter": "Ser", "single_letter": "S", "charged": False, "polar": True, "desc": "This is the desc"}},  
    "serinex2": {"stats": {"MAX_HEALTH": 42, "MAX_ENERGY":70, "attack": 6, "defense": 8, "speed": 71, "recovery": 7, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("serinex3", 20),
                    'unfusion' : "serine", 
                    "id": 47, 
                    "sci": {"three_letter": "Ser", "single_letter": "S", "charged": False, "polar": True, "desc": "This is the desc"}},
    "serinex3": {"stats": {"MAX_HEALTH": 52, "MAX_ENERGY":80, "attack": 8, "defense": 10, "speed": 81, "recovery": 9, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "serinex2", 
                    "id": 48, 
                    "sci": {"three_letter": "Ser", "single_letter": "S", "charged": False, "polar": True, "desc": "This is the desc"}},
    

    "threonine": {"stats": {"MAX_HEALTH": 33, "MAX_ENERGY":54, "attack": 4, "defense": 5, "speed": 54, "recovery": 4, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("threoninex2", 8),
                    'unfusion' : None, 
                    "id": 49, 
                    "sci": {"three_letter": "Thr", "single_letter": "T", "charged": False, "polar": True, "desc": "This is the desc"}},
    "threoninex2": {"stats": {"MAX_HEALTH": 43, "MAX_ENERGY":64, "attack": 6, "defense": 7, "speed": 64, "recovery": 6, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("threoninex3", 20),
                    'unfusion' : "threonine", 
                    "id": 50, 
                    "sci": {"three_letter": "Thr", "single_letter": "T", "charged": False, "polar": True, "desc": "This is the desc"}},
    "threoninex3": {"stats": {"MAX_HEALTH": 53, "MAX_ENERGY":74, "attack": 8, "defense": 9, "speed": 74, "recovery": 8, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "threoninex2", 
                    "id": 51, 
                    "sci": {"three_letter": "Thr", "single_letter": "T", "charged": False, "polar": True, "desc": "This is the desc"}},

    
    "tryptophan": {"stats": {"MAX_HEALTH": 42, "MAX_ENERGY":28, "attack": 9, "defense": 2, "speed": 45, "recovery": 8, "element": "fire"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("tryptophanx2", 8),
                    'unfusion' : None, 
                    "id": 52, 
                    "sci": {"three_letter": "Trp", "single_letter": "W", "charged": False, "polar": False, "desc": "This is the desc"}},
    "tryptophanx2": {"stats": {"MAX_HEALTH": 52, "MAX_ENERGY":38, "attack": 11, "defense": 4, "speed": 55, "recovery": 10, "element": "fire"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("tryptophanx3", 20),
                    'unfusion' : "tryptophan", 
                    "id": 53, 
                    "sci": {"three_letter": "Trp", "single_letter": "W", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "tryptophanx3": {"stats": {"MAX_HEALTH": 62, "MAX_ENERGY":48, "attack": 13, "defense": 6, "speed": 65, "recovery": 12, "element": "fire"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "tryptophanx2", 
                    "id": 54, 
                    "sci": {"three_letter": "Trp", "single_letter": "W", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    

    "tyrosine": {"stats": {"MAX_HEALTH": 34, "MAX_ENERGY":54, "attack": 3, "defense": 6, "speed": 45, "recovery": 6, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("tyrosinex2", 8),
                    'unfusion' : None, 
                    "id": 55, 
                    "sci": {"three_letter": "Trp", "single_letter": "Y", "charged": False, "polar": True, "desc": "This is the desc"}},
    "tyrosinex2": {"stats": {"MAX_HEALTH": 44, "MAX_ENERGY":64, "attack": 5, "defense": 8, "speed": 55, "recovery": 8, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("tyrosinex3", 20),
                    'unfusion' : "tyrosine", 
                    "id": 56, 
                    "sci": {"three_letter": "Trp", "single_letter": "Y", "charged": False, "polar": True, "desc": "This is the desc"}}, 
    "tyrosinex3": {"stats": {"MAX_HEALTH": 54, "MAX_ENERGY":74, "attack": 7, "defense": 10, "speed": 65, "recovery": 10, "element": "water"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "tyrosinex2", 
                    "id": 57, 
                    "sci": {"three_letter": "Trp", "single_letter": "Y", "charged": False, "polar": True, "desc": "This is the desc"}}, 

    
    "valine": {"stats": {"MAX_HEALTH": 45, "MAX_ENERGY":29, "attack": 4, "defense": 5, "speed": 57, "recovery": 8, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("valinex2", 8),
                    'unfusion' : None, 
                    "id": 58, 
                    "sci": {"three_letter": "Val", "single_letter": "V", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "valinex2": {"stats": {"MAX_HEALTH": 55, "MAX_ENERGY":39, "attack": 6, "defense": 7, "speed": 67, "recovery": 10, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": ("valinex3", 20),
                    'unfusion' : "valine", 
                    "id": 59, 
                    "sci": {"three_letter": "Val", "single_letter": "V", "charged": False, "polar": False, "desc": "This is the desc"}}, 
    "valinex3": {"stats": {"MAX_HEALTH": 65, "MAX_ENERGY":49, "attack": 8, "defense": 9, "speed": 77, "recovery": 12, "element": "normal"},
                    "ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
                    "fusion": None,
                    'unfusion' : "valinex2", 
                    "id": 60, 
                    "sci": {"three_letter": "Val", "single_letter": "V", "charged": False, "polar": False, "desc": "This is the desc"}}, 
}


#
# This is the information for the Non-player Characters in the game. It has six enemies per department (hallway), who each have preset teams.
#   a Boss enemy in the home location plus a variety of function based NPS: Healer, Fuser, Unfuser, and The PC Storage. Everyone has a direction
#   that they face, the "classroom" they use for a battle scene, and if they have been defeated or not. Each time the player moves into a new 
#   map area I have the enemies being reset.
#
TrainerInfo = {
        'bc1': {
                'monsters': {0: ('valine', 8), 1: ('tyrosine', 8)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },

        'bc2': {
                'monsters': {0: ('alanine', 8), 1: ('tryptophan', 8)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },

        'bc3': {
                'monsters': {0: ('alanine', 15), 1: ('tryptophan', 15)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },

        'bc4': {
                'monsters': {0: ('alanine', 15), 1: ('tryptophan', 15)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },

        'bc5': {
                'monsters': {0: ('alanine', 15), 1: ('tryptophan', 15)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },

        'b1': {
                'monsters': {0: ('glycine', 8), 1: ('lysine', 8)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },

        'b2': {
                'monsters': {0: ('proline', 8), 1: ('leucine', 8)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },
        
        'b3': {
                'monsters': {0: ('proline', 15), 1: ('leucine', 15)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },

        'b4': {
                'monsters': {0: ('proline', 15), 1: ('leucine', 15)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },

        'b5': {
                'monsters': {0: ('proline', 15), 1: ('leucine', 15)},
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['down'],
                'look_around': False,
                'defeated': False,
                'classroom': 'labfight'
                },

        'boss': {
                'monsters': {0:('proline', 5), 1:('isoleucine', 3)},
                'direction': 'right',
                'radius': 0,
                'look_around': False,
                'dialog': {
                    'default': ['Hey, who are you?', 'Did you run that gel?', 'No!?'], 
                    'defeated': ['Go update your lab notebook', 'We\'ll fight again sometime.']},
                'directions': ['right'],
                'defeated': False,
                'classroom': 'labfight'
		        },
        
        'healer': {
                'direction': 'right',
                'radius': 0,
                'look_around': False,
                'dialog': {
                    'default': ['BY THE POWER OF SCIENCE', 'ALL THESE MOBS FRESH'], 
                    'defeated': None},
                'directions': ['right'],
                'defeated': False,
                'classroom': None
		        },

        'fuser': {
                'direction': 'right',
                'radius': 0,
                'look_around': False,
                'dialog': {
                    'default': ['Let\'s try fusions!', 'ALL AVaILABLE ARE FUSED'], 
                    'defeated': None},
                'directions': ['right'],
                'defeated': False,
                'classroom': None
        },

        'unfuser': {
                'direction': 'right',
                'radius': 0,
                'look_around': False,
                'dialog': {
                    'default': ['You don\'t want a fusion?', 'ALL AMINOMONS ARE UNFUSED'], 
                    'defeated': None},
                'directions': ['right'],
                'defeated': False,
                'classroom': None
        },

        'storage': {
                'direction': 'right',
                'radius': 0,
                'look_around': False,
                'dialog': {
                    'default': ['I\'m the PC storage beep boop.'], 
                    'defeated': None},
                'directions': ['right'],
                'defeated': False,
                'classroom': None
        }
}

#
# This is the information on all the abilities in the game. Each have an side that they target, the energy cost, the
#   amount that they do, the element of the attack, and an associated animation (attack or heal). This information is
#   utilized during the apply attack sequence during a battle. 
#
SKILLS_DATA = {
            'burn': {'target': 'opponent', 'amount': 2, 'cost': 5, 'element': 'fire', 'animation': 'attack'},
            'heal': {'target': 'player', 'amount': 2, 'cost': 5, 'element': 'earth', 'animation': 'heal'},
            'scratch': {'target': 'opponent', 'amount': 2, 'cost': 1, 'element': 'normal', 'animation': 'attack'},
            'tackle': {'target': 'opponent', 'amount': 2, 'cost': 1, 'element': 'electric', 'animation': 'attack'},
            'splash': {'target': 'opponent', 'amount': 2, 'cost': 1, 'element': 'water', 'animation': 'attack'}
}
