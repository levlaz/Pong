import Vapor

struct PingPong: NodeRepresentable {
    let ping: Ping
    let pong: PongResult
    
    func makeNode() throws -> Node {
        return [
            "ping": try ping.makeNode(),
            "pongResult": try pong.makeNode()
        ]
    }
}

struct PingerRunResult: NodeRepresentable {
    let results: [PingPong]
    
    func makeNode() throws -> Node {
        return [
            "results": try results.makeNode()
        ]
    }
}

struct Pinger {
    
    let drop: Droplet
    var pings: [Ping]
    
    init(drop: Droplet) throws {
        guard let pingsJSON = drop.config["pings"] as? JSON else {
            throw PongError.configNotJSON
        }
        guard let node = pingsJSON.makeNode().nodeArray else {
            throw PongError.pingTemplatesNotArray
        }
        self.drop = drop
        self.pings = try node.converted()
    }
    
    func run() throws -> PingerRunResult {
        var results: [PingPong] = []
        for ping in pings {
            let res = try run(ping: ping)
            results.append(PingPong(ping: ping, pong: res))
        }
        return PingerRunResult(results: results)
    }
    
    private func run(ping: Ping) throws -> PongResult {
        let request = try ping.toRequest()
        do {
            let response = try drop.client.respond(to: request)
            let pong = Pong(response: response)
            let result = pong.verify(assertions: ping.assertions)
            return result
        } catch {
            return .error(error)
        }
    }
}
