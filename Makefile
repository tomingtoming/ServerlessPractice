build:
	dep ensure
	env GOOS=linux go build -ldflags="-s -w" -o bin/tryo   tryo/main.go
	env GOOS=linux go build -ldflags="-s -w" -o bin/mendes mendes/main.go
