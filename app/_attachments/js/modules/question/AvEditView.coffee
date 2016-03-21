AvEditView = Backbone.View.extend

  className: 'av-edit-view'

  events:
    'change #auto-progress'      : 'updateAutoProgress'
    'change #delay'              : 'updateDelay'
    'change #transition-comment' : 'updateTransitionComment'
    'change #time-limit'         : 'updateTimeLimit'
    'change #warning-time'    : 'updateWarningTime'
    'change #warning-message' : 'updateWarningMessage'
    'change input[type=file]' : 'updateFiles'
    'change select#stimulus'  : 'updateStimulus'
    'change input.asset'      : 'updateAssets'
    'change .asset-name'      : 'changeAssetName'
    'change .asset-value'     : 'changeAssetValue'
    'click .remove-asset'     : 'removeAsset'

    'click button.layout-add-row'       : 'addRow'
    'click button.layout-remove-row'    : 'removeRow'
    'click button.layout-add-column'    : 'addColumn'
    'click button.layout-remove-column' : 'removeColumn'
    'change select.layout-cell-content' : 'updateCell'
    'change input.layout-column-width'  : 'updateColumnWidth'
    'change input.layout-row-height'    : 'updateRowHeight'

  initialize: (options) ->
    @model = options.model

  updateDelay: ->
    @model.set('delay', parseInt(@$el.find('#delay').val()))

  updateAutoProgress: ->
    @model.set('autoProgress', @$el.find("#auto-progress").is(":checked"))

  updateTransitionComment: ->
    @model.set('transitionComment', @$el.find('#transition-comment').val())

  updateTimeLimit: ->
    @model.set('timeLimit', @getNumber('#time-limit'))

  updateWarningTime: ->
    @model.set('warningTime', @getNumber('#warning-time'))

  updateWarningMessage: ->
    @model.set('warningMessage', @getString('#warning-message'))


  save: ->
    # attributes are handled independently and immediately
    # most editors @model.set everything

  addRow: (e) ->
    layout = @layout()
    layout.rows.push({height:10,columns:[]})
    @layout(layout)
    @renderLayoutEditor()

  removeRow: (e) ->
    row = @getNumber e, 'data-row'
    layout = @layout()
    layout.rows.splice(row, 1)
    @layout layout
    @renderLayoutEditor()

  addColumn: (e) ->
    row = @getNumber e, 'data-row'
    layout = @layout()
    layout.rows[row].columns = [] unless layout.rows[row].columns?
    layout.rows[row].columns.push({width:10,cell:null})
    @renderLayoutEditor()


  removeColumn: (e) ->
    column = @getNumber e, 'data-column'
    row = @getNumber e, 'data-row'
    layout = @layout()
    layout.rows[row].columns.splice(column, 1)
    @layout layout
    @renderLayoutEditor()

  updateCell: (e) ->
    row    = @getNumber e, 'data-row'
    column = @getNumber e, 'data-column'

    if @getString(e) is "none"
      value = null
    else
      value  = @getNumber e

    layout = @layout()
    layout.rows[row].columns[column].cell = value
    @updateGridPreview()

  updateColumnWidth: (e) ->
    row    = @getNumber e, 'data-row'
    column = @getNumber e, 'data-column'
    value  = @getNumber e
    layout = @layout()
    layout.rows[row].columns[column].width = value
    @layout layout
    @updateGridPreview()


  updateRowHeight: (e) ->
    row    = @getNumber e, 'data-row'
    value  = @getNumber e
    layout = @layout()
    layout.rows[row].height = value
    @layout layout
    @updateGridPreview()

  updateFiles: (e) ->
    files = e.target.files
    file = files[0]

    if files && file
      reader = new FileReader()

      reader.onload = (readerEvt) =>
        img64 = btoa(readerEvt.target.result)
        @addAsset
          name    : file.name
          imgData : img64
          type    : file.type

      reader.readAsBinaryString(file)

  renderStimulusEditor: ->
    stimulus = @model.getNumber('stimulus', null)
    assets = @model.getArray('assets')

    optionsHtml = assets.map ( el, i ) ->
      selected = 'selected' if stimulus is i
      "<option value='#{i}' #{selected||''}>#{el.name}</option>"
    if stimulus is null
      optionsHtml = "<option selected disabled>Please select a stimulus</option>" + optionsHtml

    noneSelected = "selected" if stimulus is "none"
    optionsHtml += "<option value='none' #{noneSelected}>None</option>"

    html = "
      <select id='stimulus'>#{optionsHtml}</select>
    "

    @$el.find('#stimulus-container').html html

  # when a new stimulus is selected
  updateStimulus: (e) ->
    stimulus = @getString(e)
    @model.set "stimulus", stimulus

  # when an asset's name is changed
  changeAssetName: (e) ->
    index = @getNumber e, 'data-index'
    name = @getString e

    assets = @model.getArray('assets')
    assets[index].name = name
    @model.set('assets', assets)
    @saveQuestion()


  changeAssetValue: (e) ->
    index = @getNumber e, 'data-index'
    value = @getString e

    assets = @model.getArray('assets')
    assets[index].value = value
    @model.set('assets', assets)
    @saveQuestion()

  # save question. called when an asset is changed. Seems important to save then.
  saveQuestion: ->
    @model.save null,
      success: =>
        Utils.midAlert "Question saved"

  removeAsset: (e) ->
    index = @getNumber e, 'data-index'

    assets = @model.getArray('assets')
    assets.splice(index, 1)
    @model.set('assets', assets)

    # if we deleted our stimulus, update stimulus too
    if @model.getNumber('stimulus', null) is index
      @model.set('stimulus', null)
      @saveQuestion()
      @renderStimulusEditor()
    else
      @saveQuestion()
    # update screen
    @renderAssetManager()

  addAsset: (asset) ->
    # clean
    newAsset =
      name    : asset.name
      imgData : asset.imgData
      type    : asset.type

    # update model
    assets = @model.getArray("assets")
    assets.push(newAsset)
    @model.set("assets", assets)
    @saveQuestion()

    # update screen
    @renderAssetManager()

  renderAssetManager: ->

    if @model.getArray('assets').length is 0
      listHtml = '<p>Nothing uploaded yet.</p>'
    else
      listHtml = @model.getArray('assets').map((el, i) ->
        "<tr>
          <td><div class='image-container'><img class='asset-thumb' src='data:#{el.type};base64,#{el.imgData}'></div></td>
          <td><input class='asset-name' data-index='#{i}' value='#{_(el.name).escape()}'></td>
          <td><input class='asset-value' data-index='#{i}' value='#{_(el.value).escape()}' placeholder='No value'></td>
          <td><button class='remove-asset command' data-index='#{i}'>Remove</button></td>
        </tr>"
      ).join('')

      listHtml = "
        <table id='asset-table'>
          <tr><th>Thumbnail</th><th>Name</th><th>Value</th></tr>
          #{listHtml}
        </table>
      "

    @$el.find('#asset-manager').html "
      <section>
      <h3>Assets</h3>
        <input id='asset-file' type='file' accept='image/gif, image/jpeg, image/png, audio/mpeg' style='border: none;font-size: 16px;'>
        #{listHtml}
      </section>
    "
    @resizeAssetThumbs()

  resizeAssetThumbs: ->
    @$el.find('img.asset-thumb').on 'load', () ->
      ratio  = $(@).width() / $(@).height()
      pratio = $(@).parent().width() / $(@).parent().height()

      if (ratio < pratio)
        css = width:'auto', height:'100%'
      else
        css = width:'100%', height:'auto'

      $(@).css(css)

      if (ratio < pratio)
        $(@).parent().width($(@).width())
      else
        $(@).parent().height($(@).height())

  # helper mutator/accessor function
  # makes returning a vlid object more consise and sets for convenience
  layout: (obj) ->
    if obj?
      # technically not necessary since the object is passed via reference
      # but it feels good to explicitly set the layout
      @model.set('layout', obj)
    else
      return @model.getObject('layout',{rows:[]})

  # returns HTMl for the editor
  editorHtml: ->

    assets = @model.getArray('assets')
    layout = @layout()

    # go through each row
    return (layout.rows.map (row, y) =>
      return "<div>Row #{y+1}
      <label class='input-box'>Height <input size='3' style='width: auto;' class='layout-row-height' data-row='#{y}' value='#{row.height}'>%</label>
      <button data-row='#{y}' class='layout-remove-row command'>Remove row</button>
      <button class='layout-add-column command' data-row='#{y}'>Add column</button></div>" +
      ((row.columns||[]).map (col, x) =>

        cell = layout.rows[y].columns[x].cell

        optionsHtml = assets.map ( el, i ) ->
          selected = 'selected' if cell is i
          "<option value='#{i}' #{selected||''}>#{el.name}</option>"

        noneSelected = if cell is null then 'selected' else ''
        optionsHtml = "<option value='none' #{noneSelected}>none</option>" + optionsHtml

        cellSelector = "
          <select class='layout-cell-content' data-row='#{y}' data-column='#{x}'>#{optionsHtml}</select>
        "
        return "
          <div style='margin-left:10px;display: block;'>
            <label class='input-box'>Width <input size='3' style='width: auto;' class='layout-column-width' data-row='#{y}' data-column='#{x}' value='#{col.width}'>%</label>
            #{cellSelector}
            <button data-row='#{y}' data-column='#{x}' class='layout-remove-column command'>Remove</button>
          </div>"
      ).join('') # end of columns map
    ).join('') # end of rows map

  renderLayoutEditor: ->
    layout  = @layout()

    stimulus = @model.getNumber('stimulus', null)

    @$el.find('#layout-editor').html "
      <h3>Grid editor</h3>
      <button class='command layout-add-row'>Add row</button>
      <section>#{@editorHtml()}</section>
      <h3>Preview</h3>
      <section id='grid-preview' style='height:480px;width:640px;'></section>
    "
    @updateGridPreview()
    return

  htmlGridPreview: ->
    #
    # Generate preview
    #
    previewGridHtml = ""
    assets = @model.getArray('assets')

    @layout().rows.forEach (row, i) ->

      rowHtml = ''
      row.columns.forEach (column) ->
        asset = assets[column.cell]

        if column.cell != null
          imgHtml = "<img class='preview-thumb' src='data:#{asset.type};base64,#{asset.imgData}'>"
        else
          imgHtml = "<br>no image"
        rowHtml += "<div style='margin:0;display: inline-block; border:solid red 1px; width:#{640*(column.width/100)}px'; overflow:hidden'> <span class='dimension-overylay'>Width #{column.width}%</span> #{imgHtml}</div>"
      previewGridHtml += "<div style='border: 1px green solid; display:block; overflow:hidden; height:#{480*(row.height/100)}px'><span class='dimension-overylay'>Row Height #{row.height}</span>#{rowHtml}</div>"

    return previewGridHtml

  updateGridPreview: ->

    @$el.find("#grid-preview").html @htmlGridPreview()
    @$el.find('img.preview-thumb').on 'load', () ->
      ratio  = $(@).width() / $(@).height()
      pratio = $(@).parent().width() / $(@).parent().height()
      css = width:'100%', height:'auto'
      css = width:'auto', height:'100%' if (ratio < pratio)
      $(@).css(css)

  render: ->

    delay = @model.getNumber('delay')

    transitionComment = @model.getEscapedString('transitionComment')

    autoProgress = @model.getBoolean('autoProgress')

    timeLimit      = @model.getNumber('timeLimit')
    warningTime    = @model.getNumber('warningTime')
    warningMessage = @model.getEscapedString('warningMessage')

    @$el.html "
      <style>
      .image-container {
        width: 100px;
        height: 100px;
        display: inline-block;
        background-color: white;
      }
      #asset-table {
        background-color: #eee;
      }
      #asset-table td,
      #asset-table th {
        padding: 5px;
      }
      #asset-table input {
        margin-top: 15px;
      }
      .input-box {
        display: inline;
        border: 1px solid #aaa;
        border-radius: 3px;
        padding: 5px;
        font-weight: normal;
        margin: 0;
      }
      .input-box input {
        border: none;
        background-color: #eee;
      }
      .dimension-overylay {
        position: absolute;
        background-color: rgba(0,0,0,.4);
        color: white;
        font-weight: bold;
      }
      </style>
      <h3>AV Editor</h3>

        <table>
          <tr>
            <td><label for='delay'>Delay</label></td>
            <td><input id='delay' type='number' value=#{delay}></td>
          </tr>
          <tr>
            <td><label for='time-limit' title='The amount of time (in ms) that the participant will be given before the task moves to the next screen automatically. 0 means disabled.'>Time limit</label></td>
            <td><input id='time-limit' type='number' value='#{timeLimit}'></td>
          </tr>
          <tr>
            <td><label for='warning-time' title='The amount of time (in ms) given before a warning message appears. 0 means disabled.'>Warning time</label></td>
            <td><input id='warning-time' type='number' value='#{warningTime}'></td>
          </tr>
          <tr>
            <td><label for='warning-message' title='A message given after the warning time expires.'>Warning message</label></td>
            <td><input id='warning-message' type='text' value='#{warningMessage}'></td>
          </tr>
          <tr>
            <td><label for='auto-progress' title='Automatically progress to the next screen for a valid answer.'>Auto progress</label></td>
            <td><input id='auto-progress' type='checkbox' #{'checked' if autoProgress}></td>
          </tr>
          <tr>
            <td><label for='transition-comment' title='Message shown when there is a valid answer.'>Transition comment</label></td>
            <td><input id='transition-comment' type='text' value='#{transitionComment}'></td>
          </tr>
          <tr><td></td></tr>
          <tr>
            <td><label for='stimulus'>Stimulus</label></td>
            <td><div id='stimulus-container'></div></td>
          </tr>
        </table>
      <div id='asset-manager'></div>
      <div id='layout-editor'></div>
    "

    @renderStimulusEditor()
    @renderAssetManager()
    @renderLayoutEditor()

  # Utility to get the value or attribute contained in a dom element.
  # See: @getNumber and @getString
  getAttribute: (target, attribute) ->
    itsAjQueryEvent = target instanceof jQuery.Event
    itsADomElement  = target instanceof Node
    itsAString      = _(target).isString()

    $target = if itsAjQueryEvent
      $(target.target)
    else if itsADomElement
      $(target)
    else if itsAString
      @$el.find(target)

    return $target.val() unless attribute?
    return $target.attr(attribute)

  # Utility to get a number from a dom element
  getNumber: (target, attribute) ->
    return Number @getAttribute( target, attribute )

  # Utility to get a string
  # just for consistency, getAttribute always returns a string
  getString: (target, attribute) ->
    return @getAttribute( target, attribute )


