require "rails_helper"

describe "Budget Investments" do
  let(:manager) { create(:manager) }
  let(:budget)  { create(:budget, :selecting, name: "2033", slug: "budget_slug") }
  let(:group)   { create(:budget_group, budget: budget, name: "Whole city") }
  let(:heading) { create(:budget_heading, group: group, name: "Health") }

  context "Printing" do
    scenario "Printing budget investments is not limited to 15" do
      20.times { create(:budget_investment, heading: heading) }

      login_as_manager(manager)
      click_link "Print budget investments"

      expect(page).to have_content(budget.name)
      within "#budget_#{budget.id}" do
        click_link "Print budget investments"
      end

      expect(page).to have_css(".budget-investment", count: 20)
      expect(page).to have_link("Print", href: "javascript:window.print();")
    end

    scenario "Printing budget investments show investment id" do
      investment = create(:budget_investment, heading: heading)

      login_as_manager(manager)
      click_link "Print budget investments"

      expect(page).to have_content(budget.name)
      within "#budget_#{budget.id}" do
        click_link "Print budget investments"
      end

      expect(page).to have_content(investment.id)
    end
  end
end
