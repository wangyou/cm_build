#!/usr/bin/python
# -*- coding:utf-8 -*-
from xml.etree import ElementTree as ET
import sys
import os
import re

modRefreshDict=1
modWriteTrans=2

rdir=os.path.dirname(os.path.abspath(sys.argv[0]))
basedir=os.path.abspath(rdir+"/../..")
dictdir=basedir+"/.myfiles/trans"

bLine=re.compile("[\r\n]*\s*[\r\n]")
#print "argv:",sys.argv," argc:",len(sys.argv)
mode=0

#####function mTrans###########
def mTrans(xmlfile,xmldict,output):
   baseXMLname=os.path.abspath(xmlfile).replace(basedir+"/","")
   
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

   printedHead=0
   if os.path.basename(xmlfile).find("string") != -1:
       pos=0
       for child_of_root in root:
           try:
               elem = root1.find(".//*[@name='"+child_of_root.attrib['name']+"']")
           except:
               elem = None

           if not elem is None:
               root.remove(child_of_root);
               elem.tail=bLine.sub("\r\n",elem.tail)
               root.insert(pos,elem)
           else:
               try:
                  elem2=root2.find(".//*[@name='"+child_of_root.attrib['name']+"']")
               except:
                  elem2=None

               if not elem2 is None:
                    root.remove(child_of_root);
                    elem2.tail=bLine.sub("\r\n",elem2.tail)
                    root.insert(pos,elem2)
               else:
                    if not child_of_root is None:
                        child_of_root.tail=bLine.sub("\r\n",child_of_root.tail)
                        if printedHead == 0:
                                   print "\n",baseXMLname,":\n===================="
                                   printedHead = 1
                        print  "[X] ",child_of_root.attrib['name'], child_of_root.text
                    else:
                        root.remove(child_of_root)
           pos+=1
       if mode & modWriteTrans:
           tree.write(output,encoding="utf-8",xml_declaration=True) 
       if mode & modRefreshDict:
           tree.write(xmldict,encoding="UTF-8",xml_declaration=True) 
       else:
           if not os.path.exists(os.path.dirname(xmldict)+"/out"):
              os.mkdir(os.path.dirname(xmldict)+"/out")
           ndict=os.path.dirname(xmldict)+"/out/"+os.path.basename(xmldict)
           tree.write(ndict,encoding="UTF-8",xml_declaration=True) 

   else :
       pos=0
       for child_of_root in root1:
           try:
               elem = root2.find(".//*[@name='"+child_of_root.attrib['name']+"']")
           except:
               elem = None

           if not elem is None:
               root1.remove(child_of_root);
               elem.tail=bLine.sub("\r\n",elem.tail)
               root1.insert(pos,elem)
           else:
               if not child_of_root is None:
                    child_of_root.tail=bLine.sub("\r\n",child_of_root.tail)
                    if printedHead == 0:
                          print "\n",baseXMLname,":\n===================="
                          printedHead = 1
                    print  "[X] ",child_of_root.attrib['name'], child_of_root.text
               else:
                    root1.remove(child_of_root)
           pos+=1
       if mode & modWriteTrans:
           tree1.write(output,encoding="utf-8",xml_declaration=True) 
       if mode & modRefreshDict:
           tree1.write(xmldict,encoding="UTF-8",xml_declaration=True) 
       else:
           if not os.path.exists(os.path.dirname(xmldict)+"/out"):
              os.mkdir(os.path.dirname(xmldict)+"/out")
           ndict=os.path.dirname(xmldict)+"/out/"+os.path.basename(xmldict)
           tree1.write(ndict,encoding="UTF-8",xml_declaration=True) 
      
   return 0

###############main#############3
opf=[]
j=0
pos=0
for op in sys.argv:
    if op == '-rd':
        mode |= modRefreshDict
    elif op == '-wt':
        mode |= modWriteTrans
    elif op[0] != '-' and pos > 0:
        opf.append(op)
        j+=1
    pos+=1

if j<3:
    for s in os.listdir(dictdir):
        langName=s
        if os.path.isdir(dictdir+"/"+s):
             for f in os.listdir(dictdir+"/"+s):
                 xmlname=f.split("-")[len(f.split("-"))-1]
                 project=f.split("-")[0].replace("_","/")
                 xmlfile=basedir+"/"+project+"/res/values/"+xmlname
                 xmldict=dictdir+"/"+s+"/"+f
                 xmlout= basedir+"/"+project+"/res/values-"+langName+"/"+xmlname
                 if os.path.isfile(xmlfile):
                     mTrans(xmlfile,xmldict,xmlout)

else:
    xmlfile=os.path.abspath(opf[0])
    xmldict=os.path.abspath(opf[1])
    xmlout=os.path.abspath(opf[2])
    if not os.path.exists(xmlfile):
        print "Error: ",xmlfile," Not Exists!"
        exit(-1)
    if not os.path.exists(xmldict):
        print "Error: ",xmldict," Not Exists!"
        exit(-1)
    mTrans(xmlfile,xmldict,xmlout)


