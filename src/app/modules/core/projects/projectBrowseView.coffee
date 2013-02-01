define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  contextMenu = require 'contextMenu'
  marionette = require 'marionette'
  jstree = require 'jquery_jstree'
  
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  
  projectBrowserTemplate = require "text!./projectBrowser.tmpl"
  rootTemplate = $(projectBrowserTemplate).filter('#projectBrowserTmpl')
  projectStoreListTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreListTmpl').html())
  projectStoreTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreTmpl').html())
  
  
  class ProjectBrowserView extends Backbone.Marionette.Layout
    template:rootTemplate
    
    regions:
      projectStores: "#projectStores"
      projectFiles : "#projectFiles"
    
    ui:
      fileNameInput : "#fileName"
      projectThumbNail: "#projectThumbNail"
      validationButton: "#validateOperationBtn"
      
    events:
      "click .newProject":   "onProjectNewRequested"
      "click .saveProject":  "onProjectSaveRequested"
      "click .loadProject":  "onProjectLoadRequested"

    constructor:(options) ->
      super options
      @operation = options.operation ? "save"
      @connectors = options.connectors ? {}
      @vent = vent
      @vent.on("project:created",@onOperationSucceeded)
      @vent.on("project:saved",@onOperationSucceeded)
      @vent.on("project:loaded",@onOperationSucceeded)
      @vent.on("project:selected",(id)=>$(@ui.fileNameInput).val(id))
      
    serializeData:->
      operation: @operation
      name: @model.get("name")
     
    onRender:=>
      tmpCollection = new Backbone.Collection()
      for name, connector of @connectors
        #hack, to inject current, existing project to sub views (for saving only)
        connector.targetProject = @model
        tmpCollection.add connector
       
      @projectStores.show new ProjectsStoreView
        collection:tmpCollection
        model: @model
        
      if @operation is "save"
        screenshotPromise = reqRes.request("project:getScreenshot")
        doScreenShotRes=(screenshotUrl)=>
          @ui.projectThumbNail.attr("src",screenshotUrl)
          @model.createFile
            name:".thumbnail"
            content:screenshotUrl
            ext:"png"  
        $.when(screenshotPromise).done(doScreenShotRes)
        
      else if @operation is "load"
        $(@ui.fileNameInput).attr("readonly", "readonly")
    
    onProjectNewRequested:=>
      fileName = @ui.fileNameInput.val()
      vent.trigger("project:newRequest", fileName)
      
    onProjectSaveRequested:=>
      fileName = @ui.fileNameInput.val()
      vent.trigger("project:saveRequest", fileName)
      
      #most of our job is done, disable the view
      @ui.validationButton.attr("disabled",true)
      @projectStores.close()
      
    onProjectLoadRequested:=>
      fileName = $(@ui.fileNameInput).val()
      vent.trigger("project:loadRequest", fileName)
      
      ###
      if @model.dirty
        bootbox.dialog "Project is unsaved, proceed anyway?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            @CreateNewProject()
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
      ###
      #most of our job is done, disable the view
      @ui.validationButton.attr("disabled",true)
      @projectStores.close()
    
    onOperationSucceeded:=>
      @close()
      
    onClose:->
      #clean up events
      @vent.off("project:saved",@onOperationSucceeded)
      @vent.off("project:loaded",@onOperationSucceeded)
      @vent.off("project:selected",(id)=>$(@ui.fileNameInput).val(id))
  
  
  class StoreView extends Backbone.Marionette.ItemView
    template:projectStoreTemplate
    ui: 
      projects: "#projects"
    events:
      "click .accordion-heading" : "onStoreSelected"
      "click .projectSelector" : "onProjectSelected"
     
    constructor:(options)->
      super options
      #hack
      @selected = false
      vent.on("project:newRequest", @onCreateRequested)
      vent.on("project:saveRequest",@onSaveRequested)
      vent.on("project:loadRequest",@onLoadRequested)
      vent.on("connector:selected", @onStoreSelected)
    
    onStoreSelected:(name)=>
      if name.currentTarget?
        if @selected
          @selected = false
          header = @$el.find(".connector-header")
          header.removeClass('alert-info')
        else
          @selected = true
          header = @$el.find(".connector-header")
          header.addClass('alert-info')
          vent.trigger("connector:selected",@model.get("name"))
      else
        if name != @model.get("name")
          @selected = false
          header = @$el.find(".connector-header")
          header.removeClass('alert-info')
        else
          @selected = true
          header = @$el.find(".connector-header")
          header.addClass('alert-info')
    
    onProjectSelected:(e)=>
      e.preventDefault()
      id = $(e.currentTarget).attr("id")
      vent.trigger("project:selected",id)
      
      vent.trigger("connector:selected",@model.get("name"))
      @trigger("project:selected", @model)
    
    onCreateRequested:(fileName)=>
      if @selected
        @model.createProject(fileName)
    
    onSaveRequested:(fileName)=>
      if @selected
        #console.log "save to #{fileName} requested"
        projectToSave = @model.targetProject
        if projectToSave?
          projectToSave.rename(fileName)
          @model.saveProject(projectToSave)
    
    onLoadRequested:(fileName)=>
      if @selected
        @model.loadProject(fileName)
    
    onRender:->
      @model.getProjectsName(@onProjectsFetched)
      #@$el.attr("href","#")
      #@$el.attr("data-target","#context-menu")
      #@$el.contextmenu()
      #@delegateEvents()
      
    onProjectsFetched:(projectNames)=>
      #console.log "projectNames #{projectNames}"
      #console.log @
      for name in projectNames
        @ui.projects.append("<li><a id=#{name} class='projectSelector' href='#' data-toggle='context' data-target='#context-menu'>#{name}  </a></li>")
          
      @delegateEvents()
      
    onClose:->
      #clean up events
      vent.off("project:saveRequest",@onSaveRequested)
      vent.off("project:loadRequest",@onLoadRequested)
      vent.off("connector:selected",@onStoreSelected)
    
  class ProjectsStoreView extends Backbone.Marionette.CompositeView
    template:projectStoreListTemplate
    itemView:StoreView
    
    constructor:(options)->
      super options
      @currentStore = null
      @on("itemview:project:selected",@toto)
    
    toto:(childView, connector)=>
      console.log connector
      
    onRenderOLD:->
      @ui.treeTest.jstree 
        "core":
          "animation":0
        "plugins" : ["html_data","ui","contextmenu","themeroller"]
        "html_data" : 
          "data" : """
          <li id='root'>
            <a href='#'>Root node</a>
            <ul><li><a href='#'>Child node</a></li></ul>
            <ul><li><a href='#'>Child node2</a></li></ul>
            <ul>
              <li>
                <a href='#'>Child node2</a>
                <ul>
                  <li><a href='#'>Child node2 sub 1</a></li>
                </ul>
              </li>
            </ul>
          </li>"""

  return ProjectBrowserView