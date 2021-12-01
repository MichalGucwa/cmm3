# class to store a single node in an XML data structure
class XMLnode:
 TEXT, TAG = 1, 2

 def __init__( self, text=None, name=None, attributes=None, children=None ):
   if   text != None and name == None:
     if type(text) != type(""):
       raise StandardError( "XMLnode __init__ error: text " + str(text) )
     self.text = text
     self.name = None
   elif text == None and name != None:
     if type(name) != type(""):
       raise StandardError( "XMLnode __init__ error: name " + str(name) )
     self.text = None
     self.name = name
     self.attributes = []
     self.children = []
     if attributes != None:
       self.attributes = attributes
     if children != None:
       self.children = children
   else:
     raise StandardError( "XMLnode __init__ error: must be text or tag" )

 def attribute( self, name ):
   result = False
   for attr in self.attributes:
     if attr[0] == name:
       if attr[1] != None:
         if type(result) != type(""):
           result  = attr[1]
         else:
           result += attr[1]
       else:
         result = True
   return result

 def type( self ):
   if self.text != None:
     return self.TEXT
   if self.name != None:
     return self.TAG
   return None

 #@staticmethod
 def text( name, text ):
   return XMLnode( name=name, children=[ XMLnode( text=text ) ] )
 text=staticmethod(text)

