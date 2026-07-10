abstract interface class Repository<TEntity, TId> {
  Future<TEntity?> findById(TId id);
}
