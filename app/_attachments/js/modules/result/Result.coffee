class Result extends Backbone.Model

  url: "result"
  
  # name : currentView.model.get "name"
  # data : currentView.getResult()
  # subtestId : currentView.model.id
  # sum : currentView.getSum()
  #   { correct, incorrect, missing, total }
  #   

  initialize: ( options ) ->
    # could use defaults but it messes things up
    if options.blank == true
      device = device || Device || {}
      deviceInfo =
        'name'      : device.name
        'platform'  : device.platform
        'uuid'      : device.uuid
        'version'   : device.version
        'userAgent' : navigator.userAgent

      @set
        'subtestData' : []
        'start_time'  : (new Date()).getTime()
        'enumerator'  : Tangerine.user.name
        'tangerine_version' : Tangerine.version
        'device' : deviceInfo

      @unset "blank" # options automatically get added to the model. Lame.

  # Defined by default for all Models to provide a hash at save. not needed for results
  beforeSave: ->
    # do nothing

  add: ( subtestDataElement ) ->
    subtestDataElement['timestamp'] = (new Date()).getTime()
    subtestData = @get 'subtestData'
    subtestData.push subtestDataElement
    @save
      'subtestData' : subtestData

  getGridScore: (id) ->
    for datum in @get 'subtestData'
      return parseInt(datum.data.attempted) if datum.subtestId == id

  gridWasAutostopped: (id) ->
    for datum in @get 'subtestData'
      return datum.data.auto_stop if datum.subtestId == id
