import PackageDescription

let package = Package(
    name: "Pong",
    dependencies: [
		.Package(url: "https://github.com/vapor/vapor.git", majorVersion: 0, minor: 16),
        .Package(url: "https://github.com/vapor/vapor-mustache.git", majorVersion: 0, minor: 11),
        .Package(url: "https://github.com/czechboy0/Redbird.git", majorVersion: 0, minor: 9)
    ]
)

#if os(Linux)
package.dependencies.append(.Package(url: "https://github.com/vapor/tls-provider.git", "0.0.42"))
#endif
