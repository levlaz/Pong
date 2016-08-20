
enum PongError: Error {
    case configNotJSON
    case pingTemplatesNotArray
    case unknownAssertionType(String)
}
