import Vapor
import HTTP
import Foundation

struct StatusRenderer {
    
    let drop: Droplet
    
    func renderHTML(time: TimeInterval, result: PingerRunResult) throws -> ResponseRepresentable {
        let overview = result.hasFailure() ? "⚠️ Some checks are failing!" : "👍 All checks passed"
        let timeDiff = Int(Date().timeIntervalSince1970 - time)
        let pings: [[String: Any]] = result.results.map { res in
            let status = res.pong.hasFailed() ? "⛔️" : "✅"
            let assertions = assertionStatus(res: res)
            return [
                "status": status,
                "assertions": assertions,
                "name": res.ping.name,
                "url": res.ping.url
            ]
        }
        let context: [String: Any] = [
            "overview": overview,
            "ago": timeDiff,
            "pings": pings
        ]
        
        return try drop.view("status.mustache", context: context)
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

