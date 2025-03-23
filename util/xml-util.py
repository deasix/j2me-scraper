#!/usr/bin/python3
#
# a flexible xml utility script originally designed to manipulate 
# emulationstation configuration file but can be adapted for other purposes

import xml.etree.ElementTree as ET
import sys
import os

def create(filename, root_tag):
    root = ET.Element(root_tag)
    root.text = "\n"
        
    tree = ET.ElementTree(root)
    ET.indent(tree, space="\t", level=0)
    tree.write(filename, encoding="utf-8", xml_declaration=True)

def search(root, match_tag, search_tag=None, search_val=None):
    if root.tag == match_tag:
        return root
        
    for element in root.findall(match_tag):
    
        # return first element
        if not search_tag or not search_val:
            return element
        
        # match first before returning
        match = element.find(search_tag)
        if match is not None and match.text == search_val:
            return element

# insert values
def insert(filename, parent_tag, insert_tag, insert_val, search_tag=None, search_val=None):
    tree = ET.parse(filename)
    root = tree.getroot()
    
    # search parent tag
    parent = search(root, parent_tag, search_tag, search_val)
    
    # insert values
    if parent is not None:
        child = parent.find(insert_tag)
        
        # create or update tag value
        if child is None or not search_tag or not search_val:
            child = ET.SubElement(parent, insert_tag)
        
        # parse as xml, otherwise plain text
        try:
            sub_element = ET.fromstring(insert_val)
            child.append(sub_element)
        except ET.ParseError:
            child.text = insert_val
            
    tree = ET.ElementTree(root)
    ET.indent(tree, space="\t", level=0)
    tree.write(filename, encoding="utf-8", xml_declaration=True)
    
if __name__ == "__main__":
    
    # guard
    size = len(sys.argv)
    if size < 3 or size == 4 or size == 6 or size > 7:
        print("Invalid number of parameters.")
        sys.exit(1)
    
    # params
    filename = sys.argv[1]
    parent_tag = sys.argv[2]
    
    # params | insert
    if size > 3 and size <= 5:
        insert(filename, parent_tag, sys.argv[3], sys.argv[4])
        sys.exit()
        
    # params | insert with search
    if size > 5 and size <= 7:
        insert(filename, parent_tag, sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
        sys.exit()
    
    # default method
    create(filename, parent_tag)
