require "rails_helper"

RSpec.describe "Slides", type: :request do
  let(:user) { User.create!(email: "viewer@example.com", password: "password12345", role: :viewer) }

  before { sign_in user }

  it "renders a filtered, paginated index" do
    Slide.create!(slide_uid: "UID-001", case_id: "CASE-001", scanner: "Aperio", received_at: Time.current)
    Slide.create!(slide_uid: "UID-002", case_id: "CASE-002", scanner: "Hamamatsu", received_at: Time.current)

    get slides_path, params: { q: "Aperio", page: 1 }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("UID-001")
    expect(response.body).not_to include("UID-002")
  end

  it "renders the global search entry point" do
    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Global slide search", "Search slides")
  end

  it "renders slide details" do
    slide = Slide.create!(slide_uid: "UID-001", case_id: "CASE-001", received_at: Time.current)

    get slide_path(slide)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Slide information")
    expect(response.body).to include("UID-001")
  end
end
