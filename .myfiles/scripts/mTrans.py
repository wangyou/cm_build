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
dictdir=os.path.abspath(rdir+"/../trans")

file_log=open(dictdir+"/log.txt","w")
bLine=re.compile("[\r\n]*\s*[\r\n]")
mode=0

#####function mTrans###########
def mTrans(xmlfile,xmldict,output):
   tree=None
   tree0=None
   tree1=None
   tree2=None
   tree3=None
   root=None
   root0=None
   root1=None
   root2=None
   root3=None

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
        pass

   xmlname=os.path.basename(xmlfile)
   if xmlname[0:3] == "cm_" :
        bbxml=xmlname.replace("cm_","")
        if os.path.exists(os.path.dirname(xmlfile)+"/"+bbxml):
            tree0=ET.parse(os.path.dirname(xmlfile)+"/"+bbxml)
            root0=tree0.getroot()
            for item in root0:
                try:
                    elem=root.find(".//*[@name='"+item.attrib['name']+"']")
                    if elem is None:
                        root.append(item)
                except:
                    pass
        if os.path.exists(os.path.dirname(xmlout)+"/"+bbxml):
            tree3=ET.parse(os.path.dirname(xmlout)+"/"+bbxml)
            root3=tree3.getroot()

   printedHead=0
   pos=0
   rootlen=len(root)
   while True:
           try:
                 child_of_root=root[pos]
           except:
               break

           if child_of_root is None:
              pos+=1
              continue
           
           if child_of_root.attrib.has_key("translatable") and (child_of_root.attrib['translatable'] == 'false'):
               root.remove(child_of_root)
               continue

           if not root3 is None:
               elem3 = root3.find(".//*[@name='"+child_of_root.attrib['name']+"']")
               if not elem3 is None:
                   root.remove(child_of_root)
                   continue

           try:
               elem = root1.find(".//*[@name='"+child_of_root.attrib['name']+"']")
           except:
               elem = None

           if not elem is None:
               root.remove(child_of_root);
               elem.tail=bLine.sub("\r\n",elem.tail)
               if not (elem.attrib.has_key("translatable") and (elem.attrib['translatable']== 'false')):
                   root.insert(pos,elem)
                   pos+=1
               continue
           else:
               try:
                  elem2=root2.find(".//*[@name='"+child_of_root.attrib['name']+"']")
               except:
                  elem2=None

               if not elem2 is None:
                    root.remove(child_of_root);
                    elem2.tail=bLine.sub("\r\n",elem2.tail)
                    if not (elem2.attrib.has_key("translatable") and (elem2.attrib['translatable']== 'false')):
                        root.insert(pos,elem2)
                        pos+=1
                    continue
               else:
                    if not child_of_root is None:
                        try:
                            child_of_root.tail=bLine.sub("\r\n",child_of_root.tail)
                            if printedHead == 0:
                                   print "\n",baseXMLname,":\n===================="
                                   print >> file_log, "\n",baseXMLname,":\n===================="
                                   printedHead = 1
                            print  "[X] ",child_of_root.attrib['name'], child_of_root.text.strip("\r\n\t ")
                            print >> file_log,  "[X] ",child_of_root.attrib['name'], child_of_root.text.strip("\r\n\t ")
                        except:
                            root.remove(child_of_root)
                            continue
                    else:
                        root.remove(child_of_root)
                        continue
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


