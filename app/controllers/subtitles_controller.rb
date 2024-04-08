class SubtitlesController < ApplicationController
  protect_from_forgery except: :fetch_subtitles

  require 'zip'
  ZIP_FILE_NAME = 'srt_files.zip'


      # - Addic7ed
      # - BSPlayer
      # - OpenSubtitles
      # - Podnadpisi.NET
      # - Subscene
      # - subDB

  # curl -F filename='Sharknado.2.The.Second.One.2014.1080p.BluRay.x264.YIFY' lvh.me:3006/fetch_subtitles -o new_file.srt
  # curl -F filename='Sharknado.2.The.Second.One.2014.1080p.BluRay.x264.YIFY' lvh.me:3006/fetch_subtitles -o new_file.srt
  def fetch_subtitles
    os = OpenSubtitle.new(
      username: Rails.application.credentials.dig(:opensubtitles, :username),
      password: Rails.application.credentials.dig(:opensubtitles, :password),
      api_key: Rails.application.credentials.dig(:opensubtitles, :api_key),
      user_agent: params[:user_agent] || 'RokoApp v1.0.0',
    )
    filename = params[:filename]
    filename = filename.sub(/\.mp4|\.avi|\.mkv/i,'')

    srt_texts = os.fetch_subtitle(filename: filename, amount: params[:amount] || 3, lang: params[:lang] || 'en')
    case srt_texts.length
    when 0
      # head :ok
      send_data nil, filename: 'not_found.srt'
    when 1
      if params[:output_format] == 'zip'
        compressed_filestream = Zip::OutputStream.write_buffer do |zos|
          srt_texts.each.with_index(1) do |srt_text, index|
            zos.put_next_entry "#{filename}.srt"

            zos.print srt_text.body.to_s
          end
        end
        compressed_filestream.rewind
        data, file_name = compressed_filestream.read, ZIP_FILE_NAME

        send_data data, filename: file_name
      else
        send_data srt_texts[0], filename: "#{filename}.srt"
      end
    else
      compressed_filestream = Zip::OutputStream.write_buffer do |zos|
        srt_texts.each.with_index(1) do |srt_text, index|
          zos.put_next_entry "#{filename}_#{index}.srt"

          zos.print srt_text.body.to_s
        end
      end
      compressed_filestream.rewind
      data, file_name = compressed_filestream.read, ZIP_FILE_NAME

      send_data data, filename: file_name
    end
  end

  private

end
