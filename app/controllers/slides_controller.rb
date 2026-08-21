class SlidesController < ApplicationController
  PER_PAGE = 25

  def index
    authorize Slide
    @filters = params.permit(:q, :match, :slide_uid, :case_id, :patient_id, :barcode, :scanner, :hospital, :department, :slide_type, :stain, :status, :decision, :acquisition_from, :acquisition_to, :received_from, :received_to, :sort, :direction, :page).to_h
    @page = [params.fetch(:page, 1).to_i, 1].max
    @per_page = PER_PAGE
    @filtered_slides = SlideSearch.new(@filters).call
    @total_count = @filtered_slides.count
    @slides = @filtered_slides.offset((@page - 1) * @per_page).limit(@per_page)
    @total_pages = [(@total_count.to_f / @per_page).ceil, 1].max
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error("Slide search failed: #{e.message}")
    @slides = Slide.none
    @total_count = 0
    @total_pages = 1
    @page = 1
    @search_error = "We could not load slides right now. Please try again."
  end

  def show
    @slide = Slide.find(params[:id])
    authorize @slide
    @latest_evaluation = @slide.rule_evaluations.includes(:winning_rule).order(evaluated_at: :desc).first
  end
end
