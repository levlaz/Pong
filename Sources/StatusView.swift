import Vapor
import HTTP
import Foundation

struct StatusRenderer {
    
    let drop: Droplet
    
    func renderHTML(time: TimeInterval, result: PingerRunResult) throws -> ResponseRepresentable {
        let overview = result.hasFailure() ? "⚠️ Some checks are failing!" : "👍 All checks passed"
        let timeDiff = Int(Date().timeIntervalSince1970 - time)
        let pings: [Node] = result.results.map { res -> Node in
            let status = res.pong.hasFailed() ? "⛔️" : "✅"
            let assertions = assertionStatus(res: res)
            return [
                "status": status.makeNode(),
                "assertions": assertions.makeNode(),
                "name": res.ping.name.makeNode(),
                "url": res.ping.url.makeNode()
            ]
        }
        let context: Node = [
            "overview": overview.makeNode(),
            "ago": timeDiff.makeNode(),
            "pings": try pings.makeNode()
        ]
        return try drop.view.make("status.leaf", context)
    }
    
    func assertionStatus(res: PingPong) -> String {
        switch res.pong {
        case .error(let err):
            let trimmed = err.substring(maxCharacters: 10)
            return "Ping failed ⛔️: \(trimmed)"
        case .ran(_, let results):
            return zip(res.ping.assertions, results).map({ (assertion, result) -> String in
                return "\(result.isSuccess() ? "✅" : "⛔️") \(assertion.description)"
            }).joined(separator: ", ")
        }
    }
}

