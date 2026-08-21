class ReviewsController < ApplicationController
  PER_PAGE = 25

  def index
    authorize Review
    @filters = params.permit(:q, :sort, :direction, :page).to_h
    @page = [params.fetch(:page, 1).to_i, 1].max
    scope = SlideSearch.new(@filters, scope: Slide.review_queue).call
    @total_count = scope.count
    @total_pages = [(@total_count.to_f / PER_PAGE).ceil, 1].max
    @slides = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def show
    @slide = Slide.find(params[:id])
    authorize @slide, policy_class: ReviewPolicy, query: :show?
    @latest_evaluation = @slide.rule_evaluations.includes(:winning_rule).order(evaluated_at: :desc).first
    @review = @slide.reviews.order(decided_at: :desc).first
  end

  def decide
    @slide = Slide.find(params[:id])
    authorize @slide, policy_class: ReviewPolicy, query: :update?
    ReviewDecisionService.call(@slide, reviewer: current_user, decision: params.require(:decision), comment: params[:comment], retention_policy_code: params[:retention_policy_code], custom_days: params[:custom_days], tags: params[:tags])
    redirect_to reviews_path, notice: "Manual review decision recorded."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    redirect_to review_path(@slide), alert: e.message
  end
end
