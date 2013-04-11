require 'test_helper'

class Spree::Admin::ContentsIntegrationTest < SpreeEssentials::IntegrationCase

  setup do
    Spree::Content.destroy_all
    @page = Spree::Page.first || Factory.create(:spree_page)
  end

  should "have a link to new content" do
    visit spree.admin_page_contents_path(@page)
    btn = find(".actions a.button").native
    assert_match /#{spree.new_admin_page_content_path(@page)}$/, btn.attribute('href')
    assert_equal "NEW CONTENT", btn.text
  end

  should "get new content" do
    visit spree.new_admin_page_content_path(@page)
    assert has_content?("New Content")
    within "#new_content" do
      assert has_field?("Title")
      assert has_field?("Page")
      assert has_field?("Body")
      assert has_field?("Context")
      assert has_field?("Attachment")
      assert has_field?("Link URL")
      assert has_field?("Link Text")
      assert has_field?("Hide Title")
    end
  end

  should "validate content" do
    visit spree.new_admin_page_content_path(@page)
    click_button "Create"
    within "#errorExplanation" do
      assert_seen "1 error prohibited this record from being saved:"
      assert_seen "Title can't be blank"
    end
  end

  should "create some content" do
    visit spree.new_admin_page_content_path(@page)
    within "#new_content" do
      fill_in "Title", :with => "Just some content"
      select @page.title, :from => "Page"
      fill_in "Body",  :with => "Just some words in the content..."
    end
    click_button "Create"
    assert_equal spree.admin_page_contents_path(@page), current_path
    assert_flash :success, "Content has been successfully created!"
  end

  context "existing content" do
    setup do
      @content = Factory.create(:spree_content, :page => @page)
    end

    should "edit and update" do
      visit spree.edit_admin_page_content_path(@page, @content)
      within "#edit_content_#{@content.id}" do
        fill_in "Title", :with => "Just some content"
        select @page.title, :from => "Page"
        fill_in "Body",  :with => "Just some words in the content..."
      end
      click_button "Update"
      assert_equal spree.admin_page_contents_path(@page.reload), current_path
      assert_flash :success, "Content has been successfully updated!"
    end

    should "not delete current attachment unless checkbox is checked" do
      @content.update_attribute(:attachment, sample_image)
      visit spree.edit_admin_page_content_path(@page, @content)
      click_button "Update"
      assert !@content.reload.attachment_file_name.blank?
    end

    should "delete current attachment" do
      @content.update_attribute(:attachment, sample_image)
      visit spree.edit_admin_page_content_path(@page, @content)
      click_link "Optional Fields"
      check "Delete current attachment"
      click_button "Update"
      assert @content.reload.attachment_file_name.blank?
    end

    should "get destroyed" do
      visit spree.admin_page_contents_path(@page)
      click_icon :trash
      page.driver.browser.switch_to.alert.accept
      assert has_content?('Loading')
    end

  end

  context "several contents" do

    setup do
      setup_action_controller_behaviour(Spree::Admin::ContentsController)
      @page.contents.destroy_all
      @contents = Array.new(2) {|i| Factory(:spree_content, :title => "Content ##{i + 1}", :page => @page, :position => i) }
    end

    should "update positions" do
      positions = Hash[@contents.map{|i| [i.id, 2 - i.position ]}]
      visit spree.admin_page_contents_path(@page)
      assert_seen "Content #1", :within => "tbody tr:first"
      assert_seen "Content #2", :within => "tbody tr:last"
      xhr :post, :update_positions, { :page_id => @page.to_param, :positions => positions }
      visit spree.admin_page_contents_path(@page)
      assert_seen "Content #2", :within => "tbody tr:first"
      assert_seen "Content #1", :within => "tbody tr:last"
    end

  end

  context "i18n" do
    should "handle i18n translation for body and title" do
      @page = Factory.create(:spree_page, :title => 'Just another page', :path => "/just-another-page")
      visit spree.new_admin_page_content_path(@page)

      within "#new_content" do
        fill_in "Title", :with => "Just some content"
        fill_in "Body",  :with => "Just some words in the content..."

        select "fr", :from => "spree_multi_lingual_dropdown"

        fill_in "content_title_fr", :with => "Juste quelque contenu"
        fill_in "content_body_fr",  :with => "Juste quelques mots dans le contenu..."

        select @page.title, :from => "Page"
      end
      click_button "Create"
      assert_equal spree.admin_page_contents_path(@page), current_path
      assert_flash :success, "Content has been successfully created!"

      visit "/just-another-page"
      assert_seen "Just some words in the content..."

      visit "/en/just-another-page"
      assert_seen "Just some words in the content..."

      visit "/fr/just-another-page"
      assert_seen "Juste quelques mots dans le contenu..."
    end
  end

end
