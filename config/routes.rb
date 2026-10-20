Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :tickets, only: %i[index show new create] do
    member do
      patch :transition
      patch :assign_to_me
      post :reveal
    end
    resources :comments, only: :create
  end

  # Musterinin gizli linkli talep sayfasi (giris gerektirmez; erisim yalnizca tahmin edilemeyen anahtarla).
  get "t/:token" => "customer_tickets#show", as: :customer_ticket
  post "t/:token/reply" => "customer_tickets#reply", as: :customer_ticket_reply

  # Ajanlar icin JSON API (agent-first). Kimlik: Authorization: Bearer <AGENT_API_TOKEN>. Bkz. public/llms.txt
  namespace :api do
    namespace :v1 do
      post "tickets" => "tickets#create", as: :tickets
      get "tickets/:token" => "tickets#show", as: :ticket
      post "tickets/:token/replies" => "tickets#reply", as: :ticket_replies
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Render bu adresi saglik kontrolu olarak kullaniyor (bkz. AGENT.md).
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
