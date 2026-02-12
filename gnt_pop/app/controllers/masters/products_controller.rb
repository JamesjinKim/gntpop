# frozen_string_literal: true

module Masters
  # 제품 마스터 관리 컨트롤러
  # 제품 코드, 제품명, 제품군, 사양, 단위 등을 CRUD 관리
  class ProductsController < ApplicationController
    before_action :set_product, only: [ :edit, :update, :destroy ]

    # GET /masters/products
    def index
      @q = Product.ransack(params[:q])
      @pagy, @products = pagy(@q.result.order(created_at: :desc))
    end

    # GET /masters/products/new
    def new
      @product = Product.new
    end

    # POST /masters/products
    def create
      @product = Product.new(product_params)

      if @product.save
        redirect_to masters_products_path, notice: "제품이 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /masters/products/:id/edit
    def edit
    end

    # PATCH/PUT /masters/products/:id
    def update
      if @product.update(product_params)
        redirect_to masters_products_path, notice: "제품이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /masters/products/:id
    def destroy
      @product.destroy!
      redirect_to masters_products_path, notice: "제품이 삭제되었습니다."
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to masters_products_path, alert: "관련 작업지시가 있어 삭제할 수 없습니다."
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :product_code,
        :product_name,
        :product_group,
        :spec,
        :unit,
        :is_active
      )
    end
  end
end
