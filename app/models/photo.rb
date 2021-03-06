class Photo < ActiveRecord::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::AssetTagHelper

  attr_accessible :image, :taken_at
  belongs_to :poi
  belongs_to :user, :counter_cache => true
  mount_uploader :image, PhotoUploader
  process_in_background :image

  before_create :extract_date_time

  after_destroy :remove_empty_directory

  validates :user_id, :poi_id, :presence => true

  scope :with_user, :include => :user
  scope :with_poi,  :include => :poi

  acts_as_api
  include Api::Photo

  def image_versions
    i = []
    i << {:type => "original", :url => image_path(image.url.to_s), :width => image.width, :height => image.height}
    image.versions.keys.each do |version|
      v = version.to_sym
      i << {:type => v, :url => image_path(image.url(v).to_s), :width => image.send(v).width, :height => image.send(v).height }
    end
    i
  end

  def taken_on
    (taken_at || created_at).to_i
  end

  protected

  # Dummy methods to generate full image paths
  def config
    Wheelmap::Application.config.action_controller
  end


  # Dummy methods to generate full image paths
  def controller
    ''
  end

  def extract_date_time
    self.taken_at = EXIFR::JPEG.new(image.path).date_time rescue nil
  end

  def remove_empty_directory
    FileUtils.remove_dir(Rails.root.join('public', image.store_dir), :force => true)
  end

end
