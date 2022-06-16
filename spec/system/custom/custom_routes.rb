require "rails_helper"

describe "Custom routes" do

  scenario "Legislation processes custom route" do
    visit "/datkanbeter"

    expect(page).to have_current_path(legislation_processes_path)
  end
end
