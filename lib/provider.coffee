fs = require 'fs'
path = require 'path'

extReg = /(Ext.*)/
startExtReg = /^Ext/

module.exports =
    selector: '.source.js'
    disableForSelector: '.source.js .comment'

    # This will take priority over the default provider, which has a priority of 0.
    # `excludeLowerPriority` will suppress any providers with a lower priority
    # i.e. The default provider will be suppressed
    inclusionPriority: 1
    excludeLowerPriority: true

    onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
        @currentObject = @currentObject[suggestion.key]

    getSuggestions: (request) ->
        # console.log 'getSuggestions'
        # console.log request
        {prefix} = request
        @selector = @getSelector(request.editor, request.bufferPosition)

        if @hasExtSelector()
            sugs = @getExtCompletion(prefix)
        else
            sugs = []
        return sugs

    hasExtSelector: () ->
        # console.log 'hasExtSelector'
        return extReg.test(@selector)

    getSelector: (editor, bufferPosition) ->
        lineString = editor.getTextInRange(
            [[bufferPosition.row, 0], bufferPosition]);
        return lineString.slice(lineString.indexOf("Ext"));

    getExtCompletion: (prefix) ->
        completions = []

        # if our selector starts with "Ext" split it on every dot
        if startExtReg.test(@selector)
            hierarchy = @selector.split('.')

        # if our prefix is "Ext" we set our @currentObject to the rootNode
        if prefix is "Ext"
            @currentObject = @jsonData.Ext

        #TODO determine if we are in Ext.create or Ext.define then get the clas
        #to get the properties and methods
        # We got an class node so we have to do special config and method
        # stuff
        # if @currentObject.configs
        #     for config in @currentObject.configs
        #         completions.push(@buildConfigsCompletion(config))
        # if @currentObject.methods
        #     for method in @currentObject.methods
        #         completions.push(@buildMethodsCompletion(method))

        # if our object has an className we have a class
        if @currentObject.className
            completions.push(@buildConstructorCompletion(@currentObject))
        else
            for key, value of @currentObject
                # If last typed level of object fits alphabetically
                # or we just got a dot
                if key.indexOf(hierarchy[hierarchy.length - 1]) > -1 or prefix is '.'
                    completions.push(@buildExtCompletion(key, value))
        completions

    buildExtCompletion: (key, value) ->
        # console.log key
        # text: @getText(clazz)
        key: key
        displayText: @selector + key # TODO refactor
        snippet: @getSnippet(key)
        type: @getType(key)
        leftLabel: 'Ext'
        description: key
        descriptionMoreURL: @getDocsURL(key)

    buildConstructorCompletion: (object) ->
        # console.log 'buildConstructorCompletion'
        # console.log object
        # text: @getText(clazz)
        key: object
        displayText: "new #{object.className}"
        snippet: @getConstructorSnippet(object)
        type:'class'
        leftLabel: 'Ext'
        rightLabel: 'Constructor'
        description: "Uses Ext.create to build a new #{object.className}."
        descriptionMoreURL: @getDocsURL(object.className)

    buildConfigsCompletion: (config) ->
        # console.log 'buildConfigCompletion'
        # console.log config
        # text: @getText(clazz)
        key: config
        displayText: @selector + config # TODO refactor
        snippet: @getConfigSnippet(config)
        type: 'property'
        leftLabel: 'Ext'
        description: config
        descriptionMoreURL: @getDocsURL(config)

    buildMethodsCompletion: (method) ->
        # console.log 'buildMethodCompletion'
        # console.log method
        # text: @getText(clazz)
        key: method
        displayText: @selector + method # TODO refactor
        snippet: @getMethodSnippet(method)
        type:'method'
        leftLabel: 'Ext'
        description: method
        descriptionMoreURL: @getDocsURL(method)

    getDocsURL: (key) ->
        "http://docs.sencha.com/extjs/6.0/6.0.0-classic/#!/api/#{key}"

    getSnippet: (key) ->
        # console.log 'getSnippet'
        switch key
          when 'Ext' then
            # body...
        return key

    getConstructorSnippet: (object) ->
        console.log 'getConstructorSnippet'
        console.log object
        snippet = "Ext.create('#{object.className}',\n$1\n});"

    getConfigSnippet: (config) ->
        console.log 'getConfigSnippet'
        console.log config
        snippet = "#{config.name}: ${1:#{config.type}}"
        return snippet

    getMethodSnippet: (method) ->
        # console.log 'getSnippet'
        switch method
          when 'Ext' then
            # body...
        return method

    getType: (key) ->
        return 'type'

    getText: (key) ->
        return 'text'

    loadCompletions: ->
        # console.log 'loadCompletions'
        @jsonData = {}
        fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
            @jsonData = JSON.parse(content) unless error?
        return
