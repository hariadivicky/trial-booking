Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "sign_in" => "sessions#new"
  post "sign_in" => "sessions#create"
  get "sign_in/otp" => "otps#show"
  post "sign_in/otp" => "otps#create"
  delete "sign_out" => "sessions#destroy"
  get "sign_up" => "registrations#new"
  post "sign_up" => "registrations#create"
  get "checkout/:trial_class_id" => "checkouts#show", as: :checkout
  post "checkout/:trial_class_id" => "checkouts#create"
  get "pay/:booking_id" => "payments#show", as: :payment
  post "pay/:booking_id" => "payments#create"
  resources :bookings, only: :show do
    resources :payment_attempts, only: :index
  end
  resources :payment_attempts, only: :index
  get "trial_classes/:trial_class_id/roster" => "rosters#show", as: :roster
  post "demo_reset" => "demo_resets#create"

  root "home#index"
end
