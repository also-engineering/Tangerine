
MemoryEditView = Backbone.View.extend
  initialize: (options) ->
    @model = options.model
  save: ->
    @model.set
      gridHeight: @$el.find('#grid-height').val()
      gridWidth: @$el.find('#grid-width').val()
      trials: @$el.find('#trials').val()

  render: ->
    gridHeight = @model.getNumber('gridHeight')
    gridWidth = @model.getNumber('gridWidth')
    trials = @model.getNumber('trials')

    @$el.html "
      <h2>Dimensions</h2>
      <section>
        <label for='grid-height'>Height</label>
        <input id='grid-height' value='#{_(gridHeight).escape()}' type='number'>

        <label for='grid-width'>Width</label>
        <input id='grid-width' value='#{_(gridWidth).escape()}' type='number'>
      </section>

      <h2>Game duration</h2>
      <section>
        <label for='trials'>Trials</label>
        <input id='trials' value='#{_(trials).escape()}' type='number'>
      </section>
    "

  isValid: -> @$el.find('#case-label').val() isnt ""

  showErrors: -> @$el.find('.message').html "Case label cannot be empty."

MemoryRunView = Backbone.View.extend

  events:
    'click #game-start' : 'start'
    'click #game-stop'  : 'stop'
    'click .cell' : 'cellClick'


  initialize: ->
    @result = []
    @mode = MemoryRunView.MODE.PREGAME

    @gridHeight = @model.getNumber('gridHeight')
    @gridWidth  = @model.getNumber('gridWidth')
    @trials     = @model.getNumber('trials')

    @allPositions = []
    [1..@gridHeight].forEach( (row) =>
      [1..@gridWidth].forEach( (col) =>
          @allPositions.push "#row-#{row}-col-#{col}"
        )
      )
    @sequence = [0..@trials].map => Math.floor(Math.random() * @allPositions.length)

  start: ->
    return if @mode isnt MemoryRunView.MODE.PREGAME
    @mode = MemoryRunView.MODE.DISPLAYING
    @trial = 1
    @displaySequence()

  displaySequence: (step = 0) ->
    if step is @trial
      return @getResponse()
    @$el.find(@allPositions[@sequence[step]]).addClass('highlight')
    setTimeout (=> @clearGrid()), MemoryRunView.DISPLAY_TIME
    setTimeout (=> @displaySequence(++step)), MemoryRunView.DISPLAY_TIME + MemoryRunView.DELAY_TIME

  getResponse: (step = 0) ->
    @mode = MemoryRunView.MODE.RESPONDING
    @response = []

  cellClick: (event) ->
    return unless @mode is MemoryRunView.MODE.RESPONDING
    cellPosition = $(event.target).attr('id')
    @response.push @allPositions.indexOf("##{cellPosition}")
    @validateResponse() if @response.length is @trial

  validateResponse: ->
    errors = 0
    @response.forEach (res, i) =>
      errors++ if res isnt @sequence[i]
    if errors is 0 and @sequence.length is @response.length
      Utils.midAlert "You won!"
    else if errors is 0
      @trial++
      setTimeout (=> @displaySequence()), MemoryRunView.INTERTRIAL_DELAY
    else
      Utils.midAlert "You lost!"


  clearGrid: ->
    @$el.find("td.cell").removeClass('highlight')

  render: ->
    gridHtml = "
      <style>
        .cell { width: 50px; height: 50px; background: #eee; border:5px solid white;}
        .cell:active { background: #6e6; }

        .highlight { background: #a33; }
      </style>
      <table>
      #{[1..@gridHeight].map( (row) =>
        "<tr>
        #{[1..@gridWidth].map( (col) =>
          "<td id='row-#{row}-col-#{col}' class='cell'></td>"
        ).join('')}
        </tr>"
      ).join('')}
      </table>
    "

    @$el.html "
      Memory game
      <ul>
        <li>gridHeight: #{@gridHeight}</li>
        <li>gridWidth: #{@gridWidth}</li>
        <li>trials: #{@trials}</li>
      </ul>
      <section>#{gridHtml}</section>
      <div id='game-controls'>
        <button id='game-start'>Start</button>
        <button id='game-stop'>Stop</button>
      </div>
    "
    @trigger "rendered"
    @trigger "subRendered"

  getResult: ->
    {}
  getSkipped: ->
    {}
  isValid: ->
    true
  showErrors: ->
    ""

MemoryRunView.MODE =
  PREGAME : 0
  DISPLAYING : 1
  RESPONDING : 2
  WAITING : 3

MemoryRunView.DISPLAY_TIME = 800
MemoryRunView.DELAY_TIME = 100
MemoryRunView.INTERTRIAL_DELAY = 2000

