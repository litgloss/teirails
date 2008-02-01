ActionController::Routing::Routes.draw do |map|

  map.resources :users, :member => {
    :suspend   => :put,
    :unsuspend => :put,
    :purge     => :delete
  } do |user|
    user.resource :profile
  end

  map.resources :contents, :member => {
    :annotatable => :get
  }

  map.resources :images, :member => {
    :stream => :get
  }

  # The annotea server!
  map.resources :annotations, :member => {
    :body => :get
  }

  map.resource :session


  ###
  # Map certain URLs to more intuitive paths.
  ###
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login  '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  map.activate '/activate/:activation_code', :controller =>
    'users', :action => 'activate'

  map.resource :search, :controller => :search

  # Might be a placeholder for a while.
  map.resource :my_litgloss, :controller => :my_litgloss

  map.resource :about, :controller => :about, :member => {
    :welcome => :get,
    :mission => :get,
    :supporters => :get,
    :contributors => :get,
    :statistics => :get,
    :awards => :get
  }

  map.resource :search, :controller => :search

  map.resource :help, :controller => :help, :member => {
    :selecting => :get,
    :reading => :get,
    :uploading => :get,
    :editing => :get
  }

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "about"
end
