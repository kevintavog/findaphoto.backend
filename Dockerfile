# ================================
# Build image
# ================================
FROM swift:5.2-focal as build
WORKDIR /build

COPY ./Package.* ./
RUN swift package resolve

COPY . .
RUN swift build --enable-test-discovery -c release

# ================================
# Run image
# ================================
FROM docker.rangic:6000/findaphoto.base:1597520289

WORKDIR /app
COPY --from=build /build/.build/release /app

CMD ["./FindAPhoto"]

