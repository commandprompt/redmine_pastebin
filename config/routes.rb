ActionController::Routing::Routes.draw do |map|
  # new paste can be only created on a project
  map.resources :pastes, :except => :new,
    :member => { :download => :get }

  map.resources :pastes, :path_prefix => '/projects/:project_id',
    :member => { :download => :get }
end
