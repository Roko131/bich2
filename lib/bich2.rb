class Bich2

  DEFAULT_OUTPUT_FOLDER = 'new_files'
  OLD_FOLDER    = 'old'

  def initialize(srt_text_utf8, narrator: nil)
    # @srt_text = srt_text_utf8
    @narrator_regex = case narrator
    when :easy; /[A-Z -]+: /
    else /[\w ]+: /
    end
    @converted_text = convert_text(srt_text_utf8).freeze
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

  private

    def convert_text(text)
      text.gsub(/(\d+(?:\r)?\n\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}(?:\r)?\n)(.*?)(?=(?:(?:\r)?\n(?:\r)?\n|(?:\r)?\n\z))/m) do |m|
        "#{$1}#{fix_content($2)}"
      end
    end

    def fix_content(content)
      rows_array = content.split("\n")
      rows_array.map! do |line|
        line = line.gsub(/\[.*\]/,'')
        line = line.gsub(@narrator_regex,'')

        fix_spaces(line)
      end.reject! do |line|
        line !~ /[\wא-ת]/
        # not(line =~ /[\w]/ || line =~ /[א-ת]/)
      end
      # puts "rows_array: #{rows_array.inspect}"
      rows_array.compact.join("\n")
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
