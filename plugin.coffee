fs = require 'fs'
async = require 'async'
jade = require 'jade-legacy'

module.exports = (env, callback) ->

  options = env.config.jade or {}
  options.pretty ?= true



  class JadeStringTemplate

    constructor: (@fn) ->

    render: (locals, callback) ->
      try
        callback null, new Buffer @fn(locals)
      catch error
        callback error

  DefaultTemplate = new JadeStringTemplate jade.compile "!=page.html", options

  templateView = (env, locals, contents, templates, callback) ->
    ### Content view that expects content to have a @template instance var that
        matches a template in *templates*. Calls *callback* with output of template
        or null if @template is set to 'none'. ###

    if @template is 'none'
      template =  DefaultTemplate

    else
      template = templates[@template]
      if not template?
        callback new Error "page '#{ @filename }' specifies unknown template '#{ @template }'"
        return

    ctx = {page: this}
    env.utils.extend ctx, locals
    template.render ctx, callback

  class JadePlugin extends env.plugins.Page

    constructor: (@filepath, @metadata, @tpl) ->

    getFilename: ->
      @filepath.relative.replace /jade$/, 'html'

    getHtml: ->
      ### render jade template using metadata as locals ###
      @tpl @metadata

    getView: -> 'template'

  JadePlugin.fromFile = (filepath, callback) ->
    async.waterfall [
      (callback) -> fs.readFile filepath.full, callback
      (buffer, callback) ->
        # extract metadata using wintersmiths markdown plugin's markdown parser
        env.plugins.MarkdownPage.extractMetadata buffer.toString(), callback
      (result, callback) ->
        try
          opts = {filename: filepath.full}
          env.utils.extend opts, options
          tpl = jade.compile result.markdown, opts
        catch error
          callback error
          return
        callback null, new JadePlugin(filepath, result.metadata, tpl)
    ], callback

  env.registerView 'template', templateView
  env.registerContentPlugin 'pages', '**/*.jade', JadePlugin
  callback() # tell the plugin manager we are done
