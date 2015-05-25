class Message < ActiveRecord::Base
  require "#{Rails.root}/lib/algo"
  after_save :update_qualities
  belongs_to :user, dependent: :destroy

  validates :content, presence: true
  validates :user, presence: true

  private
    def update_qualities
      a = Algo.new(text: self.content)
      qs = a.qualities[:descriptions]
      qs.each do |quality|
        q = if Quality.where('user_id = ? AND name = ?', self.user_id, quality).first.present?
            q.increment!(:count)
          else
            Quality.create!(name: quality, count: 1)
          end
        end
    end
end
