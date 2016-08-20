import HTTP
import Node
import Foundation

struct Ping {
    let url: String
    let body: String?
    let method: HTTP.Method
    let assertions: [PongAssertion]
}

extension String {
    
    func base64EncodedString() -> String {
        return self.data(using: .utf8)!.base64EncodedString()
    }
    
    func base64DecodedString() -> String {
        return Data(base64Encoded: self)!.string
    }
}

extension Ping {
    
    func toRequest() throws -> Request {
        return try Request(method: method,
                           uri: url,
                           headers: ["User-Agent": "pong.honza.tech"],
                           body: .data(body?.bytes ?? []))
    }
}

extension Ping: NodeConvertible {
    
    init(node: Node, in context: Context) throws {
        self.url = try node.extract("url")
        let nodes: [Node] = try node.extract("assertions")
        let body: String? = try node.extract("body")
        self.body = body?.base64DecodedString
        let method: String? = try node.extract("method")
        self.method = Method(method ?? "GET")
        self.assertions = try parseAssertions(nodes: nodes, context: context)
    }
    
    func makeNode() throws -> Node {
        let nodes = try assertions.map({ try $0.makeNode() })
        let node: Node = try nodes.makeNode()
        var out: Node = [
            "url": url.makeNode(),
            "assertions": node
        ]
        if let body = body {
            out["body"] = body.base64EncodedString().makeNode()
        }
        return out
    }
}
