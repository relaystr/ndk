package relaystr.ndk

/// Constants for the NIP-55 "Android Signer Application" protocol.
///
/// NIP-55 is a protocol implemented by several external signer apps
/// (Amber, Primal, Aegis, ...). The wire format below is generic.

const val nostrSignerScheme = "nostrsigner"

const val keyType = "type"
const val keyCurrentUser = "current_user"
const val keyUriData = "uri_data"
const val keyPubKey = "pubKey"
const val keyId = "id"
const val keyPermissions = "permissions"
const val keyResult = "result"
const val keySignature = "signature"
const val keyPackage = "package"
const val keyEvent = "event"