class XML:
 def __init__( self, text ):
   self.data = XMLnode( name="" )
   self.xml_parse( text, self.data )

 # extract text from xml
 #@staticmethod
 def xml_text( node ):
   result = ""
   if node.type() == XMLnode.TEXT:
     result = node.text
   else:
     for item in node.children:
       result += XML.xml_text( item )
   return result
 xml_text=staticmethod(xml_text)

 # simple xml to text
 #@staticmethod
 def xml_dump( node ):
   result = ""
   if node.type() == XMLnode.TEXT:
     result = node.text
   else:
     content = node.name
     for attr in node.attributes:
       if attr[1] == None:
         content += " "+attr[0]
       else:
         content += " "+attr[0]+"='"+attr[1]+"'"
     if len(node.children) > 0:
       if content != "":
         result += "<"+content+">"
       for item in node.children:
         result += XML.xml_dump( item )
       if content != "":
         result += "</"+node.name+">\n"
     else:
       result += "<"+content+"/>"
   return result
 xml_dump=staticmethod(xml_dump)

 # parse an xml text file into a nested list of elements
 # result is a list of XMLnodes
 def xml_parse( self, data, node, index=0 ):
   while (1):
     # deal with text segments
     iopen1 = data.find( "<", index )
     if iopen1 < 0:
       break
     s = data[index:iopen1]
     if len(s) > 0:
       node.children.append( XMLnode( text=s ) )
     # deal with tags
     iclose1 = data.find( ">", iopen1+1 )
     if iclose1 < 0:
       raise StandardError( "XML unclosed tag: "+data[iopen1,iopen1+40] )
     content = data[iopen1+1:iclose1]
     # deal with close tags
     if content[:1] == "/":
       return iopen1
     # deal with special tags
     elif content[:1] == "?":
       if content[-1:] != "?":
         raise StandardError( "XML invalid special: <"+content+">" )
       index = iclose1+1
     # deal with comment tags
     elif content[:3] == "!--":
       if content[-2:] != "--":
         raise StandardError( "XML invalid comment: <"+content+">" )
       index = iclose1+1
     # deal with tags
     else:
       closed = ( content[-1:] == "/" )
       content = content.strip( "/" )
       csplit = content.split( None, 1 ) + ["",""]
       tag, atts = csplit[0], csplit[1]
       # get attributes
       attlist = []
       iattr = 0
       while iattr < len(atts):
         iname = iattr
         while iattr < len(atts) and  not( atts[iattr].isspace() or
                                           atts[iattr] == "=" ):
           iattr += 1
         aname = atts[iname:iattr]
         if iattr == len(atts) or atts[iattr] != "=":
           attlist.append((aname,None))
         else:
           ibeg = iattr+1
           q = atts[ibeg]
           if q != "'" and q != '"':
             raise StandardError( "XML unopened quote: <"+attr+">" )
           iend = atts.find( q, ibeg+1 )
           if iend < 0:
             raise StandardError( "XML unclosed quote: <"+attr+">" )
           aval = atts[ibeg+1:iend]
           attlist.append((aname,aval))
           iattr = iend+1
         while iattr < len(atts) and atts[iattr].isspace():
           iattr += 1
       # create node
       cnode = XMLnode( name=tag, attributes=attlist )
       if closed:
         index = iclose1+1
       else:
         index = self.xml_parse( data, cnode, iclose1+1 )
         closetag = "</"+tag+">"
         if data[index:index+len(closetag)] != closetag:
           raise StandardError( "XML missing close tag: "+closetag )
         index = index+len(closetag)
       node.children.append( cnode )
   # deal with trailing text
   s = data[index:]
   if len(s) > 0:
     node.children.append( XMLnode( text=s ) )
   return len(data)

 def xpath( self, path, base=None ):
   if base == None:
      base = self.data
   if type(path) != type("") or type(base) != type(self.data):
     raise StandardError( "XML invalid xpath arguments: "+str(path)+str(base) )
   if path == "":
     return base
   xpath = path.split( "/" )
   if xpath[0] == "":
     return self.xpath( "/".join( xpath[1:] ), self.data )
   if xpath[0] == ".":
     return self.xpath( "/".join( xpath[1:] ), base )
   if xpath[0] == "..":
     return self.xpath( "/".join( xpath[1:] ), self.parent_of( base ) )
   if base.type() == XMLnode.TAG:
     name,index = xpath[0],1
     if name.find("[") >= 0:
       i1,i2 = name.find("["),name.rfind("]")
       index = int(name[i1+1:i2])
       name = name[:i1]
     for node in base.children:
       if node.name == name:
         if index == 1:
           return self.xpath( "/".join( xpath[1:] ), node )
         else:
           index -= 1
   return None

 def xpath_list( self, path, base=None ):
   if base == None:
      base = self.data
   if type(path) != type("") or type(base) != type(self.data):
     raise StandardError( "XML invalid xpath arguments: "+str(path)+str(base) )
   if path == "":
     return [ base ]
   xpath = path.split( "/" )
   if xpath[0] == "":
     return self.xpath_list( "/".join( xpath[1:] ), self.data )
   if xpath[0] == ".":
     return self.xpath_list( "/".join( xpath[1:] ), base )
   if xpath[0] == "..":
     return self.xpath_list( "/".join( xpath[1:] ), self.parent_of( base ) )
   result = []
   if base.type() == XMLnode.TAG:
     for node in base.children:
       if node.name == xpath[0]:
         result += self.xpath_list( "/".join( xpath[1:] ), node )
   return result

 def parent_of( self, target, node=None ):
   if node == None:
     node = self.data
   if node.type() == XMLnode.TAG:
     for cnode in node.children:
       if cnode is target:
         return node
     for cnode in node.children:
       result = self.parent_of( target, cnode )
       if result != None:
         return result
   return None

 # get the contents of an xpath
 def get( self, path, base=None ):
   if base == None:
     base = self.data
   node = self.xpath( path )
   if node != None:
     return XML.xml_text( node )
   return ""

 # set the contents of an xpath
 def set( self, path, text, base=None ):
   if base == None:
     base = self.data
   cnode = XMLnode( text=text )
   node = self.xpath( path )
   if node == None:
     paths = path.split("/")
     pathh = "/".join( paths[:-1] )
     node = self.xpath( pathh )
     node.children.append( XMLnode( name=paths[-1], children=[cnode] ) )
   else:
     node.children = [cnode]

 # evaluate an xsl condition from a given node in an xml document
 def xsl_condition( self, condition, node=None ):
   if node == None:
     node = self.data
   # split of quoted strings
   tok1 = []
   quot = ""
   current = ""
   for c in condition:
     if quot == "":
       if c == '"' or c == "'":
         tok1.append(current)
         current = ""
         quot = c
       else:
         current += c
     else:
       if c == quot:
         tok1.append('"""'+current+'"""')
         current = ""
         quot = ""
       else:
         current += c
   if current != "": tok1.append(current)
   # split the rest
   tok2 = []
   for tok in tok1:
     if tok[0] != '"':
       current = ""
       i = 0
       while i < len(tok):
         if tok[i] == " ":
           if current != "":
             if current != "": tok2.append(current)
             current = ""
           i+=1
         elif tok[i] == "(" or tok[i] == ")":
           if current != "": tok2.append(current)
           tok2.append(tok[i])
           current = ""
           i+=1
         elif tok[i] == "=":
           if current != "": tok2.append(current)
           tok2.append("==")
           current = ""
           i+=1
         elif tok[i:i+2] == "!=":
           if current != "": tok2.append(current)
           tok2.append("!=")
           current = ""
           i+=2
         elif tok[i:i+5] == "&gt;=":
           if current != "": tok2.append(current)
           tok2.append(">=")
           current = ""
           i+=4
         elif tok[i:i+5] == "&lt;=":
           if current != "": tok2.append(current)
           tok2.append("<=")
           current = ""
           i+=4
         elif tok[i:i+5] == "&lt;":
           if current != "": tok2.append(current)
           tok2.append(">")
           current = ""
           i+=3
         elif tok[i:i+5] == "&lt;":
           if current != "": tok2.append(current)
           tok2.append("<")
           current = ""
           i+=3
         else:
           current += tok[i]
           i+=1
       if current != "": tok2.append(current)
     else:
       tok2.append( tok )
   # evaluate xpaths
   tok3 = []
   for tok in tok2:
     if ( ( tok[0].isalpha() or tok[0] == "/" or tok[0] == "." ) and
          ( tok != "not" and tok != "and" and tok != "or" ) ):
       node = self.xpath( tok, node )
       if node != None:
         val = XML.xml_text( node )
         if val != "":
           tok3.append( '"""'+XML.xml_text( node )+'"""' )
         else:
           tok3.append( 'True' )
       else:
         tok3.append( '""' )
     else:
       tok3.append( tok )
   # turn into python expr and evaluate
   expr = " ".join( tok3 )
   return eval( expr )

 # parse xslt, returning a string, based on xsl and xml data structures
 def xsl_parse( self, xslnode, xmlnode=None ):
   if xmlnode == None:
     xmlnode = self.data    
   result = ""
   for xslchild in xslnode.children:
     # insert simple text
     if   xslchild.type() == XMLnode.TEXT:
       if len(xslchild.text.strip()) != 0:
         result += xslchild.text
     # otherwise interpret tags
     else:
       # handle xsl:text
       if xslchild.name == "xsl:text":
         if len(xslchild.children) == 1:
           if xslchild.children[0].type() == XMLnode.TEXT:
             result += xslchild.children[0].text
           else:
             raise StandardError( "XSL invalid xsl:text: "+str(xslchild) )
         else:
           raise StandardError( "XSL invalid xsl:text: "+str(xslchild) )
       # handle xsl:value-of
       elif xslchild.name == "xsl:value-of":
         val = xslchild.attribute( "select" )
         if type(val) == type(""):
           vnode = self.xpath( val, xmlnode )
           if vnode != None:
             result += XML.xml_text( vnode )
         else:
           raise StandardError( "XSL invalid xsl:value-of: "+str(xslchild) )
       # handle xsl:if
       elif xslchild.name == "xsl:if":
         val = xslchild.attribute( "test" )
         if type(val) == type(""):
           if self.xsl_condition( val, xmlnode ):
             result += self.xsl_parse( xslchild, xmlnode )
         else:
           raise StandardError( "XSL invalid xsl:if: "+str(xslchild) )
       # handle xsl:for-each
       elif xslchild.name == "xsl:for-each":
         val = xslchild.attribute( "select" )
         if type(val) == type(""):
           xmlfornodes = self.xpath_list( val, xmlnode )
           for xmlfornode in xmlfornodes:
             result += self.xsl_parse( xslchild, xmlfornode )
         else:
           raise StandardError( "XSL invalid xsl:for-each: "+str(xslchild) )
       # ignore other tags
       else:
         result += self.xsl_parse( xslchild, xmlnode )
   return result


