import Vapor

struct PingPong: NodeConvertible {
    let ping: Ping
    let pong: PongResult
    
    init(ping: Ping, pong: PongResult) {
        self.ping = ping
        self.pong = pong
    }
    
    init(node: Node, in context: Context) throws {
        self.ping = try node.extract("ping")
        self.pong = try node.extract("pongResult")
    }
    
    func makeNode() throws -> Node {
        return [
            "ping": try ping.makeNode(),
            "pongResult": try pong.makeNode()
        ]
    }
}

struct PingerRunResult: NodeConvertible {
    let results: [PingPong]
    
    init(results: [PingPong]) {
        self.results = results
    }
    
    init(node: Node, in context: Context) throws {
        self.results = try node.extract("results")
    }
    
    func makeNode() throws -> Node {
        return [
            "results": try results.makeNode()
        ]
    }
    
    func failed() -> [PingPong] {
        return results.filter { $0.pong.hasFailed() }
    }
    
    func hasFailure() -> Bool {
        return !failed().isEmpty
    }
}

struct Pinger {
    
    let drop: Droplet
    var pings: [Ping]
    var isFailing: Bool = false
    
    init(drop: Droplet) throws {
        guard let pingsNode = drop.config["pings"]?.node else {
            throw PongError.configNotJSON
        }
        guard let node = pingsNode.nodeArray else {
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
            return .error(String(describing: error))
        }
    }
}
