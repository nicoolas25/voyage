module Jekyll
  class RandomTag < Liquid::Tag
    def initialize(tag_name, max, tokens)
      super
      @max, @delta = max.strip.split(" ").map(&:to_i)
    end

    def render(context)
      (rand(@max) + (@delta || 0)).to_s
    end
  end
end

Liquid::Template.register_tag('random', Jekyll::RandomTag)
