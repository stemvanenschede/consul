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

    scenario "shows question list" do
      visit legislation_process_path(process)

      expect(page).to have_content("Question 1")
      expect(page).to have_content("Question 2")
      expect(page).to have_content("Question 3")

      click_link "Question 1"

      expect(page).to have_content("Question 1".upcase)
      expect(page).to have_content("Description 1")
      expect(page).to have_content("NEXT QUESTION")

      click_link "Next question"

      expect(page).to have_content("Question 2".upcase)
      expect(page).to have_content("Description 2")
      expect(page).to have_content("NEXT QUESTION")

      click_link "Next question"

      expect(page).to have_content("Question 3".upcase)
      expect(page).to have_content("Description 3")
      expect(page).not_to have_content("NEXT QUESTION")
    end

    scenario "shows question page" do
      visit legislation_process_question_path(process, process.questions.first)

      expect(page).to have_content("Question 1".upcase)
      expect(page).to have_content("Description 1")
      expect(page).to have_content("Open answers (0)".upcase)
    end

    scenario "shows next question link in question page" do
      visit legislation_process_question_path(process, process.questions.first)

      expect(page).to have_content("Question 1".upcase)
      expect(page).to have_content("Description 1")
      expect(page).to have_content("NEXT QUESTION")

      click_link "Next question"

      expect(page).to have_content("Question 2".upcase)
      expect(page).to have_content("Description 2")
      expect(page).to have_content("NEXT QUESTION")

      click_link "Next question"

      expect(page).to have_content("Question 3".upcase)
      expect(page).to have_content("Description 3")
      expect(page).not_to have_content("NEXT QUESTION")
    end

    scenario "do not show next question link with only one question" do
      visit legislation_process_question_path(process, question)

      expect(page).to have_content(question.title.upcase)
      expect(page).not_to have_link("Next question")
    end
  end
end
