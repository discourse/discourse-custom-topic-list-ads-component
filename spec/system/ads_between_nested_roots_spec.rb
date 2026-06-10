# frozen_string_literal: true

RSpec.describe "Ads between nested roots", system: true do
  fab!(:theme) { upload_theme_component }
  fab!(:topic)
  fab!(:op) { Fabricate(:post, topic: topic) }
  fab!(:root_replies) { Fabricate.times(7, :post, topic: topic) }

  let(:ads_config) do
    [
      {
        id: "ad-post-1",
        text: "Post Ad for All",
        link: "https://example.com/ad1",
        utm_source: "discourse",
        include_groups: "",
        exclude_groups: "",
      },
    ]
  end

  before do
    SiteSetting.nested_replies_enabled = true
    SiteSetting.nested_replies_default_sort = "old"
    theme.update_setting(:ads, ads_config)
    theme.update_setting(:show_between_posts, 3)
    theme.update_setting(:exclude_categories, "")
    theme.save!
  end

  it "shows ads between every nth top-level reply and none inside the reply tree" do
    visit("/n/#{topic.slug}/#{topic.id}")

    expect(page).to have_css(".nested-view")
    expect(page).to have_css(
      ".discourse-custom-ad-component.--between-nested-roots a[href*='example.com/ad1']",
      count: 2,
    )
    expect(page).to have_css(
      ".nested-post:has([data-post-number='#{root_replies[2].post_number}']) + .discourse-custom-ad-component.--between-nested-roots",
    )
    expect(page).to have_no_css(".nested-post .discourse-custom-ad-component")
    expect(page).to have_no_css(".nested-view__op .discourse-custom-ad-component")
  end
end
