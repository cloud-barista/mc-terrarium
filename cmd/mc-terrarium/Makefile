default:
	go build -o mc-terrarium
cc:
	GOOS=linux GOARCH=arm go build -o mc-terrarium-arm
run:
	./mc-terrarium
runwithport:
	./mc-terrarium --port=$(PORT)
clean:
	rm -v mc-terrarium
prod:
	@echo "Build for production"
# Note - Using cgo write normal Go code that imports a pseudo-package "C". I may not need on cross-compiling.
# Note - You can find possible platforms by 'go tool dist list' for GOOS and GOARCH
# Note - Using the -ldflags parameter can help set variable values at compile time.
# Note - Using the -s and -w linker flags can strip the debugging information.
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-s -w' -o mc-terrarium
