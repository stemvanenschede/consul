require_dependency Rails.root.join("app", "models", "budget", "investment").to_s

class Budget
  class Investment
    def should_show_vote_count?
      budget.valuating? && budget.phases.enabled.pluck(:kind).include?("selecting")
    end
  end
end
