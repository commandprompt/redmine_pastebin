ActionController::Routing::Routes.draw do |map|
  map.resources :pastes
  map.resources :pastes, :path_prefix => '/projects/:project_id'
end
