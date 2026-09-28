import 'local_cache.dart';
import 'cache_stub.dart'
    if (dart.library.io) 'cache_io.dart'
    if (dart.library.html) 'cache_web.dart'
    if (dart.library.js_interop) 'cache_web.dart' as platform;

export 'local_cache.dart';

Future<LocalCache> openLocalCache() => platform.createCache();
