package relaystr.ndk

/// Constants for the NIP-55 "Android Signer Application" protocol.
///
/// NIP-55 is a protocol implemented by several external signer apps
/// (Amber, Primal, Aegis, ...). Amber is only the reference app used for
/// installation detection / linking; the wire format below is generic.

const val nostrSignerScheme = "nostrsigner"

/// Reference external signer package (Amber) used as install-detection fallback.
const val referenceSignerPackage = "com.greenart7c3.nostrsigner"

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
