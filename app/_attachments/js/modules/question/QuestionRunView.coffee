class QuestionRunView extends Backbone.View

  className: 'question'

  events:
    'change input'           : 'update'
    'change textarea'        : 'update'
    'click .av-controls-prev' : 'avPrev'
    'click .autoscroll_icon' : 'scroll'
    'click .av-controls-exit' : 'avExit'
    'click .av-controls-next' : 'avNext'
    'mousedown .av-button' : 'avButton'

  avExit: ->
    # reset the timer every time the button is pressed
    if @exitTimerId?
      clearTimeout @exitTimerId
      @exitTimerId = setTimeout @cancelExit.bind(this), QuestionRunView.EXIT_TIMER
    else
      @exitTimerId = setTimeout @cancelExit.bind(this), QuestionRunView.EXIT_TIMER

    @exitCount++
    if @exitCount > 4
      @abort()

  abort: ->
    @trigger 'abort'

  cancelExit: ->
    @exitCount = 0
    @exitTimerId = null



  startAv: ->
    @$el.find('.av-question').css('display', 'block')
    @displayTime = (new Date()).getTime()
    @startProgressTimer() if @timeLimit isnt 0
    @startWarningTimer()  if @warningTime isnt 0
    @resizeAvImages()

  stopTimers: ->
    clearTimeout(@warningTimerId)  if @warningTimerId?
    clearTimeout(@progressTimerId) if @progressTimerId?

  startWarningTimer: ->
    @warningTimerId = setTimeout(@checkWarningTimer.bind(@), QuestionRunView.TIMER_INTERVAL)

  checkWarningTimer: ->
    elapsed = (new Date).getTime() - @displayTime
    if elapsed >= @warningTime
      @setMessage @model.get('warningMessage')
    else
      @warningTimerId = setTimeout(@checkWarningTimer.bind(@), QuestionRunView.TIMER_INTERVAL)

  startProgressTimer: ->
    @progressTimerId = setTimeout(@checkProgressTimer.bind(@), QuestionRunView.TIMER_INTERVAL)

  checkProgressTimer: ->
    elapsed = (new Date).getTime() - @displayTime
    if elapsed >= @timeLimit
      @forceProgress(elapsed)
    else
      @progressTimerId = setTimeout(@checkProgressTimer.bind(@), QuestionRunView.TIMER_INTERVAL)

  forceProgress: (elapsed) ->
    @forcedTime = elapsed
    @isValid = true
    @skipped = true
    @model.set('skippable', true)
    @answer = "skipped" if @answer is ""
    @trigger "av-next"

  avButton: (e) ->
    time = (new Date).getTime() - @displayTime
    $target = $(e.target).parent('button')
    unless @responseTime
      @responseTime = time
      @audio.play() if @audio?
      @answer = $target.attr('data-value')
      @updateValidity()

    @model.getString('transitionComment')
    if @isValid
      @trigger 'av-next' if @autoProgress
      if @model.getString('transitionComment') isnt ''
        @setMessage(@model.getEscapedString('transitionComment'))
    else
      if @model.getString('transitionComment') isnt ''
        @setMessage(@model.getEscapedString('transitionComment'))

      return @setMessage(@model.getEscapedString("customValidationMessage"))

    @trigger "answer", e, @model.get('order')

  avPrev: ->
    @trigger "av-prev"
  avNext: ->
    @trigger "av-next"

  scroll: (event) ->
    @trigger "scroll", event, @model.get("order")

  playDisplayAudio: () ->
    @displayAudioObj.play()

  initialize: (options) ->
    @on "show", => @onShow()
    @model     = options.model
    @parent    = options.parent

    @displayAudio = @model.getObject('displayAudio', false)
    if @displayAudio
      @displayAudioObj = new Audio("data:#{@displayAudio.type};base64,#{@displayAudio.data}")

    @inputAudio = @parent.model.getObject('inputAudio', false)
    if @inputAudio
      @audio = new Audio("data:#{@inputAudio.type};base64,#{@inputAudio.data}")
    @dataEntry = options.dataEntry
    @fontFamily = @parent.model.get('fontFamily')
    @fontStyle = "style=\"font-family: #{@parent.model.get('fontFamily')} !important;\"" if @parent.model.get("fontFamily") != ""

    unless @dataEntry
      @answer = options.answer
    else
      @answer = {}

    @name     = @model.escape("name").replace /[^A-Za-z0-9_]/g, "-"
    @type     = @model.get "type"
    @options  = @model.get "options"
    @notAsked = options.notAsked
    @isObservation = options.isObservation

    @defineSpecialCaseResults()

    if @model.getBoolean("skippable")
      @isValid = true
      @skipped = true
    else
      @isValid = false
      @skipped = false

    if @notAsked == true
      @isValid = true
      @updateResult()

    if @type == "single" or @type == "multiple"
      @button = new ButtonView
        options : @options
        mode    : @type
        dataEntry  : @dataEntry
        answer     : @answer
        fontFamily : @fontFamily

      @button.on "change rendered", => @update()

    @timeLimit      = @model.getNumber('timeLimit', 0)
    @warningTime    = @model.getNumber('warningTime', 0)
    @warningMessage = @model.getEscapedString('warningMessage')
    @autoProgress  = @model.getBoolean('autoProgress')
    @exitTimerId   = null
    @exitCount = 0


  previousAnswer: =>
    @parent.questionViews[@parent.questionIndex - 1].answer if @parent.questionIndex >= 0

  onShow: =>

    showCode = @model.getString("displayCode")

    return if _.isEmptyString(showCode)

    try
      CoffeeScript.eval.apply(@, [showCode])
    catch error
      name = ((/function (.{1,})\(/).exec(error.constructor.toString())[1])
      message = error.message
      alert "Display code error\n\n#{name}\n\n#{message}"

  update: (event) =>
    @updateResult()
    @updateValidity()
    @trigger "answer", event, @model.get("order")

  updateResult: =>
    if @notAsked == true
      if @type == "multiple"
        for option, i in @options
          @answer[@options[i].value] = "not_asked"
      else
        @answer = "not_asked"
    else
      if @type == "open"
        @answer = @$el.find("##{@cid}_#{@name}").val()
      else
        @answer = @button.answer

  updateValidity: ->

    isSkippable    = @model.getBoolean("skippable")
    isAutostopped  = @$el.hasClass("disabled_autostop")
    isLogicSkipped = @$el.hasClass("disabled_skipped")

    # have we or can we be skipped?
    if isSkippable or ( isLogicSkipped or isAutostopped )
      # YES, ok, I guess we're valid
      @isValid = true
      @skipped = if _.isEmptyString(@answer) then true else false
    else
      # NO, some kind of validation must occur now
      customValidationCode = @model.get("customValidationCode")

      @answer = "" unless @answer

      if not _.isEmptyString(customValidationCode)
        try
          @isValid = CoffeeScript.eval.apply(@, [customValidationCode])
        catch e
          alert "Custom Validation error\n\n#{e}"
      else
        @isValid =
          switch @type
            when "open"
              if _.isEmptyString(@answer) || (_.isEmpty(@answer) && _.isObject(@answer)) then false else true # don't use isEmpty here
            when "multiple"
              if ~_.values(@answer).indexOf("checked") then true  else false
            when "single"
              if _.isEmptyString(@answer) || (_.isEmpty(@answer) && _.isObject(@answer)) then false else true
            when "av"
              hasTime = @timeLimit isnt 0
              timeValid = (new Date).getTime - @displayTime >= @timeLimit
              notEmpty = @answer isnt ""
              notEmpty or (hasTime and timeValid)

  setOptions: (options) =>
    @button.options = options
    @button.render()

  setAnswer: (answer) =>
    alert "setAnswer Error\nTried to set #{@type} type #{@name} question to string answer." if _.isString(answer) && @type == "multiple"
    alert "setAnswer Error\n#{@name} question requires an object" if not _.isObject(answer) && @type == "multiple"

    if @type == "multiple"
      @button.answer = $.extend(@button.answer, answer)
    else if @type == "single"
      @button.answer = answer
    else
      @answer = answer

    @updateValidity()
    @button.render()

  setMessage: (message) =>
    @$el.find(".error_message").html message

  setPrompt: (prompt) =>
    @$el.find(".prompt").html prompt

  setHint: (hint) =>
    @$el.find(".hint").html hint

  setName: ( newName = @model.get('name') ) =>
    @model.set("name", newName)
    @name = @model.escape("name").replace /[^A-Za-z0-9_]/g, "-"

  getName: =>
    @model.get("name")

  render: ->
    @$el.attr "id", "question-#{@name}"

    if not @notAsked

      html = "<div class='error_message'></div><div class='prompt' #{@fontStyle || ""}>#{@model.get 'prompt'}</div>
      <div class='hint' #{@fontStyle || ""}>#{(@model.get('hint') || "")}</div>"

      if @type == "open"
        if _.isString(@answer) && not _.isEmpty(@answer)
          answerValue = @answer
        if @model.get("multiline")
          html += "<div><textarea id='#{@cid}_#{@name}' data-cid='#{@cid}' value='#{answerValue || ''}'></textarea></div>"
        else
          html += "<div><input id='#{@cid}_#{@name}' data-cid='#{@cid}' value='#{answerValue || ''}'></div>"
      else if @type == "av"
        html += "<div class='av-question' id='container-#{@name}'></div>"

      else
        html += "<div class='button_container'></div>"

      html += "<img src='images/icon_scroll.png' class='icon autoscroll_icon' data-cid='#{@cid}'>" if @isObservation
      @$el.html html

      if @type == "single" or @type == "multiple"
        @button.setElement(@$el.find(".button_container"))
        @button.on "rendered", => @trigger "rendered"
        @button.render()
      else
        @trigger "rendered"

    else
      @$el.hide()
      @trigger "rendered"
    @htmlAv()

  htmlAv: ->

    #
    # Generate av question
    #
    html = ""
    assets = @model.getArray('assets')

    windowHeight = $(window).height() - 200
    console.log("win height: " +  windowHeight)
    windowWidth  = $(window).width()
    @model.layout().rows.forEach (row) ->

      rowHtml = ''
      row.columns.forEach (cell) ->
        asset = assets[cell.content]

        if cell.content != null
          imgHtml = "<button class='av-button' data-value='#{_.escape(asset.value)}'><img class='av-image' src='data:#{asset.type};base64,#{asset.imgData}'></button>"
        else
          imgHtml = ""

        if cell.align != null
          textAlign = "text-align: #{Question.AV_ALIGNMENT[cell.align]}"
        else
          textAlign = ''

        rowHtml += "<div class='av-cell' style='height:#{windowHeight*(row.height/100)}px; width:#{windowWidth*(cell.width/100)}px;  #{textAlign}'>#{imgHtml}</div>"
      html += "<div class='av-row' style='height:#{windowHeight*(row.height/100)}px'>#{rowHtml}</div>"

    # wrap the old html variable
    html = "
    <div class='av-controls'>
      <button class='av-controls-prev command'>&lt;</button>
      <button class='av-controls-exit command'>x</button>
      <button class='av-controls-next command'>&gt;</button>
    </div>

    <div id='av-progress' class='av-light'></div>
    <div class='av-light av-prompt error_message'>#{@model.get('prompt')}</div>
    <div class='av-layout'>#{html}</div>
    "

    @$el.find("#container-#{@name}").html html

    if @autoProgress
      @$el.find('.av-controls')[0].style.opacity = 0

    @resizeAvImages()

  resizeAvImages: ->

    @$el.find('img.av-image').each ->
      ratio  = $(@).width() / $(@).height()
      pratio = $(@).parent().width() / $(@).parent().height()

      if (ratio < pratio)
        css = width:'auto', height:'100%'
      else
        css = width:'100%', height:'auto'

      $(@).parent().css(css)


  setProgress: (current, total)->
    @$el.find("#av-progress").html "#{current}/#{total}"

  defineSpecialCaseResults: ->
    list = ["missing", "notAsked", "skipped", "logicSkipped", "notAskedAutostop"]
    for element in list
      if @type == "single" || @type == "open"
        @[element+"Result"] = element
      if @type == "multiple"
        @[element+"Result"] = {}
        @[element+"Result"][@options[i].value] = element for option, i in @options
    return

Object.defineProperty QuestionRunView, "TIMER_INTERVAL",
  value: 20, # 20 milliseconds


Object.defineProperty QuestionRunView, "EXIT_TIMER",
  value: 5e3 # 5 seconds
