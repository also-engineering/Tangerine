(doc) ->
  return if doc.collection isnt "result"

  result = {
    id         : doc._id
    enumerator : doc.editedBy
    endTime    : doc.updated
    #uploaded   : doc.uploaded
    complete   : false
    length     : doc.subtestData.length
    location   : {}
    grids : []
  }

  modSuspicion = 0

  for subtest in doc.subtestData
    if subtest.prototype is "location"
      result.location = subtest.data
    else if subtest.prototype is "complete"
      result.complete = true
    else if subtest.prototype is "grid"
      grid =
        name      : subtest.data.variable_name
        auto      : subtest.data.auto_stop
        left      : subtest.data.time_remain
        last      : parseInt(subtest.data.attempted)
        total     : subtest.data.time_allowed
        itemCount : subtest.data.items.length


      lastItemIsCorrect = subtest.data.items[subtest.data.attempted-1].itemResult is "C"
      modSuspicion++ if lastItemIsCorrect
      result.grids.push grid

  result.modulationFlag = modSuspicion is result.grids.length

  day   = parseInt(doc.updated.substr(8,2))
  month = {"Jan":1,"Feb":2,"Mar":3,"Apr":4,"May":5,"Jun":6,"Jul":7,"Aug":8,"Sep":9,"Oct":10,"Nov":11,"Dec":12}[doc.updated.substr(4,3)]
  year  = parseInt(doc.updated.substr(11, 4))

  emit [doc.assessmentId,year, month, day], result

###
* Autostop Too Fast:  if  *_autostop = TRUE    AND  *_time_remain > 55.
* Autostop Too Slow:  if  *_autostop = TRUE   AND  *_time_remain < 30. 
* Time Not Stopped:  if *_attempted =  (last grid item value)   AND  *_time_remain = 0
* Time Stopped Inappropriately:   if  *_time_remain > 0  AND  *_attempted ≠  (last grid item value) 
* Nudge Rule:  if  ( *_attempted) / (total time - *_time_remain) > 3 seconds
* Mode Modulation Rule:  if  *_attempted = correct  for ALL subtasks in an assessment;
Flag and question whether assessor knows how to change input mode to "mark" after time has stopped.  
###