# Template language class
# Implements a simplified template language which translates to a
# subset of xsl.
class Template( XML ):
 def __init__( self, text ):
   self.data = XMLnode( name="" )
   self.template_parse( text, self.data )

 # parse a ccp4 template text file into a nested list of elements
 # result is a list of XMLnodes
 def template_parse( self, data, node, index=0 ):
   while (1):
     # deal with text segments
     iopen1 = data.find( "<", index )
     if iopen1 < 0:
       break
     s = data[index:iopen1]
     if len(s) > 0:
       node.children.append( XMLnode( name="xsl:text",
                                      children=[XMLnode( text=s )] ) )
     # deal with tags
     iclose1 = data.find( ">", iopen1+1 )
     if iclose1 < 0:
       raise StandardError( "Template unclosed tag: "+data[iopen1,iopen1+40] )
     content = data[iopen1+1:iclose1]
     # deal with close tags
     if content[0] == "/":
       return iopen1
     # deal with special tags
     elif content[0] == "?":
       if content[-1] != "?":
         raise StandardError( "Template invalid special: <"+content+">" )
       index = iclose1+1
     # deal with comment tags
     elif content[:3] == "!--":
       if content[-2:] != "--":
         raise StandardError( "Template invalid comment: <"+content+">" )
       index = iclose1+1
     # deal with expression tags
     elif content[0] == "=":
       path = content.strip( "/=" ).strip()
       cnode = XMLnode( name="xsl:value-of", attributes=[("select",path)] )
       node.children.append( cnode )
       index = iclose1+1
     # deal with if tags
     elif content[:2] == "if":
       test = content[2:].strip()
       cnode = XMLnode( name="xsl:if", attributes=[("test",test)] )
       index = self.template_parse( data, cnode, iclose1+1 )
       node.children.append( cnode )
       closetag = "</if>"
       if data[index:index+5] != "</if>":
         raise StandardError( "Template missing close tag: "+data[index:index+40] )
       index = index+5
     # deal with if tags
     elif content[:7] == "foreach":
       path = content[7:].strip()
       cnode = XMLnode( name="xsl:for-each", attributes=[("select",path)] )
       index = self.template_parse( data, cnode, iclose1+1 )
       node.children.append( cnode )
       closetag = "</foreach>"
       if data[index:index+10] != "</foreach>":
         raise StandardError( "Template missing close tag: "+data[index:index+40] )
       index = index+10
     # deal with tags
     else:
       closed = ( content[-1] == "/" )
       content = content.strip( "/" )
       csplit = content.split( None, 1 )
       tag = csplit[0]
       attlist = []
       cnode = XMLnode( name=tag, attributes=attlist )
       if closed:
         index = iclose1+1
       else:
         index = self.template_parse( data, cnode, iclose1+1 )
         closetag = "</"+tag+">"
         if data[index:index+len(closetag)] != closetag:
           raise StandardError( "Template missing close tag: "+closetag )
         index = index+len(closetag)
       node.children.append( cnode )
   # deal with trailing text
   s = data[index:]
   if len(s) > 0:
     node.children.append( XMLnode( name="xsl:text",
                                    children=[XMLnode( text=s )] ) )
   return len(data)


