class User < ApplicationRecord
  devise  :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable
  has_one_attached :avatar

  def self.guest
    find_or_create_by!(email: 'guest@example.com') do |user|
      user.password = SecureRandom.urlsafe_base64
    end
  end

  has_many :videos, class_name: "Video"
  has_many :meditations
end
