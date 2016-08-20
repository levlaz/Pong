import HTTP
import Node

enum PongAssertionResult: NodeConvertible {
    case success
    case failure(String)
    
    func isSuccess() -> Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    init(node: Node, in context: Context) throws {
        let result: String = try node.extract("result")
        switch result {
        case "success":
            self = .success
        case "failure":
            self = .failure(try node.extract("message"))
        default:
            fatalError("Unknown case \(result)")
        }
    }
    
    func makeNode() throws -> Node {
        switch self {
        case .failure(let err):
            return [
                "result": "failure",
                "message": err.makeNode()
            ]
        case .success:
            return [
                "result": "success"
            ]
        }
    }
}

extension Collection where Iterator.Element == PongAssertionResult {
    func didSomeFail() -> Bool {
        return self.filter({ !$0.isSuccess() }).count > 0
    }
}

protocol PongAssertion: CustomStringConvertible, NodeConvertible {
    func verify(pong: Pong) -> PongAssertionResult
}

enum PongResult: NodeConvertible {
    case error(String)
    case ran(Pong, [PongAssertionResult])
    
    func hasFailed() -> Bool {
        switch self {
        case .error(_): return true
        case .ran(_, let results):
            return results.didSomeFail()
        }
    }
    
    init(node: Node, in context: Context) throws {
        if let error = node["error"]?.string {
            self = .error(error)
        } else {
            let pong: Pong = try node.extract("pong")
            let results: [PongAssertionResult] = try node.extract("assertionResults")
            self = .ran(pong, results)
        }
    }
    
    func makeNode() throws -> Node {
        switch self {
        case .error(let error):
            return [
                "error": error.makeNode()
            ]
        case .ran(let pong, let results):
            return [
                "pong": try pong.makeNode(),
                "assertionResults": try results.makeNode()
            ]
        }
    }
}

extension Status: NodeConvertible {
    public init(node: Node, in context: Context) throws {
        self = Status(statusCode: try node.converted())
    }
    
    public func makeNode() throws -> Node {
        return statusCode.makeNode()
    }
}

extension HeaderKey: NodeConvertible {
    public init(node: Node, in context: Context) throws {
        let description: String = try node.converted()
        self = HeaderKey(description)
    }
    
    public func makeNode() throws -> Node {
        return .string(self.description)
    }
}

extension Response: NodeConvertible {
    
    public convenience init(node: Node, in context: Context) throws {
        let status: Status = try node.extract("status")
        let headers: [String: String] = try node.extract("headers")
        var properHeaders: [HeaderKey: String] = [:]
        for (key, value) in headers {
            properHeaders[HeaderKey(key)] = value
        }
        self.init(status: status, headers: properHeaders)
    }
    
    public func makeNode() throws -> Node {
        return [
            "status": try status.makeNode(),
            "headers": try headers.makeNode()
        ]
    }
}

struct Pong: NodeConvertible {
    let response: Response
    
    init(response: Response) {
        self.response = response
    }
    
    func verify(assertions: [PongAssertion]) -> PongResult {
        let results = assertions.map { return $0.verify(pong: self) }
        return .ran(self, results)
    }
    
    init(node: Node, in context: Context) throws {
        self.response = try node.extract("response")
    }
    
    func makeNode() throws -> Node {
        return [
            "response": try response.makeNode()
        ]
    }
}
