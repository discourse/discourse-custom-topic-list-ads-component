# frozen_string_literal: true

RSpec.describe "Ads Between Topics", system: true do
  fab!(:theme) { upload_theme_component } 

  fab!(:user) { Fabricate(:user) }
  fab!(:staff_user) { Fabricate(:admin) } 
  fab!(:group_member) do
    user = Fabricate(:user, username: "adfan")
    group = Fabricate(:group, name: "advertarget")
    group.add(user)
    user
  end
  fab!(:another_group_member) do
    user = Fabricate(:user, username: "otheruser")
    group = Fabricate(:group, name: "othertarget")
    group.add(user)
    user
  end

  fab!(:general_category) { Fabricate(:category, name: "General Discussion") }
  fab!(:excluded_category) { Fabricate(:category, name: "No Ads Here") }
  fab!(:parent_category) { Fabricate(:category, name: "Parent With Ads") }
  fab!(:child_of_excluded_parent_category) do
    Fabricate(:category, name: "Child No Ads", parent_category_id: excluded_category.id)
  end

  let(:default_ads_config) do
    [
      {
        id: "ad1",
        text: "Amazing Product Ad - All Users",
        link: "https://example.com/amazing",
        utm_source: "discourse",
        include_groups: "", 
        exclude_groups: "",
      },
      {
        id: "ad2",
        text: "Special Offer for Staff",
        link: "https://example.com/staff-offer",
        utm_source: "discourse",
        include_groups: "staff",
        exclude_groups: "",
      },
      {
        id: "ad3",
        text: "Advertarget Group Exclusive",
        link: "https://example.com/advertarget-deal",
        utm_source: "discourse",
        include_groups: "advertarget",
        exclude_groups: "",
      },
      {
        id: "ad4",
        text: "Ad for everyone EXCEPT Othertarget Group",
        link: "https://example.com/general-ad",
        utm_source: "discourse",
        include_groups: "",
        exclude_groups: "othertarget",
      },
      {
        id: "ad5",
        text: "Ad for Anonymous Users",
        link: "https://example.com/anon-ad",
        utm_source: "discourse",
        include_groups: "anon",
        exclude_groups: "",
      },
    ]
  end

  def create_topics(count, category)
    count.times { |i| Fabricate(:topic, title: "Test Topic in #{category.name} #{i + 1}", category: category) }
  end

  def find_ads
    page.all(".topic-list tr.discourse-custom-ad-component")
  end

  before do
    theme.update_setting(:ads, default_ads_config)
    theme.update_setting(:show_between_every, 2) 
    theme.update_setting(:exclude_categories, "") 
    theme.save!
  end

  context "when viewing a topic list in a general category" do
    before do
      create_topics(7, general_category) 
    end

    it "shows ads at the configured frequency for anonymous users" do
      visit(general_category.url)
      expect(find_ads.count).to eq(3)

      expect(page).to have_css("tr.discourse-custom-ad-component a[href*='example.com/anon-ad']")
    end

    it "shows ads for a regular logged-in user" do
      sign_in(user)
      visit(general_category.url)
      expect(find_ads.count).to eq(3)

      expect(page).to have_css("tr.discourse-custom-ad-component a[href*='example.com/amazing']")
    end

    it "shows staff-specific ads and general ads for staff users" do
      sign_in(staff_user)
      visit(general_category.url)
  
      expect(page).to have_css("tr.discourse-custom-ad-component a[href^='https://example.com/staff-offer']")
    end

    it "shows ads targeted to a specific group for a member of that group" do
      sign_in(group_member) 
      visit(general_category.url)
      
      expect(page).to have_css("tr.discourse-custom-ad-component a[href*='example.com/advertarget-deal']")
    end

    it "does not show ads to users in an excluded group for that ad" do
      sign_in(another_group_member) 
      visit(general_category.url)

      expect(page).not_to have_css("tr.discourse-custom-ad-component a[href*='example.com/general-ad']")
    end
  end

  context "when category exclusion is configured" do
    before do
      theme.update_setting(:exclude_categories, "#{excluded_category.id}|#{child_of_excluded_parent_category.parent_category_id}")
      theme.save!
      create_topics(5, excluded_category)
      create_topics(5, child_of_excluded_parent_category)
      create_topics(5, general_category) 
    end

    it "does not show ads in an excluded category" do
      sign_in(user)
      visit(excluded_category.url)

      expect(page).not_to have_css("tr.discourse-custom-ad-component")
    end

    it "does not show ads if the parent category is excluded" do
      sign_in(user)
      visit(child_of_excluded_parent_category.url)
      
      expect(page).not_to have_css("tr.discourse-custom-ad-component")
    end

    it "still shows ads in non-excluded categories" do
      sign_in(user)
      visit(general_category.url)
      expect(find_ads.count).to eq(2)
    end
  end

  context "when ad frequency is changed" do
    before do
      theme.update_setting(:show_between_every, 1)
      theme.save!
      create_topics(3, general_category)
    end

    it "shows ads according to the new frequency" do
      sign_in(user)
      visit(general_category.url)
   
      expect(find_ads.count).to eq(3)
    end
  end
end