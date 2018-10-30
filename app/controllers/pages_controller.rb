class PagesController < ApplicationController
  require 'zip'
  ZIP_FILE_NAME = 'srt_files.zip'

  def home
  end

  def upload
    if params[:srt_files].size > 1#  multiple files
      compressed_filestream = Zip::OutputStream.write_buffer do |zos|
        params[:srt_files].each do |srt_file|
          zos.put_next_entry srt_file.original_filename

          bich = Bich2.new_from_file_path(srt_file.tempfile.path)
          zos.print bich.export_to_text
        end
      end
      compressed_filestream.rewind
      data, file_name = compressed_filestream.read, ZIP_FILE_NAME
    else # single file
      srt_file = params[:srt_files].first
      tempfile = srt_file.tempfile
      bich = Bich2.new_from_file_path(tempfile.path)
      data, file_name = bich.export_to_text, srt_file.original_filename
    end

    send_data data, filename: file_name
  end

end
