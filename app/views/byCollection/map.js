(function(doc) {
  if (doc.collection) {
    return emit(doc.collection, {
      "r": doc._rev
    });
  }
});
