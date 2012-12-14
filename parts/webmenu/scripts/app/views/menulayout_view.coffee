define [
  "backbone.viewmaster"

  "cs!app/views/itemdescription_view"
  "cs!app/views/menulist_view"
  "cs!app/views/breadcrumbs_view"
  "cs!app/views/profile_view"
  "cs!app/views/favorites_view"
  "cs!app/views/search_view"
  "cs!app/views/search_result_view"
  "cs!app/application"
  "hbs!app/templates/menulayout"
  "app/utils/debounce"
], (
  ViewMaster

  ItemDescriptionView
  MenuListView
  Breadcrumbs
  ProfileView
  Favorites
  Search
  SearchResult
  Application
  template
  debounce
) ->

  class MenuLayout extends ViewMaster

    className: "bb-menu"

    template: template

    constructor: (opts) ->
      super

      @allItems = opts.allItems
      @user = opts.user
      @config = opts.config

      @menuListView = new MenuListView
        model: opts.initialMenu
        collection: opts.allItems

      @setView ".menu-app-list-container", @menuListView

      if FEATURE_SEARCH
        @setView ".search-container", new Search

      @setView ".breadcrums-container", new Breadcrumbs
        model: opts.initialMenu

      @setView ".sidebar", new ProfileView
        model: @user
        config: @config

      @setView ".favorites", new Favorites
        collection: @allItems
        config: @config

    reset: ->
      @menuListView.setRoot()
      @menuListView.refreshViews()



