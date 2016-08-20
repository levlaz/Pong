import Vapor
import HTTP
import Foundation

class LoggingMiddleware: Middleware {
    
    weak var app: Droplet?
    init(app: Droplet) {
        self.app = app
    }
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let start = Date()
        let response = try next.respond(to: request)
        let duration = -start.timeIntervalSinceNow
        let ms = Double(Int(duration * 1000 * 1000))/1000
        let durationText = "\(ms) ms"
        app?.log.info("\(request.method) \(request.uri.path)\(request.uri.query != nil ? "?\(request.uri.query!)" : "") -> \(response.status.statusCode) (\(durationText))")
        return response
    }
}
