
import os, sys, time
from xml.etree import ElementTree as ET

# ------------------------------------------------------------------------------

class ModulesElementTree(ET.ElementTree):

   def __init__(self):
      ET.ElementTree.__init__(self, ET.Element("root"))


   def parseModulesDef(self, ifile):
      root = self.getroot()
      amounts = dict()
      tag_id_map = dict()
      modules_list = list()
      for line in ifile:
         stripped = line.strip().replace("\t", " ")
         if stripped and not stripped.startswith("#"):
            head, sep, tail = stripped.partition(" ")
            if sep != " ":
               self._string_error("No separating space:", line)

            value = tail.lstrip()
            unquoted = value.split('"')
            if len(unquoted) == 1:
               if value.find(" ") > 0:
                  self._string_error("Unquoted text:", line)

            elif len(unquoted) == 3:
               if len(unquoted[0]) == 0 and len(unquoted[2]) == 0:
                  value = unquoted[1]

               else:
                  self._string_error("Quotation in text:", line)

            else:
               self._string_error("Incorrect quotation:", line)

            tag_key, sep2, id = head.partition(",")
            tag, sep1, key = tag_key.partition("_")
            if sep1 == "_":
               if sep2 == ",":
                  tag_id = ",".join((tag, id))

                  element = tag_id_map.get(tag_id)
                  if element is None:
                     element = ET.Element(tag)
                     tag_id_map[tag_id] = element
                     element.attrib["ID"] = id

                  attrib = element.attrib
                  if key in attrib:
                     self._string_error("Repeated entry:", line)

                  else:
                     attrib[key] = value

               elif tag == "N":
                  if amounts.get(key):
                     self._string_error("Duplicated entry:", line)

                  elif not value.isdigit():
                     self._string_error("Numeric value expected:", line)

                  else:
                     amounts[key] = [int(value), 0]

               elif tag_key == "MODULE_LIST":
                  modules_list = self._split_line(value)

               else:
                  self._string_error("Unrecognised record", line)

            elif tag_key == "PROJECT":
               root.tag = value

            elif tag_key == "TITLE":
               root.attrib[tag_key] = value

            else:
               self._string_error("Unrecognised record", line)


      elements = tag_id_map.values()
      modules_map = dict()
      mod_tit_map = dict()
      for element in elements:
         occurance = amounts.get(element.tag + "S")
         if not occurance:
            self._element_error("Unrecognised element", element)

         else:
            name = element.get("NAME")
            module = element.get("MODULE")
            title = element.get("TITLE")
            key = None
            map = None
            if name and element.tag == "MODULE":
               key = name
               map = modules_map

            elif module and title:
               key = " ".join((module, title))
               map = mod_tit_map

            if not key:
               self._element_error("Ignoring:", element)

            else:
               occurance[1] += 1
               if key in map:
                  self._element_error("Element duplication", element)

               else:
                  map[key] = element


      print
      for tag, occurance in amounts.items():
         declared, actual = occurance
         print "No of %7s: %3d declared and %3d found" % (tag, declared, actual)


      for element in elements:
         attrib = element.attrib
         titles = self._split_line(attrib.pop("TASK_LIST", ""))
         if titles:
            module = attrib.get("MODULE")
            if element.tag == "MODULE":
               module = attrib.get("NAME")

            if not module:
               self._element_error("Missing TITLE or NAME:", element)

            else:
               for title in titles:
                  key = " ".join((module, title))
                  child = mod_tit_map.pop(key, None)
                  if child == None:
                     self._string_error("Undefined task in module %s:" %module, title)

                  else:
                     element.append(child)


      for element in mod_tit_map.values():
         self._element_error("Unreferenced task:", element)


      for module_name in modules_list:
         if not module_name.strip():
            root.append(ET.Element("SEPARATOR"))

         else:
            element = modules_map.pop(module_name, None)
            if element == None:
               self._string_error("Declared MODULE is not defined: ", module_name)

            else:
               root.append(element)


      self._add_indents(root, "\n")
      self._check_modules(root, None)
      print


   def _split_line(self, line):
      parts = line.split("{")
      words = parts[0].split()
      for part in parts[1:]:
         head, sep, tail = part.partition("}")
         words.append(head)
         words.extend(tail.split())

      return words


   def _add_indents(self, e0, t0):
      e0.tail = t0
      if len(e0) > 0:
         t1 = t0 + "   "
         e0.text = t1
         for e1 in e0:
            self._add_indents(e1, t1)

         e1.tail = t0


   def _check_modules(self, e0, m0):
      a0 = e0.attrib
      m1 = a0.pop("MODULE", a0.get("NAME"))
      if m0 and m0 != m1:
         self._element_error("MODULE attribute missmatch:", e0)

      for e1 in e0:
         self._check_modules(e1, m1)


   def _string_error(self, message, string):
      print
      print message
      print string


   def _element_error(self, message, element):
      print
      print message
      print ET.tostring(ET.Element(element.tag, element.attrib))


   def writeModulesDef(self, ofile):
      head_list = list()
      head_list.extend(("FOLDER_DESCRIPT", "FOLDER_MODULE", "FOLDER_NAME", "FOLDER_TASK_LIST", "FOLDER_TITLE",))
      head_list.extend(("MODULE_LIST", "MODULE_NAME", "MODULE_TASK_LIST", "MODULE_TITLE",))
      head_list.extend(("N_FOLDERS", "N_MODULES", "N_TASKS", "PROJECT",))
      head_list.extend(("TASK_DESCRIPT", "TASK_MODULE", "TASK_NAME", "TASK_TITLE","TITLE",))
      id_limit = 10000

      element_list = list()
      self._add_to_list(self.getroot(), None, None, element_list, id_limit)

      element_list.append(ET.Element("MODULE", ID="0", NAME="", TITLE="", TASK_LIST=""))
      element_list.append(ET.Element("FOLDER", ID="0", NAME="", TITLE="", DESCRIPT="", MODULE="", TASK_LIST=""))
      element_list.append(ET.Element("TASK", ID="0", NAME="", TITLE="", DESCRIPT="", MODULE=""))

      element_list.sort(lambda x, y: cmp(int(x.get("ID")), int(y.get("ID"))))

      tag_counts = dict(MODULE=-1, FOLDER=-1, TASK=-1)
      moddef_list = list()
      moddef_list.append((head_list.index("PROJECT"), id_limit, "CCP4"))
      for element in element_list:
         tag = element.tag
         id = id_limit
         if tag in tag_counts:
            id = tag_counts[tag] + 1
            tag_counts[tag] = id

         for key, value in element.attrib.items():
            if key != "ID":
               head = "_".join((tag, key))
               if tag == "CCP4":
                  head = key

               if not head in head_list:
                  self._element_error("Element implies unspecified record %s:" %head, element)

               else:
                  moddef_list.append((head_list.index(head), id, value))


      for tag, count in tag_counts.items():
         head = "N_%sS" %tag
         if head in head_list:
            moddef_list.append((head_list.index(head), id_limit, str(count)))

      moddef_list.sort(lambda x, y: cmp((1 + id_limit)* x[0] + x[1], (1 + id_limit)* y[0] + y[1]))

