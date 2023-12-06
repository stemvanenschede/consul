require "rails_helper"

describe "Legislation" do
  context "process debate page" do
    let(:process)  { create(:legislation_process) }
    let(:question) { create(:legislation_question, process: process) }

    before do
      create(:legislation_question, process: process, title: "Question 1", description: "Description 1")
      create(:legislation_question, process: process, title: "Question 2", description: "Description 2")
      create(:legislation_question, process: process, title: "Question 3", description: "Description 3")
    end

    scenario "do not show next question link with only one question" do
      visit legislation_process_question_path(process, question)

      expect(page).to have_content(question.title)
      expect(page).not_to have_link("Next question")
    end
  end
end
