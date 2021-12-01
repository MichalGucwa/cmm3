# This file is used to shutdown handler. Temperately use only. 
#  July 06
#  Wanjuan Yang
#--------------------------------------------------------------------

import socket

sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
sock.connect(('localhost',4090))
message = "<db_request><command>DbRegister</command><argument>wy45</argument><argument>12</argument><request_id>4</request_id></db_request>\n"
sock.send(message)
#response = sock.recv(4096)

message = "<db_request><command>ShutDown</command><request_id>4</request_id></db_request>\n"
sock.send(message)
sock.close()
