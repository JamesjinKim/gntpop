class DefectAnalysisService
  def initialize(from, to)
    @from = from
    @to = to
    @results = ProductionResult.where(created_at: @from.beginning_of_day..@to.end_of_day)
  end

  def summary
    total_good = @results.sum(:good_qty)
    total_defect = @results.sum(:defect_qty)
    total = total_good + total_defect
    inspection_count = InspectionResult.where(insp_date: @from..@to).count

    {
      total_production: total,
      total_good: total_good,
      total_defect: total_defect,
      defect_rate: total.positive? ? (total_defect.to_f / total * 100).round(2) : 0,
      inspection_count: inspection_count
    }
  end

  def pareto_by_defect_code
    DefectRecord
      .joins(:production_result, :defect_code)
      .where(production_results: { created_at: @from.beginning_of_day..@to.end_of_day })
      .group("defect_codes.name")
      .order("sum_defect_qty DESC")
      .sum(:defect_qty)
  end

  def defect_rate_by_process
    @results
      .joins(:manufacturing_process)
      .group("manufacturing_processes.process_name")
      .select(
        "manufacturing_processes.process_name as name",
        "SUM(defect_qty) * 100.0 / NULLIF(SUM(good_qty + defect_qty), 0) as rate"
      )
      .map { |r| [ r.name, r.rate&.round(2) || 0 ] }
      .to_h
  end

  def defect_rate_by_product
    @results
      .joins(work_order: :product)
      .group("products.product_name")
      .select(
        "products.product_name as name",
        "SUM(defect_qty) * 100.0 / NULLIF(SUM(good_qty + defect_qty), 0) as rate"
      )
      .map { |r| [ r.name, r.rate&.round(2) || 0 ] }
      .to_h
  end

  def daily_defect_trend
    @results
      .group_by_day(:created_at, range: @from..@to)
      .sum(:defect_qty)
  end
end
