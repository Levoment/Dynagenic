#!/usr/bin/env python3 

import os, sys, shutil, stat, subprocess



# get absolute input and output paths
input_path = sys.argv[1]


# make sure destination directory exists
os.makedirs(os.path.dirname(input_path), exist_ok=True)

for directory, subdirectories, files in os.walk(input_path):
    for folder in subdirectories:
        if "dynagenic/resources" in os.path.join(directory, folder):
            print ("Changing permission of: " +  os.path.join(directory, folder))
            # Make the directory have Everyone can read/write/execute permissions
            os.chmod(os.path.join(directory, folder), stat.S_IRWXO)
    for file in files:
        if "dynagenic/resources" in os.path.join(directory, file):
            print ("Changing permission of: " +  os.path.join(directory, file))
            # Make the file have Everyone can read/write permissions
            os.chmod(os.path.join(directory, file), stat.S_IROTH | stat.S_IWOTH)