#     ofile.write("#CCP4I DATE 13 Sep 2011  16:44:45\n")
      ofile.write(time.strftime("#CCP4I DATE %d %b %Y  %H:%M:%S\n", time.localtime(time.time())))
      ofile.write("#CCP4I SCRIPT DEF modules\n")
      ofile.write("#CCP4I USER %s\n" %os.environ.get("USER", "unknown"))
      ofile.write("#CCP4I VERSION CCP4Interface 2.2.1\n")
      for ind, id, value in moddef_list:
         key = head_list[ind]
         if id < id_limit:
            key = "%s,%d" %(key, id)

         if not value or value.find(" ") > 0:
               value = "\"%s\"" %value

         ofile.write("%-25s %s\n" %(key, value))

      ofile.write("\n")
      print


   def _add_to_list(self, e0, m0, k0, element_list, id_limit):
      if not e0.tag.strip():
         self._element_error("Missing tag:", e0)
         return

      id = e0.get("ID", str(id_limit))
      if not id.isdigit():
         self._element_error("Non-integer ID:", e0)
         return

      e0.attrib["ID"] = id

      is_ccp4 = e0.tag == "CCP4"
      is_module = e0.tag == "MODULE"
      is_folder = e0.tag == "FOLDER"
      is_task = e0.tag == "TASK"
      is_separator = e0.tag == "SEPARATOR"

      m1 = m0
      if is_module:
         m1 = e0.get("NAME", "")

      k1 = None
      if is_ccp4 or is_module or is_folder:
         k1 = list()

      if is_module or is_folder or is_task:
         key = e0.get("TITLE").strip()
         if is_module:
            key = e0.get("NAME").strip()

         if not key:
            self._element_error("Missing TITLE:", element)

         else:
            if key.find(" ") > 0:
               key = "{%s}" %(key)

            k0.append(key)

      if is_separator:
         k0.append("{}")

      for e1 in e0:
         self._add_to_list(e1, m1, k1, element_list, id_limit)

      element = ET.Element(e0.tag)
      element.attrib.update(e0.attrib)
      if is_ccp4:
         element.attrib["MODULE_LIST"] = " ".join(k1)

      if is_module or is_folder:
         element.attrib["TASK_LIST"] = " ".join(k1)

      if is_folder or is_task:
         element.attrib["MODULE"] = m0

      element.tail = "\n"
      element_list.append(element)

# ------------------------------------------------------------------------------

if __name__ == '__main__':

   print
   argmap = dict()
   for key, value in zip(sys.argv[1::2], sys.argv[2::2]):
      value = os.path.abspath(value)
      print "%-9s %s" %(key + ":", value)
      argmap[key.lower()] = value

   defin = argmap.get("defin")
   xmlin = argmap.get("xmlin")
   defout = argmap.get("defout")
   xmlout = argmap.get("xmlout")
   if defin and xmlin or not defin and not xmlin:
      print "   usage:"
      print "   python modules_def_xml.py defin in.def [defout <out.def>] [xmlout <out.xml>]"
      print "   or:"
      print "   python modules_def_xml.py xmlin in.xml [defout <out.def>] [xmlout <out.xml>]"
      print
      print "   Do NOT define any ID attribute when adding new elements to XMLIN to preserve existing numbering"
      print

   else:
      tree = ModulesElementTree()
      if defin:
         with open(defin) as ifile:
            tree.parseModulesDef(ifile)

      elif xmlin:
         with open(xmlin) as ifile:
            tree.parse(ifile)

      if defout:
         with open(defout, "w") as ofile:
            tree.writeModulesDef(ofile)

      elif xmlout:
         with open(xmlout, "w") as ofile:
            tree.write(ofile)

# ------------------------------------------------------------------------------

