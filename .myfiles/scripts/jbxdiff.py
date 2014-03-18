#!/usr/bin/python
# -*- coding:utf-8 -*-
import os
import sys

rdir=os.path.dirname(os.path.abspath(sys.argv[0]))
basedir=os.path.abspath(rdir+"/../..")
confdir=basedir+"/kernel/motorola/omap4-common/arch/arm/configs/"
if not os.path.exists(confdir+"mapphone_OCE_defconfig") or not os.path.exists(confdir+"mapphone_OCEdison_defconfig"):
   exit(-1)


fOCE = open(confdir+"mapphone_OCE_defconfig")
line = fOCE.readline()  
config={}          
while line:
    line=line.split("#")[0].strip()
    if line is None or line == "":
        line = fOCE.readline()
        continue
    key=line.split("=")[0]
    value=line.split("=")[1]
    if not key is None and key != "":
        config[key]=value
#        print key+" = "+value
    line = fOCE.readline()

fOCE.close()

print "\n"
fEdison= open(confdir+"mapphone_OCEdison_defconfig")
line = fEdison.readline() 
while line:
    line=line.split("#")[0].strip()
    if line is None or line == "":
        line = fEdison.readline()
        continue
    key=line.split("=")[0]
    value=line.split("=")[1]
    if config.has_key(key) and config[key]==value:
       del(config[key])
    elif config.has_key(key) and config[key] != value:
       print key+" = "+config[key]+"\t=>"+value
       config[key]=key
    elif not value is None:
       print key+" = "+value
       config[key]=value  
    line = fEdison.readline()
    
fEdison.close()
print "\n=========== ALL DIFFRENT CONFIGS ================="
for (k,v) in config.items():
    print "%s="% k,v

