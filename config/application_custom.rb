module Consul
  class Application < Rails::Application
    config.x.theme.current = "enschede"
    config.x.theme.load_path = Rails.root.join(
      "app",
      "assets",
      "stylesheets",
      "themes"
    )
  end
end
