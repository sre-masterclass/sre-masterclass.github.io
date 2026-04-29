# Use the official Golang image to create a build artifact.
FROM golang:1.22-alpine AS builder

# Install git
RUN apk add --no-cache git

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Copy the source code
COPY . .

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN ls -la
RUN go version
RUN go env
RUN cat go.mod
RUN cat go.sum
RUN go mod tidy

# Build the Go app
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Use a minimal image to run the app
FROM alpine:latest

# Install wget for health checks
RUN apk --no-cache add wget

# Set the Current Working Directory inside the container
WORKDIR /root/

# Copy the Pre-built binary file from the previous stage
COPY --from=builder /app/main .

# Make the binary executable
RUN chmod +x ./main

# Expose port 8000 to the outside world
EXPOSE 8000

# Command to run the executable
CMD ["./main"]
