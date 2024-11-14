library ndk;

/**
 * presentation layer
 * 
 */

export 'presentation_layer/ndk.dart';
export 'presentation_layer/ndk_config.dart';
export 'domain_layer/entities/ndk_request.dart';
export 'domain_layer/entities/request_response.dart';

/**
 * common entities
 * 
 * to access all entities use 
 * import 'package:ndk/entities.dart' as ndk_entities;
 * 
 */
export 'domain_layer/entities/nip_01_event.dart';
export 'domain_layer/entities/filter.dart';
export 'domain_layer/entities/nip_51_list.dart';
export 'domain_layer/entities/contact_list.dart';
export 'domain_layer/entities/read_write.dart';
export 'domain_layer/entities/relay.dart';
export 'domain_layer/entities/relay_set.dart';
export 'domain_layer/entities/metadata.dart';

/**
 *  export classes that need to be injected
 * 
 */

/// signers / verifiers
export 'domain_layer/repositories/event_verifier.dart';
export 'domain_layer/repositories/event_signer.dart';
export 'data_layer/repositories/verifiers/bip340_event_verifier.dart';
export 'data_layer/repositories/signers/bip340_event_signer.dart';

/// cache
export 'domain_layer/repositories/cache_manager.dart';
export 'data_layer/repositories/cache_manager/mem_cache_manager.dart';
// export 'data_layer/repositories/cache_manager/db_cache_manager.dart';

/**
 * common usecases
 * 
 */

export "domain_layer/usecases/relay_manager.dart";
export "domain_layer/usecases/jit_engine.dart";
export "domain_layer/usecases/requests/requests.dart";
export "domain_layer/usecases/follows/follows.dart";
export 'domain_layer/usecases/metadatas/metadatas.dart';
export 'domain_layer/usecases/user_relay_lists/user_relay_lists.dart';
export 'domain_layer/usecases/lists/lists.dart';
export 'domain_layer/usecases/relay_sets/relay_sets.dart';
