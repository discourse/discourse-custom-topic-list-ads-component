# frozen_string_literal: true

RSpec.describe "Ads Between Posts", system: true do
  fab!(:theme) { upload_theme_component }

  fab!(:user)
  fab!(:staff_user, :admin)

  fab!(:general_category) { Fabricate(:category, name: "General") }
  fab!(:excluded_category) { Fabricate(:category, name: "No Ads") }

  let(:default_ads_config) do
    [
      {
        id: "ad-post-1",
        text: "Post Ad for All",
        link: "https://example.com/ad1",
        utm_source: "discourse",
        include_groups: "",
        exclude_groups: "",
      },
      {
        id: "staff-post-ad",
        text: "Staff Only Post Ad",
        link: "https://example.com/staff",
        utm_source: "discourse",
        include_groups: "staff",
        exclude_groups: "",
      },
    ]
  end

  def create_post_stream(topic, count)
    Fabricate(:post, topic: topic, user: topic.user, raw: "Initial post") if topic.posts.empty?
    count.times { |i| Fabricate(:post, topic: topic, raw: "This is content for a reply ##{i + 1}") }
  end

  def find_ads_in_post_stream
    page.all(".discourse-custom-ad-component")
  end

  before do
    SiteSetting.glimmer_post_stream_mode = "enabled"
    theme.update_setting(:ads, default_ads_config)
    theme.update_setting(:show_between_posts, 2) # show ad every 2 posts
    theme.update_setting(:exclude_categories, "")
    theme.save!
  end

  context "when viewing a topic with enough posts" do
    fab!(:topic) { Fabricate(:topic, category: general_category, user: user) }

    before { create_post_stream(topic, 5) }

    it "shows ads at the configured frequency for anon users" do
      visit(topic.url)

      expect(find_ads_in_post_stream.size).to eq(4) # including the ad after the initial post
      expect(page).to have_css(".discourse-custom-ad-component a[href*='example.com/ad1']")
    end

    it "shows staff-specific ads for staff" do
      sign_in(staff_user)
      visit(topic.url)

      expect(page).to have_css(".discourse-custom-ad-component a[href*='example.com/staff']")
    end
  end

  context "when category exclusion is enabled" do
    fab!(:excluded_topic) { Fabricate(:topic, category: excluded_category, user: user) }

    before do
      theme.update_setting(:exclude_categories, "#{excluded_category.id}")
      theme.save!
      create_post_stream(excluded_topic, 5)
    end

    it "does not show ads in excluded categories" do
      sign_in(user)
      visit(excluded_topic.url)

      expect(page).not_to have_css(".discourse-custom-ad-component")
    end
  end
end
