import PackageDescription

let package = Package(
    name: "Pong",
    dependencies: [
		.Package(url: "https://github.com/vapor/vapor.git", majorVersion: 0, minor: 16),
        .Package(url: "https://github.com/czechboy0/Redbird.git", majorVersion: 0, minor: 9)
    ]
)
