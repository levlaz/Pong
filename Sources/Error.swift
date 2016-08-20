
enum PongError: Error {
    case configNotJSON
    case pingTemplatesNotArray
    case unknownAssertionType(String)
    case missingEmailSetup
    case emailSendFailed(Int, String)
}
