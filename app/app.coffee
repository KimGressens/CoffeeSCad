define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  require 'bootstrap'
  require 'bootbox'
  
  
  ###############################
 
  app = new Backbone.Marionette.Application
    root: "/coffeescad"
  # Mix Backbone.Events, modules, and layout management into the app object.
  ###return _.extend app,
    module: (additionalProps)->
      return _.extend
        Views: {}
        additionalProps
  ###
  return app