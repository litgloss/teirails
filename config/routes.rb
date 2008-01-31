ActionController::Routing::Routes.draw do |map|

  map.resources :users, :member => {
    :suspend   => :put,
    :unsuspend => :put,
    :purge     => :delete
  }

  map.resources :contents, :member => {
    :annotatable => :get
  }

  # The annotea server!
  map.resources :annotations, :member => {
    :body => :get
  }

  map.resource :session

  map.resource :profile

  ###
  # Map certain URLs to more intuitive paths.
  ###
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login  '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  map.activate '/activate/:activation_code', :controller =>
    'users', :action => 'activate'


  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "welcome"
end