class Control:
 def __init__( self ):
   self.status = 0
   self.stdin  = ''
   self.stdout = ''
   self.stderr = ''
   self.trap_errors( True )
   self.params_inp = []
   self.params_def = []

 def trap_errors( self, flag ):
   self.error = flag

 def parse_input( self, keyworddata ):
   import sys
   input = []
   # extract the keyword data
   keyxml = XML( keyworddata )
   # get input from command line
   for item in sys.argv[1:]:
     if item[:1] == "-":
       name = item.lstrip("-")
       input.append( [name,""] )
     else:
       if len(input) == 0:
         input.append( ["",""] )
       if input[-1][1] == "":
         input[-1][1] = item
       else:
         input[-1][1] += " "+item
   # get input from stdin if required
   if len(input) > 0 and input[-1][0] == "stdin":
     input.pop()
     s = sys.stdin.readlines()
     for line in s:
       if line[:1] != "#":
         w = line.split( None, 1 ) + [""]
         if ( len(line) > 1 ):
           input.append( w[0:2] )
   # check against valid keywords
   input_error = ( len(input) == 0 )
   msg = "INPUT ERROR:\n"
   keywords = keyxml.xpath_list( "key" )
   keycount = [0]*len(keywords)
   for i in range(len(input)):
     key,val = input[i]
     val = val.strip()
     keyindex = -1
     for k in range(len(keywords)):
       if key == keywords[k].attribute("name"):
         keyindex = k
     if keyindex >= 0:
       keycount[keyindex] += 1
       if   keywords[keyindex].attribute("int"):
         try:
           x = int(val)
         except:
           msg += "Keyword '"+key+"' takes integer, got '"+val+"'\n"
           input_error = True
       elif keywords[keyindex].attribute("float"):
         try:
           x = float(val)
         except:
           msg += "Keyword '"+key+"' takes decimal, got '"+val+"'\n"
           input_error = True
       elif keywords[keyindex].attribute("bool"):
         if ( val != "" and val != "0" and val != "1" and
              val.lower() != "true" and val.lower() != "false" ):
           msg += "Keyword '"+key+"' takes logical, got '"+val+"'\n"
           input_error = True
       elif keywords[keyindex].attribute("text"):
         if val == None or val == "":
           msg += "Keyword '"+key+"' takes text, got nothing\n"
           input_error = True
       else:
         if val != "":
           msg += "Keyword '"+key+"' takes no value\n"
           input_error = True
     else:
       msg += "Unrecognized keyword: '"+key+"'\n"
       input_error = True
     input[i] = [key,val,keyindex]
   # check number of keywords
   defaults = []
   for k in range(len(keywords)):
     key = keywords[k].attribute("name")
     count = keycount[k]
     if keywords[k].attribute("compulsory") and count < 1:
       msg += "Keyword '"+key+"' must appear at least once.\n"
       input_error = True
     if not keywords[k].attribute("multiple") and count > 1:
       msg += "Keyword '"+key+"' must appear at most once.\n"
       input_error = True
     if keywords[k].attribute("default") and count == 0:
       defval = keywords[k].attribute("default")
       defaults.append( [key,defval,k] )
   # store input and defaults
   for i in input:
     self.params_inp.append( [i[0],i[1]] )
   for i in defaults:
     self.params_def.append( [i[0],i[1]] )
   # assemble final input
   input += defaults
   # documentation for errors or null input
   if input_error:
     sys.stderr.write( msg )
     sys.stderr.write( """
Keywords:
 Keywords may be given on the command line by preceding them with "-",
 or on standard input by first giving the -stdin command line switch.

 [!] = Compulsory    [*] = Can appear multiple times 

Known keywords:
""" )
     for k in range(len(keywords)):
       key = keywords[k].attribute("name")
       typ = ""
       if   keywords[k].attribute("int"):
         typ = "<integer>"
       elif keywords[k].attribute("float"):
         typ = "<decimal>"
       elif keywords[k].attribute("text"):
         typ = "<text>"
       mod = ""
       if ( keywords[k].attribute("compulsory") and
            keywords[k].attribute("multiple") ):
         mod = "[!*] "
       elif keywords[k].attribute("compulsory"):
         mod = "[!] "
       elif keywords[k].attribute("multiple"):
         mod = "[*] "
       doc = XML.xml_text( keywords[k] )
       sys.stderr.write( "  %-40s %-5s %-30s\n"%(key+" "+typ,mod,doc) )
     sys.stderr.write( "\n" )
     raise( StandardError( 'Fail in command input.' ) )
   # convert to XML
   self.xml = XML("")
   for item in input:
     key,val,keyindex = item
     if   keywords[keyindex].attribute("list"):
       node0 = XMLnode( name=key )
       head = tail = ""
       i = val.find("[")
       if i >= 0:
         head,val = val[:i+1],val[i+1:]
       i = val.rfind("]")
       if i >= 0:
         val,tail = val[:i],val[i:]
       vals = val.split(',')
       if head != "":
         node0.children.append( XMLnode( text=head ) )
       if len(vals) > 0:
         for v in vals[:-1]:
           node1 = XMLnode( text=v )
           node0.children.append( XMLnode( name="list", children=[node1] ) )
           node0.children.append( XMLnode( text="," ) )
         node1 = XMLnode( text=vals[-1] )
         node0.children.append( XMLnode( name="list", children=[node1] ) )
       if tail != "":
         node0.children.append( XMLnode( text=tail ) )
       self.xml.data.children.append( node0 )
     elif keywords[keyindex].attribute("bool"):
       if   val         == "":      val = "1"
       elif val.lower() == "true":  val = "1"
       elif val.lower() == "false": val = "0"
       node1 = XMLnode( text=val )
       node0 = XMLnode( name=key, children=[node1] )
       self.xml.data.children.append( node0 )
     else:
       node1 = XMLnode( text=val )
       node0 = XMLnode( name=key, children=[node1] )
       self.xml.data.children.append( node0 )
   return self.xml

 def run_program( self, *data ):
   import os, sys
   if sys.version_info >= (2,4,0): 
      import subprocess
   else:
      subprocess = __import__("subprocess_with_fixes")
   if len(data) == 1:
     assert len(data[0]) == 3
     prgm, args, cmds = data[0]
   else:
     assert len(data) == 3
     prgm, args, cmds = data
   bin = os.path.join( os.environ['CCP4'], 'bin', prgm )
   if ( not os.path.exists( bin ) ):
     bin = prgm  # if binary isn't in CBIN, assume absolute or path
   # start of windows compatibility code
   if ( os.name == 'NT' ):
     bin = bin.strip() + '.exe'
     bin.replace( '\\\\', '/' )
     args.replace( '\\\\', '/' )
     cmds.replace( '\\\\', '/' )
   # end of windows comatibility code
   self.stdin += '\n'+prgm+' '+args+' << "eof"\n'+cmds+'"eof"\n\n'
   # launch the program
   arglist = [bin] + args.split()
   # if running on windows supress the spawning of empty consoles when 
   # subprocessing an executable
   if os.name == "nt":
      info=subprocess.STARTUPINFO()
      info.dwFlags |= subprocess.STARTF_USESHOWWINDOW
      info.wShowWindow=subprocess.SW_HIDE
      process = subprocess.Popen( arglist,
                               stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               startupinfo=info)
   else:
      process = subprocess.Popen( arglist,
                               stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)
   process.stdin.write( cmds )
   process.stdin.close()
   # write and record the program output
   stdoutdata = ""
   while process.poll() == None:
     data = process.stdout.readline()
     sys.stdout.write( data )
     sys.stdout.flush()
     stdoutdata += data
   data = process.stdout.read()
   sys.stdout.write( data )
   sys.stdout.flush()
   stdoutdata += data
   self.status = process.returncode
   self.stdout = stdoutdata
   self.stderr = process.stderr.read()
   if self.error:
     if self.status != 0:
       sys.stderr.write( prgm+" "+args+"\n"+cmds+"\n" )
       sys.stderr.write( self.stderr )
       sys.stderr.flush()
       raise( StandardError( 'Fail in program <'+prgm+'>' ) )

 def run_program_template( self, *data ):
   if len(data) == 1:
     assert len(data[0]) == 3
     prgm, args, cmds = data[0]
   else:
     assert len(data) == 3
     prgm, args, cmds = data
   argx = self.xml.xsl_parse( Template( args ).data )
   cmdx = self.xml.xsl_parse( Template( cmds ).data )
   self.run_program( prgm, argx, cmdx )

 def display_params( self, title ):
   s0 = "################################################################\n"
   s1 = "###                                                          ###\n"
   s2 = s1[:4] + title + s1[4+len(title):]
   s = s0 + s2 + s0
   s += "----------------------  INPUT PARAMETERS  ----------------------\n"
   for i in self.params_inp:
     s += i[0] + " " + i[1] + "\n";
   s += "---------------------- DEFAULT PARAMETERS ----------------------\n"
   for i in self.params_def:
     s += i[0] + " " + i[1] + "\n";
   s += "----------------------------------------------------------------\n"
   return s

 def read( self, path ):
   f = file( path, 'r' ); s = f.read(); f.close()
   return s

 def readlines( self, path ):
   f = file( path, 'r' ); s = f.readlines(); f.close()
   return s

 def write( self, path, txt ):
   f = file( path, 'w' ); f.write( txt ); f.close()

 def copy( self, src, dst ):
   self.stdin += '\ncp '+src+' '+dst+'\n\n'
   import shutil
   shutil.copy( src, dst )

 def remove( self, path ):
   self.stdin += '\nrm '+path+'\n\n'
   import os
   os.remove( path )

 def mkdir( self, path ):
   self.stdin += '\nmkdir '+path+'\n\n'
   import os
   try:
     os.mkdir( path )
   except OSError,e:
     return e

