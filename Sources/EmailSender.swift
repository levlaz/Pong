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
    
    func sendEmail() throws {
        #if os(Linux)
            let client = try SMTPClient<TLSClientStream>.makeSendGridClient()
        #else
            let client = try SMTPClient<TCPClientStream>.makeSendGridClient()
        #endif
        
        let credentials = SMTPCredentials(user: username, pass: password)
        let email = Email(
            from: source,
            to: target,
            subject: "⚠️ Some of your Pong assertions have failed!",
            body: "Hello from Vapor SMTP 👋"
        )
        let (code, reply) = try client.send(email, using: credentials)
        guard code == 221 else {
            throw PongError.emailSendFailed(code, reply)
        }
    }
}
