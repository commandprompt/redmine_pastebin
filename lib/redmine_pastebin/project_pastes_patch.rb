module RedminePastebin
  module ProjectPastesPatch
    def self.included(base)
      base.class_eval do
        has_many :pastes
      end
    end
  end
end
