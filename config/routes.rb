ActionController::Routing::Routes.draw do |map|
  map.resources :pastes, :only => [:index, :show],
    :member => { :download => :get }
  map.resources :pastes, :path_prefix => '/projects/:project_id',
    :member => { :download => :get }
end
