import Vapor
import HTTP
import VaporMustache
import Polymorphic
import JSON

let providers: [Vapor.Provider.Type] = [VaporMustache.Provider.self]

#if os(Linux)
import VaporTLS
let drop = Droplet(client: Client<TLSClientStream>.self, providers: providers)
#else
let drop = Droplet(providers: providers)
#endif

drop.middleware.append(LoggingMiddleware(app: drop))

// setup objects

let pinger = try Pinger(drop: drop)
//do {
//    let result = try pinger.run()
//    print("Objects created")
//} catch {
//    print(error)
//}

let statusRenderer = StatusRenderer(drop: drop)

// routes

drop.get("/") { req in
    return Response(redirect: "/status")
    //TODO: index page
    //returns a rendered page for all the status checks and how they're doing
//    let context: [String: Any] = [:]
//    return try drop.view("index.mustache", context: context)
}

drop.post("run") { req in
    let result = try pinger.run()
    return try result.makeNode().toJSON()
}

drop.get("ping-templates") { req in
    let config = drop.config["pings"] as! JSON
    return config
}

drop.get("status") { req in
    
    guard let statusView = StatusView(rawValue: req.query?["format"]?.string ?? "html") else {
        return try Response(status: .badRequest, json: .object(["error": .string("invalid format")]))
    }
    
    switch statusView {
    case .html:
        return try statusRenderer.renderHTML()
    case .json:
        return try statusRenderer.renderJSON()
    }
}

// start

drop.serve()
