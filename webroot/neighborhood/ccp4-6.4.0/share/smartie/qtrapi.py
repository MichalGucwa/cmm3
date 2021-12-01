
import os, sys, time
from xml.etree import ElementTree as ET

# ------------------------------------------------------------------------------

xrtns = "{http://www.ccp4.ac.uk/xrt}%s"
job_tag = "Job"
job_path = "/Job"


class Report(list):

   def __init__(self, title="Untitled", path=None):
      report = os.path.join(path, "report")
      self.xml = report + ".xml"
      self.xrt = report + ".xrt"
      self.title = title

   def flush(self):
      self.xrttree = ET.ElementTree(ET.Element("report"))
      e0 = self.xrttree.getroot()
      e0.text = "\n"
      e0.tail = "\n"
      e0 = ET.SubElement(e0, xrtns %"results")
      e0.text = "\n\n"
      e0.tail = "\n"

      self.xmltree = ET.ElementTree(ET.Element(job_tag))
      f0 = self.xmltree.getroot()
      f0.text = "\n"
      f0.tail = "\n"

      e1 = ET.SubElement(e0, xrtns %"title", select=job_path + "/Title")
      e1.tail = "\n"
      e1.tail = "\n\n"

      f1 = ET.SubElement(f0, "Title")
      f1.text = self.title
      f1.tail = "\n"
      f1.tail = "\n"

      for element in self:
         element.flush_into(e0, f0)

      self.xmltree.write(self.xml)
      ofile = open(self.xrt, "w")
      ofile.write(ET.tostring(self.xrttree.getroot()).replace("ns0", "xrt"))
      ofile.close()


class Section(list):
   cou = 0

   def __init__(self, title="Untitled"):
      Section.cou += 1
      self.cou = Section.cou
      self.title = title
      self.tag = "SubJob_%03d" %self.cou
      self.path = job_path + "/" + self.tag

   def flush_into(self, e0, f0):
      e1 = ET.SubElement(e0, xrtns %"section", title=self.title)
      e1.text = "\n"
      e1.tail = "\n\n"

      for element in self:
         element.flush_into(e1, f0)


class Text(list):
   cou = 0

   def __init__(self, title="Untitled", folded=False):
      Text.cou += 1
      self.cou = Text.cou
      self.title = title
      self.tag = "KeyText_%03d" %self.cou
      self.path = job_path + "/" + self.tag
      self.folded = "false"
      if folded:
         self.folded = "true"

   def flush_into(self, e1, f1):
      keytext = "\n".join(self)
      e2 = ET.SubElement(e1, xrtns %"keytext")
      e2.attrib["folded"] = self.folded
      e2.attrib["name"] = self.title
      e2.attrib["select"] = self.path
      e2.tail = "\n"

      f2 = ET.SubElement(f1, self.tag)
      f2.text = "\n" + keytext + "\n"
      f2.tail = "\n"


class Table(list):
   cou = 0

   def __init__(self, title="Untitled", folded="false"):
      Table.cou += 1
      self.cou = Table.cou
      self.title = title
      self.folded = folded
      self.tag = "Table_%03d" %self.cou
      self.path = job_path + "/" + self.tag

   def flush_into(self, e1a, f1):
      e2 = ET.SubElement(e1a, xrtns %"table", select=self.path)
      e2.attrib["title"] = self.title
      e2.text = "\n\n"
      e2.tail = "\n\n"
      e2.attrib["folded"] = self.folded

      for column in self:
         e3 = ET.SubElement(e2, xrtns %"data", title=column.title)
         e3.attrib["select"] = column.tag + "/" + column.cell_tag
         e3.tail = "\n"

      f2 = ET.SubElement(f1, self.tag)
      f2.text = "\n"
      f2.tail = "\n"

      for element in self:
         element.flush_into(e2, f2)


class Column(list):
   cou = 0
   cell_tag = "D"

   def __init__(self, title=""):
      Column.cou += 1
      self.cou = Column.cou
      self.title = title
      self.tag = "Column_%03d" %self.cou

   def flush_into(self, e1a, f1):
      f2 = ET.SubElement(f1, self.tag)
      f2.text = ""
      f2.tail = "\n"

      for element in self:
         f3 = ET.SubElement(f2, self.cell_tag)
         f3.text = str(element)
         f3.tail = ""


