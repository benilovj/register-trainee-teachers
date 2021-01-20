# frozen_string_literal: true

require_relative "routes/sidekiq_routes"

Rails.application.routes.draw do
  extend SidekiqRoutes

  get :ping, controller: :heartbeat
  get :healthcheck, controller: :heartbeat
  get :sha, controller: :heartbeat

  get "/home", to: "pages#home", as: :home
  get "/accessibility", to: "pages#accessibility", as: :accessibility
  get "/cookies", to: "pages#cookies", as: :cookies
  get "/privacy-policy", to: "pages#privacy_policy", as: :privacy_policy
  get "/pages/:page", to: "pages#show"
  get "/data-requirements", to: "pages#data_requirements"

  get "/404", to: "errors#not_found", via: :all
  get "/422", to: "errors#unprocessable_entity", via: :all
  get "/500", to: "errors#internal_server_error", via: :all

  get "/trainees/not-supported-route", to: "trainees/not_supported_routes#index"

  get "/sign-in" => "sign_in#index"
  get "/sign-out" => "sign_out#index"

  get "/sign-in/user-not-found", to: "sign_in#new"

  if FeatureService.enabled?("use_dfe_sign_in")
    get "/auth/dfe/callback" => "sessions#callback"
    get "/auth/dfe/sign-out" => "sessions#signout"
  else
    get "/personas", to: "personas#index"
    get "/auth/developer/sign-out", to: "sessions#signout"
    post "/auth/developer/callback", to: "sessions#callback"
  end

  concern :confirmable do
    resource :confirm_details, as: :confirm, only: %i[show update], path: "/confirm"
  end

  resources :trainees, except: :destroy do
    scope module: :trainees do
      resource :programme_details, concerns: :confirmable, only: %i[edit update], path: "/programme-details"
      resource :contact_details, concerns: :confirmable, only: %i[edit update], path: "/contact-details"
      resource :trainee_id, only: %i[edit update], path: "/trainee-id" do
        member do
          get "confirm", to: "trainee_ids#confirm"
        end
      end

      namespace :degrees do
        get "/new/type", to: "type#new"
        post "/new/type", to: "type#create"
      end

      resources :degrees do
        collection do
          resource :confirm_details, as: :degrees_confirm, only: %i[show update], path: "/confirm"
        end
      end

      resource :personal_details, concerns: :confirmable, only: %i[show edit update], path: "/personal-details"

      namespace :diversity do
        resource :disclosure, concerns: :confirmable, only: %i[edit update], path: "/information-disclosed"
        resource :ethnic_group, only: %i[edit update], path: "/ethnic-group"
        resource :ethnic_background, only: %i[edit update], path: "/ethnic-background"
        resource :disability_disclosure, concerns: :confirmable, only: %i[edit update], path: "/disability-disclosure"
        resource :disability_detail, concerns: :confirmable, only: %i[edit update], path: "/disabilities"
      end

      resource :outcome_details, only: [], path: "outcome-details" do
        get "confirm"
        get "recommended"
        resource :outcome_date, only: %i[edit update], path: "/outcome-date"
      end

      resource :qts_recommendations, only: %i[create]

      resource :confirm_withdrawal, only: %i[show update], path: "/withdraw/confirm"
      resource :withdrawal, only: %i[show update], path: "/withdraw"

      resource :confirm_deferral, only: %i[show update], path: "/defer/confirm"
      resource :deferral, only: %i[show update], path: "/defer"

      resource :timeline, only: :show
    end

    member do
      get "training-details", to: "trainees/training_details#edit", as: :training_details
      get "course-details", to: "trainees/course_details#edit"
      get "check-details", to: "trainees/check_details#show"
      get "review-draft", to: "trainees/review_draft#show"
    end
  end

  resources :trn_submissions, only: %i[create show], param: :trainee_id

  root to: "pages#show", defaults: { page: "start" }
end
