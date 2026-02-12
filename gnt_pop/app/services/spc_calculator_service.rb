class SpcCalculatorService
  # X-bar R chart constants (subgroup size n=5)
  A2 = 0.577
  D3 = 0.0
  D4 = 2.114

  def initialize(item_name, from, to)
    @item_name = item_name
    @from = from
    @to = to
    @items = InspectionItem
      .joins(:inspection_result)
      .where(item_name: item_name)
      .where(inspection_results: { insp_date: from..to })
      .where.not(measured_value: nil)
      .order("inspection_results.insp_date")
  end

  def xbar_chart_data
    subgroups.map { |date, values| [ date.to_s, mean(values).round(4) ] }
  end

  def r_chart_data
    subgroups.map { |date, values| [ date.to_s, (values.max - values.min).round(4) ] }
  end

  def control_limits
    return empty_limits if subgroups.empty?

    xbar_values = subgroups.map { |_, v| mean(v) }
    r_values = subgroups.map { |_, v| v.max - v.min }

    x_double_bar = mean(xbar_values)
    r_bar = mean(r_values)

    {
      xbar: {
        ucl: (x_double_bar + A2 * r_bar).round(4),
        cl: x_double_bar.round(4),
        lcl: (x_double_bar - A2 * r_bar).round(4)
      },
      r: {
        ucl: (D4 * r_bar).round(4),
        cl: r_bar.round(4),
        lcl: (D3 * r_bar).round(4)
      }
    }
  end

  def process_capability
    all_values = @items.pluck(:measured_value).compact.map(&:to_f)
    return { cp: nil, cpk: nil, data_count: 0 } if all_values.size < 2

    sigma = std_dev(all_values)
    return { cp: nil, cpk: nil, data_count: all_values.size } if sigma.zero?

    avg = mean(all_values)
    usl = avg + 3 * sigma
    lsl = avg - 3 * sigma

    cp = ((usl - lsl) / (6 * sigma)).round(3)
    cpu = ((usl - avg) / (3 * sigma)).round(3)
    cpl = ((avg - lsl) / (3 * sigma)).round(3)
    cpk = [ cpu, cpl ].min.round(3)

    { cp: cp, cpk: cpk, data_count: all_values.size }
  end

  private

  def subgroups
    @subgroups ||= begin
      values = @items.pluck("inspection_results.insp_date", :measured_value)
      values.group_by(&:first)
            .transform_values { |pairs| pairs.map { |_, v| v.to_f } }
            .select { |_, v| v.size >= 2 }
    end
  end

  def empty_limits
    {
      xbar: { ucl: 0, cl: 0, lcl: 0 },
      r: { ucl: 0, cl: 0, lcl: 0 }
    }
  end

  def mean(arr)
    return 0.0 if arr.empty?
    arr.sum.to_f / arr.size
  end

  def std_dev(arr)
    return 0.0 if arr.size < 2
    avg = mean(arr)
    Math.sqrt(arr.sum { |v| (v - avg)**2 } / (arr.size - 1))
  end
end
