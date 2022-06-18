class Bich2

  DEFAULT_OUTPUT_FOLDER = 'new_files'
  OLD_FOLDER    = 'old'

  BRACKETS_TYPES_H = {
    round: {look: '()', regex: '\(.*?\)'},
    box:   {look: '[]', regex: '\[.*?\]'},
    curly: {look: '{}', regex: '\{.*?\}'},
  }.with_indifferent_access

  Rule = Struct.new(:regex, :to, keyword_init: true)

  def initialize(srt_text_utf8, narrator: :default, brackets_types: [:round, :box], rules_h: {}, remove_css: false, **options)
    # @srt_text = srt_text_utf8
    @rules = create_rules(rules_h.merge(narrator: narrator, brackets_types: brackets_types))

    if remove_css
      @remove_css = true
    end

    @converted_text = convert_text(srt_text_utf8).freeze
  end


  def method
    if false
      Bich2.new(File.read('aa.srt'), )
      reload!
      puts Bich2.new_from_file_path('aa.srt').export_to_text
    end
  end

  def export_to_text
    @converted_text
  end

  def export_to_file(file_name:)
    File.open(file_name, 'w') {|f| f.write(@converted_text) }
  end

  def self.new_from_file_path(file_path, **options)
    new(File.open(file_path, 'r:UTF-8').read, options)
  end

  def self.run(output_folder: DEFAULT_OUTPUT_FOLDER)
    # fetch srt file:
    srt_files = Dir.entries('.')[2..-1].sort.select{|entry| entry.end_with?('.srt')}

    srt_files.each do |srt_file|
      if false # use new folder
        old_folder_file_path = File.join(OLD_FOLDER, srt_file)
        FileUtils.mv(srt_file, old_folder_file_path)

        output_file_path = File.join(output_folder, srt_file)
        Bich2.new_from_file_path(old_folder_file_path).export_to_file(file_name: output_file_path)
      else # use current folder
        old_folder_file_path = File.join(OLD_FOLDER, srt_file)
        FileUtils.mv(srt_file, old_folder_file_path)

        Bich2.new_from_file_path(old_folder_file_path).export_to_file(file_name: srt_file)
      end
    end
    # move srt_files to old folder:
  end if false

  def self.remove_css(text)
    text.gsub(/<\w+(( \w+="[\w# ]+")+)?>/,'').gsub(/<\/\w+>/,'')
  end

private

  def create_rules(rules_h)
    rules_h.each_with_object([]) do |(rule,args), rules|
      rules.concat(self.send("get_#{rule}_rules", args))
    end
  end

  def get_narrator_rules(narrator)
    regex = case narrator
    when :easy; /[A-Z -]+:( |\z|\r|\n)/
    else /[\w -]+:( |\z|\r|\n)/
    # else /[\w ]+: /
    end
    [Rule.new(regex: regex, to: '')]
  end

  def get_brackets_types_rules(brackets_types)
    regex = Regexp.new(brackets_types.map{|bracket_type| "(?:#{BRACKETS_TYPES_H[bracket_type][:regex]})"}.join('|'), Regexp::MULTILINE)
    [Rule.new(regex: regex, to: '')]
  end

  def convert_text(text)
    text = Bich2.remove_css(text) if @remove_css
    # (?:\d+\n\d\d:\d\d:\d\d,\d\d\d --> \d\d:\d\d:\d\d,\d\d\d\n)(.*?)(?:\n\n|\z)
    # \d+\n\d\d:\d\d:\d\d,\d\d\d --> \d\d:\d\d:\d\d,\d\d\d\n(.*?)(?:\n\n|\z)
    text.gsub(/(\d+(?:\r)?\n\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}(?:\r)?\n)(.*?)(?=(?:(?:\r)?\n(?:\r)?\n|(?:\r)?\n\z))/m) do |m|
      "#{$1}#{fix_content($2)}"
    end
  end

  # def fix_content(content)
  #   rows_array = content.split("\n")
  #   rows_array.map! do |line| # applying desired rules
  #     # line = line.gsub(@brackets_regex,'') if @brackets_regex.present?
  #     # line = line.gsub(/\[.*\]/,'')
  #     # line = line.gsub(@narrator_regex,'')
  #     @rules.each{|rule| line = line.gsub(rule.regex,rule.to)}
  #     # @rules.each{|rule|
  #     #   puts "line: #{line.inspect}"
  #     #   line = line.gsub(rule.regex,rule.to)
  #     # }
  #
  #     fix_spaces(line)
  #   end.reject! do |line| # rejecting non words lines? (aka empty lines?)
  #     # line !~ /[\wא-ת]/ # raised Encoding::CompatibilityError (UTF-8 regexp with ASCII-8BIT string)
  #     line !~ /[[:alnum:]]/
  #     # not(line =~ /[\w]/ || line =~ /[א-ת]/)
  #   end
  #   # puts "rows_array: #{rows_array.inspect}"
  #   rows_array.compact.join("\n")
  # end

  def fix_content(content)
    new_content = content
    @rules.each{|rule| new_content = new_content.gsub(rule.regex,rule.to)}
    # binding.pry
    new_content.split("\n").reject do |line| # rejecting non words lines? (aka empty lines?)
      line !~ /[[:alnum:]]/
    end.compact.join("\n").squeeze(' ').strip
  end

  def fix_spaces(line)
    line.squeeze(' ').strip
  end

end

if $PROGRAM_NAME == __FILE__
  Bich2.run
end
#

# a.export(out_file: '3.srt')
