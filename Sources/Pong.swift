import HTTP
import Node

enum PongAssertionResult: NodeRepresentable {
    case success
    case failure(String)
    
    func isSuccess() -> Bool {
        if case .success = self {
            return true
        }
        return false
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
    func didAllSucceed() -> Bool {
        return self.filter({ !$0.isSuccess() }).count > 0
    }
}

protocol PongAssertion: CustomStringConvertible, NodeConvertible {
    func verify(pong: Pong) -> PongAssertionResult
}

enum PongResult: NodeRepresentable {
    case error(Error)
    case ran(Pong, [PongAssertionResult])
    
    func makeNode() throws -> Node {
        switch self {
        case .error(let error):
            return [
                "error": String(error).makeNode()
            ]
        case .ran(let pong, let results):
            return [
                "pong": try pong.makeNode(),
                "assertionResults": try results.makeNode()
            ]
        }
    }
}

extension Status: NodeRepresentable {
    public func makeNode() throws -> Node {
        return [
            "statusCode": statusCode.makeNode(),
            "reasonPhrase": reasonPhrase.makeNode()
        ]
    }
}

extension Response: NodeRepresentable {
    public func makeNode() throws -> Node {
        return [
            "status": try status.makeNode(),
            "headers": try headers.makeNode()
        ]
    }
}

struct Pong: NodeRepresentable {
    let response: Response
    
    func verify(assertions: [PongAssertion]) -> PongResult {
        let results = assertions.map { return $0.verify(pong: self) }
        return .ran(self, results)
    }
    
    func makeNode() throws -> Node {
        return [
            "response": try response.makeNode()
        ]
    }
}
