module RedminePastebin
  module UserPastesPatch
    def self.included(base)
      base.class_eval do
        has_many :pastes, :foreign_key => "author_id"
      end
    end
  end
end
