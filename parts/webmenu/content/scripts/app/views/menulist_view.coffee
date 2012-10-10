define [
  "cs!app/views/layout"
  "cs!app/views/menuitem_view"
  "hbs!app/templates/menulist"
  "backbone"
], (
  Layout
  MenuItemView
  template
  Backbone
) ->
  class MenuListView extends Layout

    className: "bb-menu"

    template: template

    constructor: ->
      super

      if @model.get("type") isnt "menu"
        throw new Error "Bad menu list model type: #{ @model.get("type") }"

      @_setView ".menu-app-list", @model.items.map (model) ->
        new MenuItemView
          model: model

