class CaseSelectRunView extends Backbone.View

  className: "CaseSelectRunView"

  events:
    "click #search-results tr" : "autofill"
    "keyup input"  : "showOptions"
    "click .clear" : "clearInputs"

  i18n: ->
    @text =
      clear : t("LocationRunView.button.clear")

  searchResultHeaders: ->
    @fields.map((field,i) =>
      return "" if @visibleFields.indexOf(field) == -1
      "<th>#{field.underscore().humanize()}</th>"
    ).join('')

  initialize: (options) ->

    @i18n()

    @model     = options.model
    @parent    = options.parent
    @dataEntry = options.dataEntry

    @visibleFields = @model.getArray "visibleFields"

    @caseName = @model.getString 'caseName'

    if @visibleFields.length is 1 and @visibleFields[0] is ""
      @visibleFields = []

    @allCases = new Cases()
    @allCases.fetch
      success: =>
        @cases = new Cases()
        @allCases.models.forEach (oneCase) =>
          now = (new Date()).getTime()
          updated = (new Date(oneCase.get("updated"))).getTime()
          twoDays = 1e3 * 60 * 20 * 48
          createdWithinTwoDays = now - updated < twoDays
          @cases.add(oneCase) if createdWithinTwoDays
        @ready = true
        @render()

  clearInputs: ->
    @$el.empty()
    @render()

  render: ->

    return @$el.html "Loading" unless @ready

    @$el.html "
      <h2>Select a #{@caseName}</h2>
      <select id='selector'>
        #{@cases.models.map((oneCase) =>
          "<option value='#{oneCase.id}'>
            #{@visibleFields.map((field) =>
              console.log("testing")
              @getFromCase(oneCase,field)
            ).join(' - ')}
          </option>").join('')}
      </select>
    "

    @trigger "rendered"
    @trigger "ready"

  getFromCase: (oneCase, field) ->
    index = oneCase.getArray('fields').indexOf(field)
    console.log(oneCase)
    console.log(field)
    return oneCase.get('caseData')[index]


  getResult: ->
    selectedId = @$el.find('#selector option:selected').val()
    selectedCase = @cases.get(selectedId)

    caseAttributes = {
      fields   : selectedCase.get('fields')
      caseData : selectedCase.get('caseData')
    }

    return caseAttributes

  getSkipped: ->
    return {
      fields   : @fields
      caseData : @fields.map -> "S"
    }

  isValid: ->
    true

  showErrors: ->
    false