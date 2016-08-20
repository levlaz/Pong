
protocol FailureHandler {
    func handleFailure(result: PongResult) throws
}

struct ServerSetup {
    let interval: Int //how often to automatically run all pings [seconds]
    let onFail: [FailureHandler] //what to call when a failure happens
}


