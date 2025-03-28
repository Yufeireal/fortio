FROM golang:1.24 AS builder

# Set working dir
WORKDIR /app

# Copy go.mod and go.sum early
COPY go.mod go.sum ./
RUN go mod download

# Install orchestrion
RUN go install github.com/DataDog/orchestrion@latest

# Add orchestrion to PATH (if installed to GOPATH/bin)
ENV PATH="/go/bin:${PATH}"

# Copy source code
COPY . .

# Use orchestrion to build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 orchestrion go build -o app .


# Minimal image with just the binary and certs
FROM scratch AS release
# We don't need to copy certs anymore since cli 1.6.0
# COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/app /usr/bin/fortio
EXPOSE 8078
EXPOSE 8079
EXPOSE 8080
EXPOSE 8081
# configmap (dynamic flags)
VOLUME /etc/fortio
# data files etc
VOLUME /var/lib/fortio
WORKDIR /var/lib/fortio
ENTRYPOINT ["/usr/bin/fortio"]
# start the server mode (grpc ping on 8079, http echo and UI on 8080, redirector on 8081) by default
CMD ["server", "-config-dir", "/etc/fortio"]