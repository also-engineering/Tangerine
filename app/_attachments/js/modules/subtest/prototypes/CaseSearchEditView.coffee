class CaseSearchEditView extends Backbone.View

  className: "CaseSelectEditView"

  events:
    'keyup #case-data'              : 'updateCaseData'
    'keyup #fields'                 : 'updateFields'
    'keyup #visible-fields'         : 'updateVisibleFields'

    'click #case-data-format input'      : 'updateCaseData'
    'click #fields-format input'         : 'updateFields'
    'click #visible-fields-format input' : 'updateVisibleFields'

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

  updateCaseData: (event) ->
    @updateCommaTabDisplay event, "#case-data"

  updateFields: (event) ->
    @updateCommaTabDisplay event, "#fields"

  updateVisibleFields: (event) ->
    @updateCommaTabDisplay event, "#visible-fields"


  tabToComma: (selector) -> @$el.find(selector).val(String(@$el.find(selector).val()).replace(/\t/g,", "))
  commaToTab: (selector) -> @$el.find(selector).val(@$el.find(selector).val().replace(/, */g, "\t"))



  save: ->

    if @$el.find("#case-data").val().match(/\t/g)?
      @$el.find("#case-data-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")
      @caseDataTabToComma()

    if @$el.find("#fields").val().match(/\t/g)?
      @fieldsTabToComma()
      @$el.find("#fields-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")

    if @$el.find("#visible-fields").val().match(/\t/g)?
      @visibleFieldsTabToComma()
      @$el.find("#visible-fields-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")

    fields = @$el.find("#fields").val().split(/, */g)
    for field, i in fields
      fields[i] = $.trim(field).replace(/[^a-zA-Z0-9']/g,"")

    visibleFields = @$el.find("#visible-fields").val().split(/, */g)
    for visibleField, i in visibleFields
      visibleFields[i] = $.trim(visibleField).replace(/[^a-zA-Z0-9']/g,"")

    # removes leading and trailng /\s/
    caseDataValue = $.trim(@$el.find("#case-data").val())
    caseData = caseDataValue.split("\n")

    for caseDatum, i in caseData
      caseData[i] = caseDatum.split(/, */g)

    @model.set
      "fields"        : fields
      "caseData"      : caseData
      "visibleFields" : visibleFields

  isValid: ->
    visibleFields = @model.get 'visibleFields'
    fields        = @model.get 'fields'
    visibleFields.forEach (oneField) =>
      return if oneField.length is 0
      @errors.push 'unknown_visible_field' if fields.indexOf(oneField) == -1

    for caseDatum in @model.get("caseData")
      if caseDatum.length != fields.length
        @errors.push "column_match" unless "column_match" in @errors
    return @errors.length == 0

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
    fields         = @model.getArray("fields")
    visibleFields  = @model.getArray("visibleFields")
    caseData       = @model.getArray("caseData")

    fields        = _.escape(fields.join(", "))
    visibleFields = _.escape(visibleFields.join(", "))
    caseData      = caseData.join("\n")

    if _.isArray(caseData)
      for caseDatum, i in caseData
        caseData[i] = _.escape(caseDatum.join(", "))

    @$el.html  "
      <div class='label_value'>
        <div class='menu_box'>
          <label for='fields'>Case Fields</label>
          <input id='fields' value='#{fields}'>
          <label>Format</label><br>
          <div id='fields-format' class='buttonset'>
            <label for='fields-tabs'>Tabs</label>
            <input id='fields-tabs' name='fields-format' type='radio' value='Tabs'>
            <label for='fields-commas'>Commas</label>
            <input id='fields-commas' name='fields-format' type='radio' value='Commas'>
          </div>
        </div>
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

      <div class='label_value'>
        <div class='menu_box'>
          <label for='case-data' title='Comma sperated values, with multiple rows separated by line. This information will be used to autofill the caseDatum data.'>Case data</label>
          <textarea id='case-data'>#{caseData}</textarea><br>
          <label title='Tangerine uses comma separated values. If you copy and paste from another program like Excel, the values will be tab separated. These buttons allow you to switch back and forth, however, Tangerine will always save the comma version.'>Format</label><br>        <div id='caseData-format' class='buttonset'>
          <div id='case-data-format' class='buttonset'>
            <label for='case-data-tabs'>Tabs</label>
            <input id='case-data-tabs' name='case-data-format' type='radio' value='Tabs'>
            <label for='case-data-commas'>Commas</label>
            <input id='case-data-commas' name='case-data-format' type='radio' value='Commas'>
          </div>
        </div>
      </div>
    "

  afterRender: ->
    @updateFields()
    @updateVisibleFields()
    @updateCaseData()

