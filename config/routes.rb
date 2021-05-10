Rails.application.routes.draw do
  get 'pages/home'
  post 'pages/upload'

  post 'api_upload', to: 'pages#api_upload'#, as: :grab_hook
  post 'api_remove_css', to: 'pages#api_remove_css'#, as: :grab_hook


  root 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
