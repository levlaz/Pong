import PackageDescription

let package = Package(
    name: "Pong",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 0, minor: 17),
        .Package(url: "https://github.com/czechboy0/gzip-vapor.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/czechboy0/Redbird.git", majorVersion: 0, minor: 10)
    ]
)
