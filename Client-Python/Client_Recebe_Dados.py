# Client Conecta via UDP e recebe os Dados do Metatrade

import socket, sys
from time import ctime

HOST = 'localhost'
PORT = 8888
BUFSIZE = 1024
ADDR = (HOST,PORT)

UDP= socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

while True:
    envia = " Ask Recebido "
    UDP.sendto(envia.encode('utf-8'), ADDR)
    re= UDP.recvfrom(1024000)
    data = re[0].decode('utf-8')
    print ("Recebido ",data)
UDP.close()

