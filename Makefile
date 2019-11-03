all: rfcomm

clean:
	rm rfcomm

rfcomm: bluez-rfcomm/rfcomm.c bluez-rfcomm/rfcomm.1
	gcc bluez-rfcomm/rfcomm.c -lbluetooth -o rfcomm -DVERSION=5.45
