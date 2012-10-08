module ActsAsTaggableOn
  module Taggable
    def taggable?
      false
    end

    ##
    # This is an alias for calling <tt>acts_as_taggable_on :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_taggable
    #   end
    def acts_as_taggable
      acts_as_taggable_on :tags
    end

    def acts_as_scored_taggable
      acts_as_scored_taggable_on :tags
    end

    def acts_as_scored_taggable_on(*tag_types)
      taggable_on(false, true, tag_types)
    end

    ##
    # This is an alias for calling <tt>acts_as_ordered_taggable_on :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_ordered_taggable
    #   end
    def acts_as_ordered_taggable
      acts_as_ordered_taggable_on :tags
    end
    
    ##
    # Make a model taggable on specified contexts.
    #
    # @param [Array] tag_types An array of taggable contexts
    #
    # Example:
    #   class User < ActiveRecord::Base
    #     acts_as_taggable_on :languages, :skills
    #   end
    def acts_as_taggable_on(*tag_types)
      taggable_on(false, false, tag_types)
    end
    
    
    ##
    # Make a model taggable on specified contexts
    # and preserves the order in which tags are created
    #
    # @param [Array] tag_types An array of taggable contexts
    #
    # Example:
    #   class User < ActiveRecord::Base
    #     acts_as_ordered_taggable_on :languages, :skills
    #   end
    def acts_as_ordered_taggable_on(*tag_types)
      taggable_on(true, false, tag_types)
    end
    
    private
    
      # Make a model taggable on specified contexts
      # and optionally preserves the order in which tags are created
      #
      # Seperate methods used above for backwards compatibility
      # so that the original acts_as_taggable_on method is unaffected
      # as it's not possible to add another arguement to the method
      # without the tag_types being enclosed in square brackets
      #
      # NB: method overridden in core module in order to create tag type
      #     associations and methods after this logic has executed
      #
      def taggable_on(ordered, scored, *tag_types)
        new_tag_types = tag_types.to_a.flatten.compact.map(&:to_sym)

        if taggable?
          self.latest_tag_types = new_tag_types
          self.tag_types = (self.tag_types + self.latest_tag_types).uniq
          latest_tag_types.each do |ltt|
            self.preserve_tag_order[ltt] = ordered
            self.tags_have_scores[ltt] = scored
          end
        else
          class_attribute :tag_types
          class_attribute :latest_tag_types
          class_attribute :preserve_tag_order
          class_attribute :tags_have_scores
          self.tag_types = new_tag_types
          self.latest_tag_types = new_tag_types
          self.preserve_tag_order = HashWithIndifferentAccess.new
          self.tags_have_scores = HashWithIndifferentAccess.new
          latest_tag_types.each do |ltt|
            self.preserve_tag_order[ltt] = ordered
            self.tags_have_scores[ltt] = scored
          end
        
          class_eval do
            has_many :taggings, :as => :taggable, :dependent => :destroy, :include => :tag, :class_name => "ActsAsTaggableOn::Tagging"
            has_many :base_tags, :through => :taggings, :source => :tag, :class_name => "ActsAsTaggableOn::Tag"

            def self.taggable?
              true
            end

            include ActsAsTaggableOn::Utils
            include ActsAsTaggableOn::Taggable::Core
            include ActsAsTaggableOn::Taggable::Collection
            include ActsAsTaggableOn::Taggable::Cache
            include ActsAsTaggableOn::Taggable::Ownership
            include ActsAsTaggableOn::Taggable::Related
            include ActsAsTaggableOn::Taggable::Dirty
          end
        end
      end

  end
end
