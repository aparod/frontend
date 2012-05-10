Frontend::Application.routes.draw do
  match '/', :to => 'users#index'
end
