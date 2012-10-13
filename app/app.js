// Generated by CoffeeScript 1.3.3
(function() {

  define(function(require) {
    var $, CodeEditorView, CsgProcessor, GlThreeView, Library, LoadView, MainContentLayout, MainMenuView, ModalRegion, Project, ProjectFile, ProjectView, SaveView, Settings, SettingsView, app, bla, marionette, modTest, testcode, _;
    $ = require('jquery');
    _ = require('underscore');
    marionette = require('marionette');
    require('bootstrap');
    CodeEditorView = require("views/codeView");
    MainMenuView = require("views/menuView");
    ProjectView = require("views/projectsview");
    bla = require("modules/project");
    ProjectFile = bla[0];
    Project = bla[1];
    Library = bla[2];
    modTest = require("views/fileSaveLoadView");
    ModalRegion = modTest[0];
    SaveView = modTest[1];
    LoadView = modTest[2];
    SettingsView = modTest[3];
    Settings = require("modules/settings");
    CsgProcessor = require("modules/csg.processor");
    MainContentLayout = require("views/mainContentView");
    GlThreeView = require("views/glThreeView");
    testcode = "class CubeClass\n  width:20\n  length:20\n  height:20\n  constructor: (@pos=[0,0,0], @rot=[0,0,0]) ->\n    return @render()\n  \n  render: =>\n    result = new CSG()\n    cube1 =CSG.cube({center: [0, 0, @height/2],radius: [@width/2, @length/2, @height/2]})\n    result = cube1\n    return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2]) \n\ncubeStuff = new CubeClass()\nreturn cubeStuff";
    app = new marionette.Application({
      root: "/opencoffeescad",
      cadProcessor: null,
      updateSolid: function() {
        return app.cadProcessor.setCoffeeSCad(app.cadEditor.getValue());
      }
    });
    app.addRegions({
      navigationRegion: "#navigation",
      mainRegion: "#mainContent",
      statusRegion: "#statusBar",
      modal: ModalRegion
    });
    app.on("start", function(opts) {
      return console.log("at start");
    });
    app.on("initialize:after", function() {
      return console.log("after init");
    });
    app.addInitializer(function(options) {
      var displayTheThing, displayTheThing2,
        _this = this;
      app.settings = new Settings;
      app.csgProcessor = new CsgProcessor;
      app.lib = new Library;
      app.project = new Project({
        name: "MyProject",
        content: "this is the first project's content"
      });
      app.project2 = new Project({
        name: "toto",
        content: "something completely different"
      });
      app.lib.add(app.project);
      app.lib.add(app.project2);
      app.model = new ProjectFile({
        name: "main",
        ext: "coscad",
        content: testcode
      });
      app.codeEditorView = new CodeEditorView({
        model: this.model
      });
      app.mainMenuView = new MainMenuView({
        model: this.lib
      });
      app.projectView = new ProjectView({
        collection: this.lib
      });
      app.glThreeView = new GlThreeView;
      app.mainContentLayout = new MainContentLayout;
      this.mainRegion.show(this.mainContentLayout);
      this.mainContentLayout.edit.show(this.codeEditorView);
      this.mainContentLayout.gl.show(this.glThreeView);
      app.navigationRegion.show(app.mainMenuView);
      app.statusRegion.show(app.projectView);
      app.modal.app = app;
      displayTheThing = function(params) {
        console.log("SaveRequested");
        return console.log("params: " + params);
      };
      displayTheThing2 = function(params) {
        console.log("LoadRequested");
        return console.log("params: " + params);
      };
      app.vent.bind("fileSaveRequest", displayTheThing);
      app.vent.bind("fileLoadRequest", displayTheThing2);
      app.mainMenuView.on("project:new:mouseup", function() {});
      app.mainMenuView.on("file:new:mouseup", function() {
        console.log("newfile");
        _this.project.remove(_this.model);
        _this.model = new ProjectFile({
          name: "main",
          ext: "coscad",
          content: ""
        });
        _this.project.add(_this.model);
        _this.codeEditorView.close();
        _this.codeEditorView = new CodeEditorView({
          model: _this.model
        });
        return _this.mainRegion.show(_this.codeEditorView);
      });
      app.mainMenuView.on("file:save:mouseup", function() {
        app.modView = new SaveView;
        app.modal.show(_this.modView);
        return console.log("savefile");
        /*
              @project.save null,
                success: (project, response) ->
                  console.log "sucess"
                  #console.log project
                error: (project, response) ->
                  console.log 'failed'
        */

      });
      app.mainMenuView.on("file:load:mouseup", function() {
        app.modView = new LoadView;
        app.modal.show(_this.modView);
        return console.log("loadfile");
        /*
              @project.fetch 
                success: (project, response)=> 
                  console.log "sucess"
                  @codeEditorView = new CodeEditorView
                    model: @model
                  @mainRegion.show @codeEditorView
                error: -> 
                  console.log "error"
        */

      });
      app.mainMenuView.on("settings:mouseup", function() {
        app.modView = new SettingsView({
          model: app.settings
        });
        return app.modal.show(_this.modView);
      });
      return app.project.on("change", function() {
        return console.log("project changed");
      });
    });
    /*return _.extend app,
      module: (additionalProps)->
        return _.extend
          Views: {}
          additionalProps
    */

    return app;
  });

}).call(this);
