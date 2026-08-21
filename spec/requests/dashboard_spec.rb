require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:user) { User.create!(email: "dashboard@example.com", password: "password12345", role: :viewer) }

  it "requires authentication" do
    get dashboard_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the operational overview for an authenticated user" do
    sign_in user

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Slides", "Storage", "API connections", "Recent activity", "Retention")
  end
end
