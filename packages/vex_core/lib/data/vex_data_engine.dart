abstract interface class VexDataEngine {
  Future<T> read<T>(Future<T> Function() operation);

  Future<T> write<T>(Future<T> Function() operation);
}
