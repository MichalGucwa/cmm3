#! /usr/bin/awk -f
#
#removes from a brk file disorder conformations, converts A to space  and deletes B
#
{
   line_pdb = $0

   if (substr($0,17,1) == "B" ) 
      { getline 
        line_pdb = $0
      }
   else {
   if (substr($0,17,1) == "A" ) 
      {   line1 = substr($0,1,16)
          line3 = substr($0,18,55)
          print line1,line3 
      }

   else
  {         printf "%s\n",line_pdb    }
}
}
#
