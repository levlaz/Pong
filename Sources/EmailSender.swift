import Vapor
import SMTP
import Transport
#if os(Linux)
import VaporTLS
#endif

extension String {
    func trimmingQuotes() -> String {
        return self.trim(characters: ["\""])
    }
}

struct EmailSender {
    
    init(drop: Droplet) throws {
        guard
            let target = drop.config["server", "on-fail", 0, "email"]?.string,
            let username = drop.config["server", "on-fail", 0, "username"]?.string,
            let password = drop.config["server", "on-fail", 0, "password"]?.string
            else {
                throw PongError.missingEmailSetup
        }
        
        self = EmailSender(target: target.trimmingQuotes(),
                           username: username.trimmingQuotes(),
                           password: password.trimmingQuotes())
    }
    
    var source: EmailAddress = EmailAddress(name: "Pong notifier", address: "noreply@pong.honza.tech")
    let target: String
    let username: String
    let password: String
    
    init(target: String, username: String, password: String) {
        self.target = target
        self.username = username
        self.password = password
    }
    
    func body(head: String, result: PingerRunResult) -> String {
        var body = "Greetings, \n\n"
        body += "\(head)\n\n"
        result.results.forEach { res in
            body += "- \(res.pong.hasFailed() ? "⛔️" : "✅") \(res.ping.url)\n"
        }
        body += "\n\n"
        body += "Just so you know. \nYours, Pong bot\n"
        body += "https://github.com/czechboy0/Pong\n"
        return body
    }
    
    func sendEmailStartedFailing(result: PingerRunResult) throws {
        let subject = "⚠️ Some Pong assertions started failing!"
        let head = "Some assertions have just started failing:"
        try sendEmail(subject: subject, body: body(head: head, result: result))
    }

    func sendEmailStoppedFailing(result: PingerRunResult) throws {
        let subject = "✅ All Pong assertions working again!"
        let head = "All assertions are passing again! 👍"
        try sendEmail(subject: subject, body: body(head: head, result: result))
    }

    func sendEmail(subject: String, body: String) throws {
        #if os(Linux)
            let client = try SMTPClient<TLSClientStream>.makeSendGridClient()
        #else
            let client = try SMTPClient<TCPClientStream>.makeSendGridClient()
        #endif
        
        let credentials = SMTPCredentials(user: username, pass: password)
        let email = Email(
            from: source,
            to: target,
            subject: subject,
            body: body
        )
        let (code, reply) = try client.send(email, using: credentials)
        guard code == 221 else {
            throw PongError.emailSendFailed(code, reply)
        }
    }
}
