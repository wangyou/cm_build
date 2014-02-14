#!/usr/bin/python
# -*- coding:utf-8 -*-
from xml.etree import ElementTree as ET
import sys
import os

rdir=os.path.dirname(os.path.abspath(sys.argv[0]))
basedir=os.path.abspath(rdir+"/../..")
dictdir=basedir+"/.myfiles/trans"

#print "argv:",sys.argv," argc:",len(sys.argv)


#####function mTrans###########
def mTrans(xmlfile,xmldict,output):
   baseXMLname=os.path.abspath(xmlfile).replace(basedir+"/","")
   print baseXMLname,":\n===================="

   try:
        tree = ET.parse(xmlfile) 
        root = tree.getroot() 
        tree1 = ET.parse(xmldict)
        root1 = tree1.getroot() 
   except Exception,e:
        print e  
        return -1
   try:
        tree2 = ET.parse(xmlout)
        root2 = tree2.getroot() 
   except:
         print
   
   if os.path.basename(xmlfile).find("string") != -1:
       for child_of_root in root:
           try:
               elem = root1.find(".//*[@name='"+child_of_root.attrib['name']+"']")
               ditxt=elem.itertext();
               for txt in child_of_root.itertext():
                      txt=ditxt
                      ditxt.next()
#               print  child_of_root.attrib['name'],child_of_root.text
           except:
               try:
                    elem2=root2.find(".//*[@name='"+child_of_root.attrib['name']+"']")
                    child_of_root.text=elem2.text
#                    print child_of_root.attrib['name'],elem2.text
               except:
                    print  "[X] ",child_of_root.attrib['name'], child_of_root.text
    
       tree.write(output,encoding="utf-8",xml_declaration=True) 
#       tree.write(xmldict,encoding="utf-8",xml_declaration=True) 

#   else :
#       tree1.write(output,encoding="utf-8",xml_declaration=True) 
      
   return 0


if len(sys.argv) < 4:
  for s in os.listdir(dictdir):
    langName=s
    if os.path.isdir(dictdir+"/"+s):
         for f in os.listdir(dictdir+"/"+s):
             xmlname=f.split("-")[1]
             project=f.split("-")[0].replace("_","/")
             xmlfile=basedir+"/"+project+"/res/values/"+xmlname
             xmldict=dictdir+"/"+s+"/"+f
             xmlout= basedir+"/"+project+"/res/values-"+langName+"/"+xmlname
             mTrans(xmlfile,xmldict,xmlout)

else:
    xmlfile=os.path.abspath(sys.argv[1])
    xmldict=os.path.abspath(sys.argv[2])
    xmlout=os.path.abspath(sys.argv[3])
    if not os.path.exists(xmlfile):
        print "Error: ",xmlfile," Not Exists!"
        exit(-1)
    if not os.path.exists(xmldict):
        print "Error: ",xmldict," Not Exists!"
        exit(-1)
    mTrans(xmlfile,xmldict,xmlout)


