import RPi.GPIO as GPIO
from bluetooth import *

#Setup GPIO pins for use in BOARD mode
GPIO.setmode(GPIO.BOARD)
GPIO.setup(3, GPIO.OUT)
GPIO.setup(5, GPIO.OUT)
GPIO.setup(7, GPIO.OUT)
GPIO.setup(11, GPIO.OUT)

#Open socket for Bluetooth
server_sock=BluetoothSocket( RFCOMM )
server_sock.bind(("",PORT_ANY))
server_sock.listen(1)

port = server_sock.getsockname()[1]

uuid = "94f39d29-7d6d-437d-973b-fba39e49d4ee"

advertise_service( server_sock, "PiCar",
                   service_id = uuid,
                   service_classes = [ uuid, SERIAL_PORT_CLASS ],
                   profiles = [ SERIAL_PORT_PROFILE ], 
                    )

client_sock, client_info = server_sock.accept()

#While connected to bluetooth
while True:

        try:
                data = client_sock.recv(1024)

                print "received [%s]" % data
#Checks what was recieved and send out GPIO signals
                if data == 'u':
                        GPIO.output(3,True)
                elif data == 'd':
                        GPIO.output(5,True)
                elif data == 'l':
                        GPIO.output(7,True)
                elif data == 'r':
                        GPIO.output(11,True)
                elif data == 'nu':
                        GPIO.output(3,False)
                elif data == 'nd':
                        GPIO.output(5,False)
                elif data == 'nl':
                        GPIO.output(7,False)
                elif data == 'nr':
                        GPIO.output(11,False)

        except IOError:
                pass
        
#Clean up on GPIO and socket when interrupted by keyboard
        except KeyboardInterrupt:

                print "disconnected"
                GPIO.cleanup()

                client_sock.close()
                server_sock.close()
                print "all done"

                break