class Graph(list):

   def __init__(self, title="Untitled", ymin=0):
      self.title = title

   def flush_into(self, e1, f1):
      e1a = ET.SubElement(e1, xrtns %"graph")
      e1a.text = "\n\n"
      e1a.tail = "\n\n\n"

      for element in self:
         element.flush_into(e1a, f1)


class PlotTable(list):
   cou = 0

   def __init__(self, title="Untitled", table=None):
      PlotTable.cou += 1
      self.cou = PlotTable.cou
      self.title = title
      self.table = table
      self.tag = "PlotTable_%03d" %self.cou
      self.path = job_path + "/" + self.tag

   def flush_into(self, e1a, f1):
      e2 = ET.SubElement(e1a, xrtns %"table", select=self.path)
      e2.attrib["title"] = self.title
      e2.text = "\n\n"
      e2.tail = "\n\n"

      for column in self.table:
         e3 = ET.SubElement(e2, xrtns %"data", title=column.title)
         e3.attrib["select"] = column.tag + "/" + column.cell_tag
         e3.tail = "\n"

      for element in self:
         element.flush_into(e2, f1)

      f2 = ET.SubElement(f1, self.tag)
      f2.text = "\n"
      f2.tail = "\n"

      for element in self.table:
         element.flush_into(e2, f2)


class Plot(list):

   def __init__(self, title="Untitled", xmin=None, xmax=None, ymin=None, ymax=None):
      self.title = title
      self.xmin = xmin
      self.xmax = xmax
      self.ymin = ymin
      self.ymax = ymax

   def flush_into(self, e2, f1):
      e3 = ET.SubElement(e2, xrtns %"plot")
      e3.attrib["title"] = self.title
      e3.text = "\n"
      e3.tail = "\n\n"
      if self.xmin != None:
         e3.attrib["xmin"] = str(self.xmin)

      if self.xmax != None:
         e3.attrib["xmax"] = str(self.xmax)

      if self.ymin != None:
         e3.attrib["ymin"] = str(self.ymin)

      if self.ymax != None:
         e3.attrib["ymax"] = str(self.ymax)

      for element in self:
         element.flush_into(e3, f1)


class Line(list):

   def __init__(self, xcol=0, ycol=1, colour="auto"):
      self.xcol = xcol
      self.ycol = ycol
      self.colour = colour

   def flush_into(self, e3, f1):
      e4 = ET.SubElement(e3, "plotline", xcol=str(self.xcol), ycol=str(self.ycol), colour=self.colour)
      e4.tail = "\n"


class Files(list):

   def flush_into(self, e1, f1):
      e1a = ET.SubElement(e1, xrtns %"files")
      e1a.text = "\n"
      e1a.tail = "\n"

      for element in self:
         element.flush_into(e1a, f1)


class File(list):
   cou = 0

   def __init__(self, title="Untitled", type="text", key="LOG", path=None):
      File.cou += 1
      self.cou = File.cou
      self.title = title
      self.type = type
      self.key = key
      self.path = path
      self.tag = "File_%03d" %self.cou
      self.xml_path = job_path + "/" + self.tag

   def flush_into(self, e2, f1):
      if self.path:
         exists = False
         if self.key.startswith("STRUCTURE"):
            exists =  os.path.isfile(self.path + ".pdb") and os.path.isfile(self.path + ".mtz")

         else:
            exists =  os.path.isfile(self.path)

         if exists:
            e3 = ET.SubElement(e2, xrtns %"file", key=self.key, type=self.type, select=self.xml_path)
            e3.tail = "\n"
            if self.title:
               e3.attrib["title"] = self.title

            always_folded = ["RESTRAINT_HTML"]
            if self.key in always_folded:
               e3.attrib["folded"] = "always"

            f2 = ET.SubElement(f1, self.tag, path=self.path)
            f2.tail = "\n"

# ------------------------------------------------------------------------------

