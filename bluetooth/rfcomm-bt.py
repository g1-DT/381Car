import RPi.GPIO as GPIO
from bluetooth import *

GPIO.setmode(GPIO.BOARD)
GPIO.setup(31, GPIO.OUT)
GPIO.setup(33, GPIO.OUT)
GPIO.setup(35, GPIO.OUT)
GPIO.setup(37, GPIO.OUT)

server_sock=BluetoothSocket( RFCOMM )
server_sock.bind(("",PORT_ANY))
server_sock.listen(1)

port = server_sock.getsockname()[1]

reconnect = True

uuid = "94f39d29-7d6d-437d-973b-fba39e49d4ee"

advertise_service( server_sock, "PiCar",
                   service_id = uuid,
                   service_classes = [ uuid, SERIAL_PORT_CLASS ],
                   profiles = [ SERIAL_PORT_PROFILE ],
#                   protocols = [ OBEX_UUID ]
                    )
#print "Waiting for that connection doe"
#client_sock, client_info = server_sock.accept()
#print "Connected yo"
while True:

        if reconnect == True:
                print "Waiting fo connecting doe"
                client_sock, client_info = server_sock.accept()
                print "Connect yo"
                reconnect = False

        try:
                data = client_sock.recv(1024)

                print "received [%s]" % data

                if data == 'u':
                        GPIO.output(31,True)
                #       GPIO.output(5,False)
                #       GPIO.output(13,True)
                #       GPIO.output(15,False)
                elif data == 'd':
                #        GPIO.output(3,False)
                        GPIO.output(33,True)
                #       GPIO.output(13,False)
                #       GPIO.output(15,True)
                elif data == 'l':
                #        GPIO.output(3,True)
                #        GPIO.output(5,False)
                        GPIO.output(35,True)
                #        GPIO.output(15,False)
                elif data == 'r':
                #        GPIO.output(3,False)
                #        GPIO.output(5,False)
                #        GPIO.output(13,True)
                        GPIO.output(37,True)
                elif data == 'nu':
                        GPIO.output(31,False)
                        GPIO.output(33,False)
                        GPIO.output(35,False)
                        GPIO.output(37,False)
                elif data == 'nd':
                        GPIO.output(31,False)
                        GPIO.output(33,False)
                        GPIO.output(35,False)
                        GPIO.output(37,False)
                elif data == 'nl':
                        GPIO.output(31,False)
                        GPIO.output(33,False)
                        GPIO.output(35,False)
                        GPIO.output(37,False)
                elif data == 'nr':
                        GPIO.output(31,False)
                        GPIO.output(33,False)
                        GPIO.output(35,False)
                        GPIO.output(37,False)
                elif data == 'rc':
                        reconnect = True

        except IOError:
                pass

        except KeyboardInterrupt:

                print "disconnected"
                GPIO.cleanup()

                client_sock.close()
                server_sock.close()
                print "all done"

                break

