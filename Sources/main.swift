import Vapor
import HTTP
import Polymorphic
import JSON
import Foundation
import gzip_vapor

let drop = Droplet()

drop.middleware.append(LoggingMiddleware(app: drop))
drop.middleware.append(GzipServerMiddleware())

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
        }
    })
    
    // routes
    
    drop.get("/") { req in
        return Response(redirect: "/status")
    }
        
    drop.get("last") { req in
        if let last = try db.getLastResultJSON() {
            return last
        } else {
            return JSON(["message": "no result cached yet"])
        }
    }
    
    drop.post("run") { req in
        let result = try run()
        return try result.makeNode().toJSON()
    }
    
    drop.get("pings") { req in
        let config = try drop.config["pings"]!.node.toJSON()
        return config
    }
    
    drop.get("status") { req in
        if let last = try db.getLastResult() {
            return try statusRenderer.renderHTML(time: last.0, result: last.1)
        } else {
            return JSON(["message": "no result cached yet"])
        }
    }
    
    // start
    periodicRunner.start()
    drop.serve()
    
} catch {
    print(error)
    exit(1)
}
