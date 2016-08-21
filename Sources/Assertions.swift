import Node

let assertionTypes: [String: PongAssertion.Type] = [
    "statusCode": StatusCodeAssertion.self,
    "body": BodyAssertion.self
]

func parseAssertions(nodes: [Node], context: Context) throws -> [PongAssertion] {
    return try nodes.map { return try parseAssertion(node: $0, context: context) }
}

func parseAssertion(node: Node, context: Context) throws -> PongAssertion {
    let type: String = try node.extract("type")
    guard let assertionType = assertionTypes[type] else {
        throw PongError.unknownAssertionType(type)
    }
    return try assertionType.init(node: node, in: context)
}

struct StatusCodeAssertion: PongAssertion {
    let statusCode: Int
    init(node: Node, in context: Context) throws {
        self.statusCode = try node.extract("statusCode")
    }
    
    func makeNode() throws -> Node {
        return [
            "type": "statusCode",
            "statusCode": statusCode.makeNode()
        ]
    }
    
    var description: String {
        return "statusCode == \(statusCode)"
    }
    
    func verify(pong: Pong) -> PongAssertionResult {
        let realStatusCode = pong.response.status.statusCode
        let success = realStatusCode == statusCode
        if success {
            return .success
        } else {
            return .failure("\(realStatusCode)")
        }
    }
}

struct BodyAssertion: PongAssertion {
    let body: String
    init(node: Node, in context: Context) throws {
        let body: String = try node.extract("body")
        self.body = body.base64DecodedString
    }
    
    func makeNode() throws -> Node {
        return [
            "type": "body",
            "body": body.base64EncodedString().makeNode()
        ]
    }
    
    var description: String {
        return "body match"
    }

    func verify(pong: Pong) -> PongAssertionResult {
        let realBody = (pong.response.body.bytes ?? []).string
        let success = realBody == body
        if success {
            return .success
        } else {
            return .failure("\(realBody)")
        }
    }
}
