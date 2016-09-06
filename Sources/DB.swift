import Foundation
import Redbird
import JSON

class DB {
    
    private let redbird: Redbird
    
    init(port: UInt16 = 6381) throws {
        let config = RedbirdConfig(address: "127.0.0.1", port: port, password: nil)
        self.redbird = try Redbird(config: config)
    }
    
    private func key() -> String {
        return "results"
    }
    
    func saveResult(result: PingerRunResult) throws {
        var node = try result.makeNode()
        //append current timestamp
        let timestamp = String(Date().timeIntervalSince1970)
        node["time"] = timestamp.makeNode()
        let jsonString = try node.toJSON().makeBytes().string
        let resp = try redbird
            .pipeline()
            .enqueue("RPUSH", params: [key(), jsonString])
            .enqueue("LTRIM", params: [key(), "-10", "-1"]) //keep the last 10 only
            .execute()
        let count = try resp[0].toInt()
        print("Saved result number \(count)")
    }
    
    func getLastResultJSON() throws -> JSON? {
        let resp = try redbird.command("LRANGE", params: [key(), "-1", "-1"])
            .toArray()
            .first?
            .toString()
        guard let bytes = resp?.bytes else { return nil }
        let json = try JSON(bytes: bytes)
        return json
    }
    
    func getLastResult() throws -> (TimeInterval, PingerRunResult)? {
        guard let json = try getLastResultJSON() else { return nil }
        let node = json.makeNode()
        let timestamp: TimeInterval = try node.extract("time")
        let result: PingerRunResult = try node.converted()
        return (timestamp, result)
    }
}
