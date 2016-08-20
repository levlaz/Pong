import Vapor
import HTTP
import VaporMustache
import Polymorphic
import JSON
import Foundation

let providers: [Vapor.Provider.Type] = [VaporMustache.Provider.self]

#if os(Linux)
    import VaporTLS
let drop = Droplet(client: Client<TLSClientStream>.self, providers: providers)
#else
let drop = Droplet(providers: providers)
#endif

drop.middleware.append(LoggingMiddleware(app: drop))

do {
    // setup objects
    
    var pinger = try Pinger(drop: drop)
    let statusRenderer = StatusRenderer(drop: drop)
    let emailSender = try EmailSender(drop: drop)
    
    let redisPort = UInt16(drop.config["server", "redis-port"]?.uint ?? 6381)
    let db = try DB(port: redisPort)
    
    func run() throws -> PingerRunResult {
        let result = try pinger.run()
        
        if result.hasFailure() && !pinger.isFailing {
            //started failing
            print("Started failing, sending email")
            pinger.isFailing = true
            try emailSender.sendEmailStartedFailing(result: result)
        } else if !result.hasFailure() && pinger.isFailing {
            //stopped failing
            print("Stopped failing, sending email")
            pinger.isFailing = false
            try emailSender.sendEmailStoppedFailing(result: result)
        } else if !result.hasFailure() {
            print("All assertions passed")
        } else {
            print("Some assertions still failing")
        }
        
        //save to db
        try db.saveResult(result: result)
        
        return result
    }
    
    let interval = drop.config["server", "interval"]?.double ?? 60
    let periodicRunner = PeriodicRunner(interval: interval, action: {
        do {
            let result = try run()
            let resultJSON = try result.makeNode().toJSON()
            //TODO: save to cache
            print("Ran: \(result.hasFailure() ? "failed" : "succeeded")")
        } catch {
            print("Failed periodic action, error \(error)")
            fatalError()
        }
    })
    
    // routes
    
    drop.get("/") { req in
        return Response(redirect: "/status")
        //TODO: index page
        //returns a rendered page for all the status checks and how they're doing
        //    let context: [String: Any] = [:]
        //    return try drop.view("index.mustache", context: context)
    }
    
    drop.get("last") { req in
        if let last = try db.getLastResultJSON() {
            return last
        } else {
            return try JSON(["message": "no result cached yet"])
        }
    }
    
    drop.post("run") { req in
        let result = try run()
        return try result.makeNode().toJSON()
    }
    
    drop.get("pings") { req in
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
    periodicRunner.start()
    drop.serve()
    
} catch {
    print(error)
    exit(1)
}
