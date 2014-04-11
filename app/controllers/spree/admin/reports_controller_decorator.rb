require_dependency 'spree/admin/reports_controller'

Spree::Admin::ReportsController.class_eval do
  # until https://github.com/spree/spree/issues/1863 is taken care of
  # this is a workaround hack to get the report definitions to load


  I18n.locale = Rails.application.config.i18n.default_locale
  I18n.reload!

  # TODO there has got to be a more ruby way to do this...


#  ADVANCED_REPORTS ||= {}
#  [ :outstanding, :revenue, :units, :profit, :count, :top_products, :top_customers, :geo_revenue, :geo_units, :geo_profit, :transactions].each do |x|
#    # TODO we should pull the name + description for the report models themselves rather than redefining them as I18n definitions
#    ADVANCED_REPORTS[x]= {name: I18n.t("adv_report.#{x}"), :description => I18n.t("adv_report.#{x}")}
#  end
#
#  Spree::Admin::ReportsController::AVAILABLE_REPORTS.merge!(ADVANCED_REPORTS)




  before_filter :basic_report_setup , :only => [:index]
   
  def basic_report_setup
    Spree::Admin::ReportsController.add_available_report! :outstanding , :outstanding
    Spree::Admin::ReportsController.add_available_report! :revenue 
    Spree::Admin::ReportsController.add_available_report! :units
    Spree::Admin::ReportsController.add_available_report! :profit
    Spree::Admin::ReportsController.add_available_report! :count
    Spree::Admin::ReportsController.add_available_report! :top_products
    Spree::Admin::ReportsController.add_available_report! :top_customers
    Spree::Admin::ReportsController.add_available_report! :geo_revenue
    Spree::Admin::ReportsController.add_available_report! :geo_units
    Spree::Admin::ReportsController.add_available_report! :geo_profit   
    @reports =  Spree::Admin::ReportsController.available_reports
    @products = Spree::Product.all
    @taxons = Spree::Taxon.all
    if defined?(MultiDomainExtension)
      @stores = Store.all
    end
  end

  def geo_report_render(filename)
    params[:advanced_reporting] ||= {}
    params[:advanced_reporting]["report_type"] = params[:advanced_reporting]["report_type"].to_sym if params[:advanced_reporting]["report_type"]
    params[:advanced_reporting]["report_type"] ||= :state
    respond_to do |format|
      format.html { render :template => "spree/admin/reports/geo_base" }
      format.csv { send_data @report.ruportdata[params[:advanced_reporting]['report_type']].to_csv }
    end
  end

  def base_report_top_render(filename)
    respond_to do |format|
      format.html { render :template => "spree/admin/reports/top_base" }
      format.csv { send_data view_context.strip_tags(@report.ruportdata.to_csv) }
    end
  end

  def base_report_render(filename)
    params[:advanced_reporting] ||= {}
    params[:advanced_reporting]["report_type"] = params[:advanced_reporting]["report_type"].to_sym if params[:advanced_reporting]["report_type"]
    params[:advanced_reporting]["report_type"] ||= I18n.t("adv_report.daily").downcase.to_sym
    respond_to do |format|
      format.html { render :template => "spree/admin/reports/increment_base" }
      format.csv do
        if params[:advanced_reporting]["report_type"] == :all
          send_data @report.all_data.to_csv
        else
          send_data @report.ruportdata[params[:advanced_reporting]['report_type']].to_csv
        end
      end
    end
  end
  
  def outstanding
    @orders = Spree::Order.complete.where("state != 'canceled'").select{ |o| o.outstanding_balance? }
    @outstanding_balance = @orders.inject(0){ |outstanding, o| outstanding += o.outstanding_balance }
  end

  def revenue
    @report = Spree::AdvancedReport::IncrementReport::Revenue.new(params)
    base_report_render("revenue")
  end

  def units
    @report = Spree::AdvancedReport::IncrementReport::Units.new(params)
    base_report_render("units")
  end

  def profit
    @report = Spree::AdvancedReport::IncrementReport::Profit.new(params)
    base_report_render("profit")
  end

  def count
    @report = Spree::AdvancedReport::IncrementReport::Count.new(params)
    base_report_render("profit")
  end

  def top_products
    @report = Spree::AdvancedReport::TopReport::TopProducts.new(params, 4)
    base_report_top_render("top_products")
  end

  def top_customers
    @report = Spree::AdvancedReport::TopReport::TopCustomers.new(params, 4)
    base_report_top_render("top_customers")
  end

  def geo_revenue
    @report = Spree::AdvancedReport::GeoReport::GeoRevenue.new(params)
    geo_report_render("geo_revenue")
  end

  def geo_units
    @report = Spree::AdvancedReport::GeoReport::GeoUnits.new(params)
    geo_report_render("geo_units")
  end

  def geo_profit
    @report = Spree::AdvancedReport::GeoReport::GeoProfit.new(params)
    geo_report_render("geo_profit")
  end

  def transactions
    @report = Spree::AdvancedReport::TransactionReport.new(params)
    base_report_top_render("transactions")
  end
end
