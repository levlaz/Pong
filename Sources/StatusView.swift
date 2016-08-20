import Vapor
import HTTP

enum StatusView: String {
    case html
    case json
}

struct StatusRenderer {
    
    let drop: Droplet
    
    func renderJSON() throws -> ResponseRepresentable {
        return JSON.object([:])
    }
    
    func renderHTML() throws -> ResponseRepresentable {
        let context: [String: Any] = [:]
        return try drop.view("status.mustache", context: context)
    }
}

