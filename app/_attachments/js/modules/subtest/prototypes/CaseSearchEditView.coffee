class CaseSearchEditView extends Backbone.View

  className: "LocationEditView"

  events:
    'keyup #case-data'              : 'updateCaseData'
    'keyup #fields'                 : 'updateFields'
    'click #case-data-format input' : 'updateCaseData'
    'click #fields-format input'    : 'updateFields'


  updateCaseData: (event) ->
    if event?.type == "click"
      if $(event.target).val() == "Tabs"
        @caseDataCommaToTab()
        hasTabs   = true
        hasCommas = false
      else
        @caseDataTabToComma()
        hasTabs   = false
        hasCommas = true

    else
      caseData = @$el.find("#case-data").val()
      hasTabs = caseData.match(/\t/g)?
      hasCommas = caseData.match(/,/g)?

    if hasTabs
      @$el.find("#case-data-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")
    else
      @$el.find("#case-data-format :radio[value='Commas']").attr("checked", "checked").button("refresh")

  updateFields: (event) ->
    if event?.type == "click"
      if $(event.target).val() == "Tabs"
        @fieldsCommaToTab()
        hasTabs   = true
        hasCommas = false
      else
        @fieldsTabToComma()
        hasTabs   = false
        hasCommas = true

    else
      fields    = @$el.find("#fields").val()
      hasTabs   = fields.match(/\t/g)?
      hasCommas = fields.match(/,/g)?

    fields = @$el.find("#fields").val()
    hasTabs   = fields.match(/\t/g)?
    hasCommas = fields.match(/,/g)?
    if hasTabs
      @$el.find("#fields-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")
    else
      @$el.find("#fields-format :radio[value='Commas']").attr("checked", "checked").button("refresh")


  caseDataTabToComma: -> @$el.find("#case-data").val(String(@$el.find("#case-data").val()).replace(/\t/g,", "))
  caseDataCommaToTab: -> @$el.find("#case-data").val(@$el.find("#case-data").val().replace(/, */g, "\t"))
  fieldsTabToComma: -> @$el.find("#fields").val(String(@$el.find("#fields").val()).replace(/\t/g,", "))
  fieldsCommaToTab: -> @$el.find("#fields").val(@$el.find("#fields").val().replace(/, */g, "\t"))

  save: ->
    if @$el.find("#case-data").val().match(/\t/g)?
      @$el.find("#case-data-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")
      @caseDataTabToComma()
    if @$el.find("#fields").val().match(/\t/g)?
      @fieldsTabToComma()
      @$el.find("#fields-format :radio[value='Tabs']").attr("checked", "checked").button("refresh")

    fields = @$el.find("#fields").val().split(/, */g)
    for level, i in fields
      fields[i] = $.trim(level).replace(/[^a-zA-Z0-9']/g,"")

    # removes /\s/
    caseDataValue = $.trim(@$el.find("#case-data").val())

    caseData = caseDataValue.split("\n")

    for caseDatum, i in caseData
      caseData[i] = caseDatum.split(/, */g)

    @model.set
      "fields"    : fields
      "caseData" : caseData

  isValid: ->
    fields = @model.get("fields")
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

  initialize: ( options ) ->
    @errors = []
    @model = options.model
    @errorMessages =
      "column_match" : "Some columns in the caseDatum data do not match the number of columns in the geographic levels."

  render: ->
    fields = @model.get("fields") || []
    caseData  = @model.get("caseData")  || []

    fields = _.escape(fields.join(", "))

    caseData = caseData.join("\n")
    if _.isArray(caseData)
      for caseDatum, i in caseData
        caseData[i] = _.escape(caseDatum.join(", "))

    @$el.html  "
      <div class='label_value'>
        <div class='menu_box'>
          <label for='fields' title='This is a comma separated list of geographic fields. (E.g. Country, Province, District, School Id) These are the fields that you would consider individual fields on the caseDatum form.'>Case Fields</label>
          <input id='fields' value='#{fields}'>
          <label title='Tangerine uses comma separated values. If you copy and paste from another program like Excel, the values will be tab separated. These buttons allow you to switch back and forth, however, Tangerine will always save the comma version.'>Format</label><br>
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
    @updateCaseData()

