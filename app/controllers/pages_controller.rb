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
          zos.put_next_entry srt_file.original_filename

          bich = Bich2.new_from_file_path(srt_file.tempfile.path, bich_params)
          zos.print bich.export_to_text
        end
      end
      compressed_filestream.rewind
      data, file_name = compressed_filestream.read, ZIP_FILE_NAME
    else # single file
      srt_file = params[:srt_files].first
      tempfile = srt_file.tempfile
      bich = Bich2.new_from_file_path(tempfile.path, bich_params)
      data, file_name = bich.export_to_text, srt_file.original_filename
    end

    send_data data, filename: file_name
  end

  # curl -F ‘data=@path/to/local/file’ UPLOAD_ADDRESS
  # curl -F 'srt_file=@/home/nirr/my_apps/dev_apps/bich/aa.srt' lvh.me:3001/api_upload -o new_file.srt
  def api_upload
    # binding.pry
    uploaded_file = params[:srt_file]
    srt_text_utf8 = uploaded_file.read
    bich = Bich2.new(srt_text_utf8)
    data, file_name = bich.export_to_text, uploaded_file.original_filename

    send_data data, filename: file_name
  end

  private

    def get_params_for_bich(params)
      {brackets_types: params[:brackets_types]}
    end

end
