unpack:
	./unpack.sh Balatro.exe
	(cd unpacked && zip -9 -r ../game.love .)

build:
	go build -o balatro

run:
	go run .