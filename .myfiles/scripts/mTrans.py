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

file_log=None
bLine=re.compile("[\r\n]*\s*[\r\n]")
mode=0

#####function mTrans###########
def indent(elem,recursive=True,level=0):
    i = "\n" + level*"  "
    if not elem is None:
        if not elem.attrib is None and elem.attrib.has_key("msgid"):
               elem.attrib.pop("msgid",None)
        if not elem.text or not elem.text.strip():
            if level==0 or len(elem)>0 and not elem.attrib is None and elem.attrib.has_key('name'):
               elem.text = i + "  "
        elif not elem.text is None:
               elem.text = elem.text.strip()
        if not elem.tail or not elem.tail.strip():
            elem.tail = i 
        if recursive:
            for elem in elem:
                indent(elem,True,level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def findItem(root,elem,lang="",ignoreProduct=False):
     if elem is None:
        return elem
     if elem.attrib is None:
        return None
     if elem.attrib.has_key('name'):
        founds=root.findall(".//*[@name='"+elem.attrib['name']+"']")
        defaultItemStr=""
        defaultItemType=""
        for founditem in founds:
            if elem.attrib.has_key("product"):
               if not founditem is None and not founditem.attrib is None:
                  if defaultItemStr == "" and ignoreProduct==True:
                      defaultItemStr=ET.tostring(founditem,'utf-8')
                      defaultItemType=founditem.attrib["product"]
                  if elem.attrib['product'] == founditem.attrib['product']:
                      return founditem
            else:
               if not founditem is None:
                  return founditem
     if defaultItemStr != "":
         if defaultItemType == 'tablet' and lang=='zh-rCN':
              itemstr=defaultItemStr.replace("平板电脑","手机")
         elif  defaultItemType == 'default' and lang=='zh-rCN':
              itemstr=defaultItemStr.replace("手机","平板电脑")
         newitem=ET.fromstring(itemstr.replace("product=\""+defaultItemType+"\"","product=\""+elem.attrib['product']+"\""))
         return newitem

     return None
                
def mTrans(xmlfile,xmldict,xmlout):
   global file_log
   tree=None
   tree0=None
   tree1=None
   tree2=None
   tree3=None
   tree4=None
   root=None
   root0=None
   root1=None
   root2=None
   root3=None
   root4=None

   baseXMLname=os.path.abspath(xmlfile).replace(basedir+"/","")
   langstr=os.path.basename(os.path.dirname(xmlout))
   if langstr[0:7] == 'values-':
       lang=langstr[7:]
   else:
       lang=""

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
                    elem=findItem(root,item,lang)
                    if elem is None:
                        root.append(item)
                except:
                    pass
        if os.path.exists(os.path.dirname(xmlout)+"/"+bbxml):
            tree3=ET.parse(os.path.dirname(xmlout)+"/"+bbxml)
            root3=tree3.getroot()
        bdictname=os.path.basename(xmldict).split("-")[len(f.split("-"))-1]
        bdictprefix=os.path.basename(xmldict).replace(bdictname,"")[:-1]
        if mode & modRefreshDict:
            ndict=os.path.dirname(xmldict)+"/"+bdictprefix+"-"+bbxml
        else:
            ndict=os.path.dirname(xmldict)+"/out/"+bdictprefix+"-"+bbxml
        if os.path.exists(ndict):
           tree4=ET.parse(ndict)
           root4=tree4.getroot()
           if root3 is None:
               root3=root4
           else:
               for item in root4:
                   try:
                       elem=findItem(root3,item,lang)
                       if elem is None:
                           root3.append(item)
                   except:
                       pass
   else:
        bdictname=os.path.basename(xmldict).split("-")[len(f.split("-"))-1]
        bdictprefix=os.path.basename(xmldict).replace(bdictname,"")[:-1]
        ndict=os.path.dirname(xmldict)+"/"+bdictprefix+"-cm_"+bdictname
        if os.path.exists(ndict):
            tree0=ET.parse(ndict)
            root0=tree0.getroot()
            for item in root0:
                try:
                    elem=findItem(root1,item,lang)
                    if elem is None:
                        root1.append(item)
                except:
                    pass


   indent(root,False)
   printedHead=0
   pos=0
   rootlen=len(root)
   while True:
           try:
                 child_of_root=root[pos]
           except:
               break
           
           removed=False

           if child_of_root is None:
              pos+=1
              continue

           ####not translate items#########
           if child_of_root.attrib.has_key("translatable") and (child_of_root.attrib['translatable'] == 'false') or child_of_root.attrib.has_key("translate") and (child_of_root.attrib['translate'] == 'false') :
               root.remove(child_of_root)
               continue

           #### in un-prefix cm_ xml
           if not root3 is None:
               elem3 = findItem(root3,child_of_root,lang)
               if not elem3 is None:
                   root.remove(child_of_root)
                   continue

           #### in dictionary
           try:
               elem = findItem(root1,child_of_root,lang,ignoreProduct=True)
           except:
               elem = None
    
           if not elem is None:
               root.remove(child_of_root);
               removed=True
               if not (elem.attrib.has_key("translatable") and (elem.attrib['translatable'] == 'false') or elem.attrib.has_key("translate") and (elem.attrib['translate'] == 'false')):
                   removed=False
                   root.insert(pos,elem)
           else:
               try:
                  elem2=findItem(root2,child_of_root,lang,ignoreProduct=True)
               except:
                  elem2=None

               if not elem2 is None:
                    root.remove(child_of_root);
                    removed=True
                    if not (elem2.attrib.has_key("translatable") and (elem2.attrib['translatable']== 'false') or elem2.attrib.has_key("translate") and (elem2.attrib['translate']== 'false')):
                        removed=False
                        root.insert(pos,elem2)
               else:
                    if not child_of_root is None and child_of_root.attrib.has_key("name"):
                        try:
                            if file_log is None:
                                file_log=open(dictdir+"/log.txt","w")
                            if printedHead == 0:
                                   print "\n",baseXMLname,":\n===================="
                                   print >> file_log, "\n",baseXMLname,":\n===================="
                                   printedHead = 1
                            print  "[X] ",child_of_root.attrib['name'], child_of_root.text.strip('\r\n \t')
                            print >> file_log,  "[X] ",child_of_root.attrib['name'], child_of_root.text.strip('\r\n \t')
                        except:
                            pass
                    else:
                        root.remove(child_of_root)
                        removed=True
           if not removed:
                indent(root[pos],True,1)
                pos+=1 
   try:
       root[pos-1].tail="\n"
   except:
       pass
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
    elif op == '|':
        break
    pos+=1

if j<3:
    files=os.listdir(dictdir)
    for s in files:
        langName=s
        if os.path.isdir(dictdir+"/"+s):
             dictlist=os.listdir(dictdir+"/"+s)
             for f in dictlist:
                  xmlname=f.split("-")[len(f.split("-"))-1]
                  xmlprefix=f.replace(xmlname,"")[:-1]
                  if xmlname[0:3] != "cm_" and os.path.isfile(f):
                       try:
                          cmpos=dictlist.index(xmlprefix+"-cm_"+xmlname)
                          mypos=dictlist.index(f)
                          if cmpos > mypos:
                              dictlist[mypos]=dictlist[cmpos]
                              dictlist[cmpos]=f
                       except:
                          pass 
             for f in dictlist:
                 xmlname=f.split("-")[len(f.split("-"))-1]
                 project=f.replace(xmlname,"")[:-1].replace("_","/")
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


