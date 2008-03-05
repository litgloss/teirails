ActionController::Routing::Routes.draw do |map|

  map.resources :users, :member => {
    :suspend   => :put,
    :unsuspend => :put,
    :purge     => :delete
  } do |user|
    user.resource :profile
    user.resource :account
  end

  map.resources :content_items, :member => {
    :annotatable => :get
  }, :collection => {
    :system => :get,
    :unpublished => :get,
    :by_author => :get,
    :by_title => :get,
    :by_language => :get,
    :search => :get

  } do |content_item|


    content_item.resources :clones

    content_item.resources :litglosses
    
    content_item.resources :versions, :member => {
      :revert_to => :post
    }
  end

  map.resources :images, :member => {
    :stream => :get
  }

  map.resources :audio_files, :member => {
    :stream => :get
  }

  map.resources :editorial_options

  map.resources :administrative_options

  map.resources :system_settings

  map.resource :install, :controller => 'install'

  map.resources :content_item_groups, :member => {
    :move_higher => :post,
    :move_lower => :post,
    :move_to_top => :post,
    :move_to_bottom => :post
  } do |content_item_group|
    content_item_group.resources :links, :controller => "content_item_group_links"

    content_item_group.resources :manage_positions, :member => {
      :move_higher => :post,
      :move_lower => :post,
      :move_to_top => :post,
      :move_to_bottom => :post
    }
  end

  # The annotea server.  XXX - code generating this
  # route needs to be moved to the acts_as_annotea_server
  # plugin.
  map.resources :annotations, :member => {
    :body => :get
  }

  map.resource :session

  map.resources :passwords

  ###
  # Map certain URLs to more intuitive paths.
  ###
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login  '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  map.activate '/activate/:activation_code', :controller =>
    'users', :action => 'activate'

  map.forgot_password '/forgot_password', :controller => 
    'passwords', :action => 'new'

  map.reset_password '/reset_password/:id', :controller => 
    'passwords', :action => 'edit'

  map.resource :search, :controller => :search

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "welcome"
end
