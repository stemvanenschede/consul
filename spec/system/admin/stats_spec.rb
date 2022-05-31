require "rails_helper"

describe "Stats", :admin do
  context "Summary" do
    scenario "General" do
      create(:debate)
      2.times { create(:proposal) }
      3.times { create(:comment, commentable: Debate.first) }
      4.times { create(:visit) }

      visit admin_stats_path

      expect(page).to have_content "DEBATES\n1"
      expect(page).to have_content "PROPOSALS\n2"
      expect(page).to have_content "COMMENTS\n3"
      expect(page).to have_content "VISITS\n4"
    end

    scenario "Votes" do
      create(:debate,   voters: Array.new(1) { create(:user) })
      create(:proposal, voters: Array.new(2) { create(:user) })
      create(:comment,  voters: Array.new(3) { create(:user) })

      visit admin_stats_path

      expect(page).to have_content "DEBATE VOTES\n1"
      expect(page).to have_content "PROPOSAL VOTES\n2"
      expect(page).to have_content "COMMENT VOTES\n3"
      expect(page).to have_content "TOTAL VOTES\n6"
    end
  end

  context "Users" do
    scenario "Summary" do
      1.times { create(:user, :level_three) }
      2.times { create(:user, :level_two) }
      3.times { create(:user) }

      visit admin_stats_path

      expect(page).to have_content "LEVEL THREE USERS\n1"
      expect(page).to have_content "LEVEL TWO USERS\n2"
      expect(page).to have_content "VERIFIED USERS\n3"
      expect(page).to have_content "UNVERIFIED USERS\n4"
      expect(page).to have_content "TOTAL USERS\n7"
    end

    scenario "Do not count erased users" do
      1.times { create(:user, :level_three, erased_at: Time.current) }
      2.times { create(:user, :level_two, erased_at: Time.current) }
      3.times { create(:user, erased_at: Time.current) }

      visit admin_stats_path

      expect(page).to have_content "LEVEL THREE USERS\n0"
      expect(page).to have_content "LEVEL TWO USERS\n0"
      expect(page).to have_content "VERIFIED USERS\n0"
      expect(page).to have_content "UNVERIFIED USERS\n1"
      expect(page).to have_content "TOTAL USERS\n1"
    end

    scenario "Do not count hidden users" do
      1.times { create(:user, :hidden, :level_three) }
      2.times { create(:user, :hidden, :level_two) }
      3.times { create(:user, :hidden) }

      visit admin_stats_path

      expect(page).to have_content "LEVEL THREE USERS\n0"
      expect(page).to have_content "LEVEL TWO USERS\n0"
      expect(page).to have_content "VERIFIED USERS\n0"
      expect(page).to have_content "UNVERIFIED USERS\n1"
      expect(page).to have_content "TOTAL USERS\n1"
    end

    scenario "Level 2 user Graph" do
      skip "No verification sms used"
      create(:geozone)
      visit account_path
      click_link "Verify my account"
      verify_residence
      confirm_phone

      visit admin_stats_path

      expect(page).to have_content "LEVEL TWO USERS\n1"
    end
  end

  describe "Budget investments" do
    context "Supporting phase" do
      let(:budget) { create(:budget) }
      let(:group_all_city) { create(:budget_group, budget: budget) }
      let!(:heading_all_city) { create(:budget_heading, group: group_all_city) }

      scenario "Number of supports in investment projects" do
        group_2 = create(:budget_group, budget: budget)

        create(:budget_investment, heading: create(:budget_heading, group: group_2), voters: [create(:user)])
        create(:budget_investment, heading: heading_all_city, voters: [create(:user), create(:user)])
        investment_retired_supports = create(:budget_investment, heading: heading_all_city)

        3.times { create(:vote, votable: investment_retired_supports, vote_flag: false) }

        visit admin_stats_path
        click_link "Participatory Budgets"
        within("#budget_#{budget.id}") do
          click_link "Supporting phase"
        end

        expect(page).to have_content "VOTES\n3"
        expect(page).to have_link "Go back", count: 1
      end

      scenario "Number of users that have supported an investment project" do
        group_2 = create(:budget_group, budget: budget)
        investment1 = create(:budget_investment, heading: create(:budget_heading, group: group_2))
        investment2 = create(:budget_investment, heading: heading_all_city)

        create(:user, :level_two, votables: [investment1, investment2])
        create(:user, :level_two, votables: [investment1])
        create(:user, :level_two)

        visit admin_stats_path
        click_link "Participatory Budgets"
        within("#budget_#{budget.id}") do
          click_link "Supporting phase"
        end

        expect(page).to have_content "PARTICIPANTS\n2"
      end

      scenario "Number of users that have supported investments projects per geozone" do
        budget = create(:budget)

        group_all_city  = create(:budget_group, budget: budget)
        group_districts = create(:budget_group, budget: budget)

        all_city    = create(:budget_heading, group: group_all_city)
        carabanchel = create(:budget_heading, group: group_districts)
        barajas     = create(:budget_heading, group: group_districts)

        create(:budget_investment, heading: all_city, voters: [create(:user)])
        create(:budget_investment, heading: carabanchel, voters: [create(:user)])
        create(:budget_investment, heading: carabanchel, voters: [create(:user)])

        visit admin_stats_path
        click_link "Participatory Budgets"
        within("#budget_#{budget.id}") do
          click_link "Supporting phase"
        end

        within("#budget_heading_#{all_city.id}") do
          expect(page).to have_content all_city.name
          expect(page).to have_content 1
        end

        within("#budget_heading_#{carabanchel.id}") do
          expect(page).to have_content carabanchel.name
          expect(page).to have_content 2
        end

        within("#budget_heading_#{barajas.id}") do
          expect(page).to have_content barajas.name
          expect(page).to have_content 0
        end
      end

      scenario "hide final voting link" do
        visit admin_stats_path
        click_link "Participatory Budgets"

        within("#budget_#{budget.id}") do
          expect(page).not_to have_link "Final voting"
        end
      end

      scenario "show message when accessing final voting stats" do
        visit budget_balloting_admin_stats_path(budget_id: budget.id)

        expect(page).to have_content "There isn't any data to show before the balloting phase."
      end
    end

    context "Balloting phase" do
      let(:budget) { create(:budget, :balloting) }
      let(:group) { create(:budget_group, budget: budget) }
      let(:heading) { create(:budget_heading, group: group) }
      let!(:investment) { create(:budget_investment, :feasible, :selected, heading: heading) }

      scenario "Number of votes in investment projects" do
        investment_2 = create(:budget_investment, :feasible, :selected, budget: budget)

        create(:user, ballot_lines: [investment, investment_2])
        create(:user, ballot_lines: [investment_2])

        visit admin_stats_path
        click_link "Participatory Budgets"
        within("#budget_#{budget.id}") do
          click_link "Final voting"
        end

        expect(page).to have_content "VOTES\n3"
      end

      scenario "Number of users that have voted a investment project" do
        create(:user, ballot_lines: [investment])
        create(:user, ballot_lines: [investment])
        create(:user)

        visit admin_stats_path
        click_link "Participatory Budgets"
        within("#budget_#{budget.id}") do
          click_link "Final voting"
        end

        expect(page).to have_content "PARTICIPANTS\n2"
      end

      scenario "Do not show headings from other budgets" do
        other_heading = create(:budget_heading)
        investment_2 = create(:budget_investment, :feasible, :selected, heading: other_heading)

        create(:user, ballot_lines: [investment])
        create(:user, ballot_lines: [investment_2])

        visit admin_stats_path
        click_link "Participatory Budgets"
        within("#budget_#{budget.id}") do
          click_link "Final voting"
        end

        expect(page).to have_content heading.name
        expect(page).not_to have_content other_heading.name
      end

      scenario "Do not count removed votes" do
        create(:user, ballot_lines: [investment])
        create(:user, ballot_lines: [investment])

        Budget::Ballot::Line.last.destroy!

        visit admin_stats_path
        click_link "Participatory Budgets"
        within("#budget_#{budget.id}") do
          click_link "Final voting"
        end

        within("#total_participants_count") do
          expect(page).to have_content "1"
        end

        within("#user_count_#{heading.slug}") do
          expect(page).to have_content "#{heading.name} 1"
        end
      end

      scenario "Do not show headings from other budgets" do
        other_heading = create(:budget_heading)
        investment_2 = create(:budget_investment, :feasible, :selected, heading: other_heading)

        create(:user, ballot_lines: [investment])
        create(:user, ballot_lines: [investment_2])

        visit admin_stats_path
        click_link "Participatory Budgets"
        within("#budget_#{budget.id}") do
          click_link "Final voting"
        end

        expect(page).to have_content heading.name
        expect(page).not_to have_content other_heading.name
      end

      scenario "Do not count removed votes" do
        create(:user, ballot_lines: [investment])
        create(:user, ballot_lines: [investment])

        Budget::Ballot::Line.last.destroy!

        visit admin_stats_path
        click_link "Participatory Budgets"
        within("#budget_#{budget.id}") do
          click_link "Final voting"
        end

        within("#total_participants_count") do
          expect(page).to have_content "1"
        end

        within("#user_count_#{heading.slug}") do
          expect(page).to have_content "#{heading.name} 1"
        end
      end
    end
  end

  context "graphs" do
    scenario "event graphs", :with_frozen_time do
      campaign = create(:campaign)

      visit root_path(track_id: campaign.track_id)

      expect(page).to have_content "Sign out"

      visit admin_stats_path

      within("#stats") do
        click_link campaign.name
      end

      expect(page).to have_content "#{campaign.name} (1)"

      within("#graph") do
        expect(page).to have_content Date.current.strftime("%Y-%m-%d")
      end
    end
  end

  context "Proposal notifications" do
    scenario "Summary stats" do
      proposal = create(:proposal)

      create(:proposal_notification, proposal: proposal)
      create(:proposal_notification, proposal: proposal)
      create(:proposal_notification)

      visit admin_stats_path
      click_link "Proposal notifications"

      within("#proposal_notifications_count") do
        expect(page).to have_content "3"
      end

      within("#proposals_with_notifications_count") do
        expect(page).to have_content "2"
      end
    end

    scenario "Index" do
      proposal_notifications = 3.times.map { create(:proposal_notification) }

      visit admin_stats_path
      click_link "Proposal notifications"

      expect(page).to have_css(".proposal_notification", count: 3)

      proposal_notifications.each do |proposal_notification|
        expect(page).to have_content proposal_notification.title
        expect(page).to have_content proposal_notification.body
      end
    end

    scenario "Deleted proposals" do
      proposal_notification = create(:proposal_notification)
      proposal_notification.proposal.destroy!

      visit admin_stats_path
      click_link "Proposal notifications"

      expect(page).to have_css(".proposal_notification", count: 1)

      expect(page).to have_content proposal_notification.title
      expect(page).to have_content proposal_notification.body
      expect(page).to have_content "Proposal not available"
    end
  end

  context "Direct messages" do
    scenario "Summary stats" do
      sender = create(:user, :level_two)

      create(:direct_message, sender: sender)
      create(:direct_message, sender: sender)
      create(:direct_message)

      visit admin_stats_path
      click_link "Direct messages"

      within("#direct_messages_count") do
        expect(page).to have_content "3"
      end

      within("#users_who_have_sent_message_count") do
        expect(page).to have_content "2"
      end
    end
  end

  context "Polls" do
    scenario "Total participants by origin" do
      create(:poll_officer_assignment)
      3.times { create(:poll_voter, origin: "web") }

      visit admin_stats_path

      within(".stats") do
        click_link "Polls"
      end

      within("#web_participants") do
        expect(page).to have_content "3"
      end
    end

    scenario "Total participants" do
      user = create(:user, :level_two)
      3.times { create(:poll_voter, user: user) }
      create(:poll_voter)

      visit admin_stats_path

      within(".stats") do
        click_link "Polls"
      end

      within("#participants") do
        expect(page).to have_content "2"
      end
    end

    scenario "Participants by poll" do
      poll1 = create(:poll)
      poll2 = create(:poll)

      1.times { create(:poll_voter, poll: poll1, origin: "web") }
      2.times { create(:poll_voter, poll: poll2, origin: "web") }

      visit admin_stats_path

      within(".stats") do
        click_link "Polls"
      end

      within("#polls") do
        within("#poll_#{poll1.id}") do
          expect(page).to have_content "1"
        end

        within("#poll_#{poll2.id}") do
          expect(page).to have_content "2"
        end
      end
    end

    scenario "Participants by poll question" do
      user1 = create(:user, :level_two)
      user2 = create(:user, :level_two)

      poll = create(:poll)

      question1 = create(:poll_question, :yes_no, poll: poll)
      question2 = create(:poll_question, :yes_no, poll: poll)

      create(:poll_answer, question: question1, author: user1)
      create(:poll_answer, question: question2, author: user1)
      create(:poll_answer, question: question2, author: user2)

      visit admin_stats_path

      within(".stats") do
        click_link "Polls"
      end

      within("#poll_question_#{question1.id}") do
        expect(page).to have_content "1"
      end

      within("#poll_question_#{question2.id}") do
        expect(page).to have_content "2"
      end

      within("#poll_#{poll.id}_questions_total") do
        expect(page).to have_content "2"
      end
    end
  end

  context "SDG" do
    scenario "Shows SDG stats link when SDG feature is enabled" do
      Setting["feature.sdg"] = true

      visit admin_stats_path

      expect(page).to have_link "SDG", href: sdg_admin_stats_path
    end

    scenario "Does not show SDG stats link when SDG feature is disbled" do
      Setting["feature.sdg"] = false

      visit admin_stats_path

      expect(page).not_to have_link "SDG"
    end

    scenario "Renders all goals stats" do
      goals_count = SDG::Goal.count

      visit sdg_admin_stats_path

      expect(page).to have_css "h3", count: goals_count
      expect(page).to have_css ".sdg-goal-stats", count: goals_count
    end
  end
end
