# Extend every view with a close method, used by ViewManager
Backbone.View.prototype.close = ->
  @remove()
  @unbind()
  @onClose?()

# hash the attributes of a model
Backbone.Model.prototype.toHash = ->
  significantAttributes = {}
  for key, value of @attributes
    significantAttributes[key] = value if !~['_rev', '_id','hash','updated'].indexOf(key)
  b64_sha1(JSON.stringify(significantAttributes))

# by default all models will save a timestamp and hash of significant attributes
Backbone.Model.prototype.beforeSave = ->
  @set "updated", (new Date()).toString()
  @set "hash", @toHash()


#
# handy jquery functions
#
( ($) -> 

  $.fn.scrollTo = (speed=250, callback)->
    try
      $('html, body').animate {
        scrollTop: $(@).offset().top + 'px'
        }, speed, null, callback
    catch e
      console.log e
      console.log "Scroll error with 'this'"
      console.log @

    return @

  # place something top and center
  $.fn.topCenter = ->
    @css "position", "absolute"
    @css "top", $(window).scrollTop() + "px"
    @css "left", (($(window).width() - @outerWidth()) / 2) + $(window).scrollLeft() + "px"

  # place something middle center
  $.fn.middleCenter = ->
    @css "position", "absolute"
    @css "top", (($(window).height() - this.outerHeight()) / 2) + $(window).scrollTop() + "px"
    @css "left", (($(window).width() - this.outerWidth()) / 2) + $(window).scrollLeft() + "px"

)(jQuery)

#
# CouchDB error handling
#
$.ajaxSetup
  statusCode:
    404: (xhr, status, message) ->
      code = xhr.status
      statusText = xhr.statusText
      seeUnauthorized = ~xhr.responseText.indexOf("unauthorized")
      if seeUnauthorized
        Utils.midAlert "Session closed<br>Please log in and try again."
        Tangerine.user.logout()



# debug codes
km = {"0":48,"1":49,"2":50,"3":51,"4":52,"5":53,"6":54,"7":55,"8":56,"9":57,"a":65,"b":66,"c":67,"d":68,"e":69,"f":70,"g":71,"h":72,"i":73,"j":74,"k":75,"l":76,"m":77,"n":78,"o":79,"p":80,"q":81,"r":82,"s":83,"t":84,"u":85,"v":86,"w":87,"x":88,"y":89,"z":90}
sks = [ { q : (km["0100ser"[i]] for i in [0..6]), i : 0, c : -> settings = new Settings "_id" : "TangerineSettings"; settings.fetch({ success: (settings) -> settings.set({"context": "server"}); settings.save();  Tangerine.router.navigate("", true);}) },
        { q : (km["0100mob"[i]] for i in [0..6]), i : 0, c : -> settings = new Settings "_id" : "TangerineSettings"; settings.fetch({ success: (settings) -> settings.set({"context": "mobile"}); settings.save();  Tangerine.router.navigate("", true);}) },
        { q : (km["0100cla"[i]] for i in [0..6]), i : 0, c : -> settings = new Settings "_id" : "TangerineSettings"; settings.fetch({ success: (settings) -> settings.set({"context": "class"}); settings.save(); Tangerine.router.navigate("", true);}) } ]
$(document).keydown (e) -> ( if e.keyCode == sks[j].q[sks[j].i++] then sks[j]['c']() if sks[j].i == sks[j].q.length else sks[j].i = 0 ) for sk, j in sks 
String.prototype.safetyDance = -> this.replace(/\s/g, "_").replace(/[^a-zA-Z0-9_]/g,"")

Math.ave = ->
  result = 0
  result += x for x in arguments
  result /= arguments.length
  return result

Math.isInt = -> return typeof n == 'number' && parseFloat(n) == parseInt(n, 10) && !isNaN(n)

Math.decimals = (num, decimals) -> m = Math.pow( 10, decimals ); num *= m; num =  num+(num<0?-0.5:+0.5)>>0; num /= m


class Utils

  @working: (isWorking) ->
    if isWorking
      Tangerine.loadingTimers = [] if not Tangerine.loadingTimers?
      Tangerine.loadingTimers.push(setTimeout(Utils.showLoadingIndicator, 3000))
    else
      if Tangerine.loadingTimers?
        clearTimeout timer while timer = Tangerine.loadingTimers.pop()
          
      $(".loading_bar").remove()

  @showLoadingIndicator: ->
    $("<div class='loading_bar'><img class='loading' src='images/loading.gif'></div>").appendTo("body").middleCenter()

  # asks for confirmation in the browser, and uses phonegap for cool confirmation
  @confirm: (message, options) ->
    if navigator.notification?.confirm?
      navigator.notification.confirm message, 
        (input) ->
          if input == 1
            options.callback true
          else if input == 2
            options.callback false
          else
            options.callback input
      , options.title, options.action+",Cancel"
    else
      if window.confirm message
        options.callback true
        return true
      else
        options.callback false
        return false
    return 0

  # this function is a lot like jQuery.serializeArray, except that it returns useful output
  @getValues: ( selector ) ->
    values = {}
    $(selector).find("input, textarea").each ( index, element ) -> 
      values[element.id] = element.value
    return values

  @cleanURL: (url) ->
    if url.indexOf?("%") != -1 
      url = decodeURIComponent url
    else
      url

  # Disposable alerts
  @topAlert: (alert_text) ->
    $("<div class='disposable_alert'>#{alert_text}</div>").appendTo("#content").topCenter().delay(2000).fadeOut(250, -> $(this).remove())

  @midAlert: (alert_text) ->
    $("<div class='disposable_alert'>#{alert_text}</div>").appendTo("#content").middleCenter().delay(2000).fadeOut(250, -> $(this).remove())

  @S4: ->
   return ( ( ( 1 + Math.random() ) * 0x10000 ) | 0 ).toString(16).substring(1)

  @guid: ->
   return @S4()+@S4()+"-"+@S4()+"-"+@S4()+"-"+@S4()+"-"+@S4()+@S4()+@S4()

  @flash: (color="red") ->
    $("body").css "backgroundColor" : color
    setTimeout ->
      $("body").css "backgroundColor" : "white"
    , 1000


  @$_GET: (q,s) ->
    vars = {}
    parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, (m,key,value) ->
        value = if ~value.indexOf("#") then value.split("#")[0] else value
        vars[key] = value.split("#")[0];
    )
    vars

  @resizeScrollPane: ->
    $(".scroll_pane").height( $(window).height() - ( $("#navigation").height() + $("#footer").height() + 100) ) 

  @askToLogout: -> Tangerine.user.logout() if confirm("Would you like to logout now?")
      

##UI helpers
$ ->
  # ###.clear_message
  # This little guy will fade out and clear him and his parents. Wrap him wisely.
  # `<span> my message <button class="clear_message">X</button>`
  $("#content").on("click", ".clear_message",  null, (a) -> $(a.target).parent().fadeOut(250, -> $(this).empty().show() ) )
  $("#content").on("click", ".parent_remove", null, (a) -> $(a.target).parent().fadeOut(250, -> $(this).remove() ) )

  # disposable alerts = a non-fancy box
  $("#content").on "click",".alert_button", ->
    alert_text = if $(this).attr("data-alert") then $(this).attr("data-alert") else $(this).val()
    Utils.disposableAlert alert_text
  $("#content").on "click", ".disposable_alert", ->
    $(this).stop().fadeOut 100, ->
      $(this).remove()
  
  # $(window).resize Utils.resizeScrollPane
  # Utils.resizeScrollPane()
