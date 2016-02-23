(keys, values, rereduce) ->
  if rereduce
    return [].concat.apply([], values)
  else
    return values