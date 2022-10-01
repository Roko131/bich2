class PagesController < ApplicationController
  protect_from_forgery except: :api_upload

  require 'zip'
  ZIP_FILE_NAME = 'srt_files.zip'

  def home
  end

  def upload
    bich_params = get_params_for_bich(params)

    if params[:srt_files].size > 1#  multiple files
      compressed_filestream = Zip::OutputStream.write_buffer do |zos|
        params[:srt_files].each do |srt_file|
          raise "not supported file type: #{srt_file.original_filename}" and return unless File.extname(srt_file.original_filename) == '.srt'

          zos.put_next_entry srt_file.original_filename

          bich = Bich2.new_from_file_path(srt_file.tempfile.path, bich_params)
          zos.print bich.export_to_text
        end
      end
      compressed_filestream.rewind
      data, file_name = compressed_filestream.read, ZIP_FILE_NAME
    else # single file
      srt_file = params[:srt_files].first
      raise "not supported file type: #{srt_file.original_filename}" and return unless File.extname(srt_file.original_filename) == '.srt'

      tempfile = srt_file.tempfile
      bich = Bich2.new_from_file_path(tempfile.path, bich_params)
      data, file_name = bich.export_to_text, srt_file.original_filename
    end

    send_data data, filename: file_name
  end

  # curl -F ‘data=@path/to/local/file’ UPLOAD_ADDRESS
  # curl -F 'srt_file=@/home/nirr/my_apps/dev_apps/bich/aa.srt' lvh.me:3001/api_upload -o new_file.srt
  # curl -F 'srt_file=@/home/nirr/my_apps/dev_apps/bich/aa.srt' -F remove_css=true lvh.me:3001/api_upload -o new_file.srt
  def api_upload
    # binding.pry
    uploaded_file = params[:srt_file]
    raise "not supported file type: #{uploaded_file.original_filename}" and return unless File.extname(uploaded_file.original_filename) == '.srt'
    srt_text_utf8 = uploaded_file.read
    bich_options = {remove_css: params[:remove_css]}
    bich_options[:narrator] = :easy if params[:narrator_easy]
    bich = Bich2.new(srt_text_utf8, **bich_options)
    data, file_name = bich.export_to_text, uploaded_file.original_filename

    send_data data, filename: file_name
  end


  # curl -F 'srt_file=@/home/nirr/my_apps/dev_apps/bich/aa.srt' lvh.me:3001/api_remove_css -o new_file.srt
  def api_remove_css
    uploaded_file = params[:srt_file]
    srt_text_utf8 = uploaded_file.read
    data, file_name = Bich2.remove_css(srt_text_utf8), uploaded_file.original_filename

    send_data data, filename: file_name
  end

private

  def get_params_for_bich(params)
    res = {brackets_types: params[:brackets_types]}
    res[:remove_css] = true if params[:remove_css]
    res[:narrator] = :easy if params[:narrator_easy]
    res
  end

end
