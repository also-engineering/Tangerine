Case = Backbone.Model.extend
  url : 'case'

Cases = Backbone.Collection.extend
  url: 'case'
  model: Case

CaseListView = Backbone.View.extend
  initialize: (options) ->
    @cases = options.cases

CaseEditView = Backbone.View.extend

  events:
    'click .back' : 'back'
    'click .save' : 'save'

  back: ->
    window.history.back()

  save: (event) ->

    event.preventDefault()
    @aCase.save
      caseId      : @$el.find('#case-id').val()
      visitNumber : @$el.find('#visit-number').val()
      dob         : @$el.find('#dob').val()
    ,
      error: (err) -> Utils.midAlert(JSON.stringify(err))
      success: ->
        Utils.midAlert('Saved')
        Tangerine.router.navigate('cases', true)


  initialize: (options) ->
    @aCase = options.aCase

  render: ->
    @$el.html "
      <button class='navigation back'>Back</button>
      <form id='new-case'>
        <table>
          <tr><td>Case ID</td> <td><input id='case-id' value='#{_(@aCase.get('caseId')).escape()}'></td></tr>
          <tr><td>Visit number</td> <td><input id='visit-number' value='#{_(@aCase.get('visitNumber')).escape()}'></td></tr>
          <tr><td>DOB</td> <td><input id='dob' type='date' value='#{_(@aCase.get('dob')).escape()}'></td></tr>
          <tr><td><button class='command save'>Save</button></td></tr>
        </table>
      </form>
    "
    @trigger "rendered"

CaseMenuView = Backbone.View.extend

  events:
    'submit #new-case' : 'newCase'
    'click .edit' : 'editCase'
    'click .back' : 'back'

  back: ->
    Tangerine.router.navigate "assessments", true

  initialize: (options) ->
    @cases = options.cases
    @listenTo @cases, 'sync', @renderCaseList

  newCase: (e) ->
    e.preventDefault()
    caseId      = @$el.find('#case-id').val()
    visitNumber = @$el.find('#visit-number').val()
    dob         = @$el.find('#dob').val()

    @cases.create
      fields: ["caseId", "visitNumber", "dob"]
      caseData: [caseId, visitNumber, dob]

  renderCaseList: ->
    html = "
      <table>
      <tr><th>case</th><th>visit</th><th>dob</th></tr>
    "
    @cases.each (oneCase) ->
      html += "<tr><td>#{oneCase.get('caseId')}</td><td>#{oneCase.get('visitNumber')}</td><td>#{oneCase.get('dob')}</td><td><button class='command'><a href='#case/#{oneCase.id}'>Edit</a></button></td></tr>"

    html += '</table>'
    @$el.find('#case-list-container').html html

  render: ->

    newCaseHtml = "
      <form id='new-case'>
        <table>
          <tr><td>Case ID</td> <td><input id='case-id'></td></tr>
          <tr><td>Visit number</td> <td><input id='visit-number'></td></tr>
          <tr><td>DOB</td> <td><input id='dob' type='date'></td></tr>
          <tr><td><button class='command create'>Create</button></td></tr>
        </table>
      </form>
    "
    @$el.html "
      <button class='navigation back'>Back</button>
      <h2>New</h2>
      #{newCaseHtml}
      <h2>Cases</h2>
      <div id='case-list-container'></div>
    "

    @renderCaseList()
    @trigger "rendered"



class CaseSelectEditView extends Backbone.View

  className: "CaseSelectEditView"

  events:
    'keyup #fields'              : 'updateFields'
    'click #fields-format input' : 'updateFields'

  updateCommaTabDisplay: (event, selector) ->
    value     = @$el.find(selector).val()
    hasTabs   = value.match(/\t/g)?

    if event?.type == "click"
      if $(event.target).val() == "Tabs"
        @commaToTab selector
        hasTabs   = true
      else
        @tabToComma selector
        hasTabs   = false

    if hasTabs
      @$el.find("#{selector}-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")
    else
      @$el.find("#{selector}-format :radio[value='Commas']").attr("checked", "checked").button("refresh")

  updateVisibleFields: (event) ->
    @updateCommaTabDisplay event, "#visible-fields"


  tabToComma: (selector) -> @$el.find(selector).val(String(@$el.find(selector).val()).replace(/\t/g,", "))
  commaToTab: (selector) -> @$el.find(selector).val(@$el.find(selector).val().replace(/, */g, "\t"))

  save: ->

    if @$el.find("#visible-fields").val().match(/\t/g)?
      @visibleFieldsTabToComma()
      @$el.find("#visible-fields-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")

    visibleFields = @$el.find("#visible-fields").val().split(/, */g)
    for visibleField, i in visibleFields
      visibleFields[i] = $.trim(visibleField).replace(/[^a-zA-Z0-9']/g,"")

    caseName = @$el.find("#case-name").val()

    @model.set
      "visibleFields" : visibleFields
      "caseName"      : caseName

  isValid: -> return true

  showErrors: ->
    alertText = "Please correct the following errors:\n\n"
    for error in @errors
      alertText += @errorMessages[error]
    alert alertText
    @errors = []

  errorMessages :
      "column_match"          : "Some columns in the caseDatum data do not match the number of columns in the geographic levels."
      'unknown_visible_field' : "Visible field not found in fields."

  initialize: ( options ) ->
    @errors = []
    @model = options.model

  render: ->
    visibleFields  = _.escape(@model.getArray("visibleFields").join(", "))
    caseName      = @model.getEscapedString("caseName")


    @$el.html  "
      <section>
        <div class='label_value'>
          <label for='case-name'>Case name</label>
          <input id='case-name' value='#{caseName}''>
        </div>

        <div class='label_value'>
          <div class='menu_box'>
            <label for='visible-fields'>Visible Fields</label>
            <input id='visible-fields' value='#{visibleFields}'>
            <label>Format</label><br>
            <div id='visible-fields-format' class='buttonset'>
              <label for='visible-fields-tabs'>Tabs</label>
              <input id='visible-fields-tabs' name='visible-fields-format' type='radio' value='Tabs'>
              <label for='visible-fields-commas'>Commas</label>
              <input id='visible-fields-commas' name='visible-fields-format' type='radio' value='Commas'>
            </div>
          </div>
        </div>
      </section>
    "

  afterRender: ->
    @updateVisibleFields()



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
      <select id='selector'>
        <option selected disabled>Please select a #{@caseName}</option>
        <option value='none'>None</option>
        #{@cases.models.map((oneCase) =>
          "<option value='#{oneCase.id}'>
            #{@visibleFields.map((field) =>
              @getFromCase(oneCase,field)
            ).join(' - ')}
          </option>").join('')}
      </select>
    "

    @trigger "rendered"
    @trigger "ready"

  getFromCase: (oneCase, field) ->
    index = oneCase.getArray('fields').indexOf(field)
    return oneCase.get('caseData')[index]

  getResult: ->
    selectedId = @$el.find('#selector option:selected').val()
    if selectedId is 'none'
      return {
        fields: ['no_case_selected'],
        caseData : [1]
      }

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