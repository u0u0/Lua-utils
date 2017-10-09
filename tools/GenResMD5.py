#!/usr/bin/env python
# -*- coding: UTF-8 -*-
"""
NAME
    GenResMD5 --


SYNOPSIS
    GenResMD5 [-h]
"""

import os
import hashlib
import json
import re

ignoreDir = ["Default"]
output = "version.json"
scriptRoot = os.path.split(os.path.realpath(__file__))[0]
info = {}
info["EngineVersion"] = "1.0.0"
info["GameVersion"] = "1.0.0"
info["packages"] = ["game", "gameA"] # first package name is fixed for cpp
info["asserts"] = {}

def joinDir(root, *dirs):
    for item in dirs:
        root = os.path.join(root, item)
    return root

scanRoot = joinDir(scriptRoot, "res")

def getMD5(root):
    files = os.listdir(root)
    for f in files:
        itemPath = joinDir(root, f)
        if os.path.isdir(itemPath):
            if (f[0] == '.' or (f in ignoreDir)):
                pass
            else:
                getMD5(itemPath)
        elif os.path.isfile(itemPath):
            if f[0] != '.' and f != output:
                fp = open(itemPath, 'rb')
                m5 = hashlib.md5()
                m5.update(fp.read())
                fp.close()
                name = itemPath[(len(scanRoot) + 1):]
                if os.sep == '\\':
                    name = re.sub('\\\\', '/', name)
                # key is path, value[0] = md5, value[2] = size
                info["asserts"][name] = [m5.hexdigest(), os.path.getsize(itemPath)]

getMD5(scanRoot)
jsonStr = json.dumps(info)
fp = open(joinDir(scanRoot, output), "wb")
fp.write(jsonStr)
fp.close()
