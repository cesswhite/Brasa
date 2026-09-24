import Foundation
import Security

// One request per child process. Secrets travel through inherited pipes only.
// No shell, credential arguments, environment secrets, files or diagnostic dumps.
SecKeychainSetUserInteractionAllowed(false)
let fixture = CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "--fixture-namespace"
let fixtureID = fixture ? CommandLine.arguments[2] : ""
if fixture && UUID(uuidString:fixtureID) == nil { exit(2) }
func reply(_ value: [String:Any]) -> Never {
    if let bytes = try? JSONSerialization.data(withJSONObject:value) { FileHandle.standardOutput.write(bytes);FileHandle.standardOutput.write(Data([10])) }
    exit(0)
}
var input = Data()
while input.count < 16384 {
    let chunk = FileHandle.standardInput.readData(ofLength:1)
    if chunk.isEmpty || chunk[0] == 10 { break };input.append(chunk)
}
guard input.count < 16384, let request = (try? JSONSerialization.jsonObject(with:input)) as? [String:Any], let operation = request["operation"] as? String,
      let origin = request["origin"] as? String, origin == "https://brasa-api-staging.acessloop.workers.dev" || (fixture && origin == "http://localhost:8787") else { reply(["ok":false,"code":"UNAVAILABLE"]) }
var query:[String:Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:fixture ? "game.brasa.fixture.session." + fixtureID : "game.brasa.online.session.v1",kSecAttrAccount as String:origin]

switch operation {
case "read":
    query[kSecReturnData as String]=true;query[kSecMatchLimit as String]=kSecMatchLimitOne
    var result:CFTypeRef?;let status=SecItemCopyMatching(query as CFDictionary,&result)
    if status == errSecItemNotFound {reply(["ok":true,"data":NSNull()])}
    guard status == errSecSuccess,let data=result as? Data,let record=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any] else {reply(["ok":false,"code":"UNAVAILABLE"])}
    reply(["ok":true,"data":record])
case "write":
    guard let record=request["data"] as? [String:Any],let token=record["token"] as? String,token.count>=20,token.count<=512,token.range(of:"^[A-Za-z0-9._%~-]+$",options:.regularExpression) != nil,
          let expiry=record["expires_at"] as? Double, expiry>Date().timeIntervalSince1970,expiry<=Date().timeIntervalSince1970+604860,
          let data=try? JSONSerialization.data(withJSONObject:["token":token,"expires_at":expiry,"origin":origin]) else {reply(["ok":false,"code":"INVALID_RECORD"])}
    var status=SecItemUpdate(query as CFDictionary,[kSecValueData as String:data] as CFDictionary)
    if status == errSecItemNotFound {
        query[kSecAttrLabel as String]="Brasa · Sesión del juego";query[kSecValueData as String]=data
        status=SecItemAdd(query as CFDictionary,nil)
    }
    reply(["ok":status == errSecSuccess,"code":status == errSecSuccess ? "SAVED":"UNAVAILABLE", "fixture_status": fixture ? Int(status):0])
case "delete":
    let status=SecItemDelete(query as CFDictionary)
    reply(["ok":status == errSecSuccess || status == errSecItemNotFound])
default: reply(["ok":false,"code":"UNAVAILABLE"])
}
