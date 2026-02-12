Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # 생산 관리 라우트
  namespace :productions do
    resources :work_orders do
      member do
        patch :start    # 작업 시작
        patch :complete # 작업 완료
        patch :cancel   # 작업 취소
      end
    end
    resources :production_results
    resources :lot_tracking, only: [ :index, :show ], param: :lot_no
  end

  # 품질관리 라우트
  namespace :quality do
    resources :inspections
    get "defect_analysis", to: "defect_analysis#index"
    get "spc", to: "spc#index"
  end

  # 모니터링 라우트
  namespace :monitoring do
    get "production_board", to: "production_board#index"
    resources :equipment_status, only: [ :index ] do
      member do
        patch :change_status
      end
    end
  end

  # 기준정보 마스터 라우트
  namespace :masters do
    resources :products
    resources :manufacturing_processes
    resources :equipments
    resources :workers
    resources :defect_codes
  end

  # Defines the root path route ("/")
  root "dashboard#index"
end
