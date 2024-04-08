class OpenSubtitle

  def initialize(api_key:, username:, password: , user_agent: )
    # @api_key    = api_key
    # @username   = username
    @password   = password
    @user_agent = user_agent
    @headers = {
      'Accept'        => 'application/json',
      'Content-Type'  => 'application/json',
      'User-Agent'    => user_agent,
      'Api-Key'       => api_key,
    }
    jwt = get_jwt(username, password)
    @headers['Authorization'] = "Bearer #{jwt}"
  end

  # ai_translated: string, # exclude, include (default: include)
  # episode_number: integer, # For Tvshows
  # foreign_parts_only: string, # exclude, include, only (default: include)
  # hearing_impaired: string, # include, exclude, only. (default: include)
  # id: integer, # ID of the movie or episode
  # imdb_id: integer, # IMDB ID of the movie or episode
  # languages: string, # Language code(s), comma separated, sorted in alphabetical order (en,fr)
  # machine_translated: string, # exclude, include (default: exclude)
  # moviehash: string, # Moviehash of the moviefile >= 16 characters <= 16 characters Match pattern: ^[a-f0-9]{16}$
  # moviehash_match: string, # include, only (default: include)
  # order_by: string, # Order of the returned results, accept any of above fields
  # order_direction: string, # Order direction of the returned results (asc,desc)
  # page: integer, # Results page to display
  # parent_feature_id: integer, # For Tvshows
  # parent_imdb_id: integer, # For Tvshows
  # parent_tmdb_id: integer, # For Tvshows
  # query: string, # file name or text search (we do guessit first)
  # season_number: integer, # For Tvshows
  # tmdb_id: integer, # TMDB ID of the movie or episode
  # trusted_sources: string, # include, only (default: include)
  # type: string, # movie, episode or all, (default: all)
  # user_id: integer, # To be used alone - for user uploads listing
  # year: integer, # Filter by movie/episode year
  def get_files(filename: ,lang: )
    params = {
      query: filename,
      languages: 'en',
    }
    res = JSON.parse((res2 = HTTP.follow.headers(@headers).get("https://api.opensubtitles.com/api/v1/subtitles?#{params.to_query}")))

    files = res.dig('data').map do |data|
      {
        hearing_impaired: data.dig('attributes','hearing_impaired'),
        file_id: data.dig('attributes','files',0,'file_id'),
      }
    end
    files
  end

  def download_file(file_id:, filename: nil)
    params = {
      file_id: file_id,
      file_name: filename,
    }

    res = JSON.parse((res2 = HTTP.follow.headers(@headers).post('https://api.opensubtitles.com/api/v1/download', json: params)))
    a = HTTP.get(res['link'])
    # a.body.to_s
  end

  def fetch_subtitle(filename: ,lang: 'en', amount: 1, hearing_impaired_last: nil, **options)
    amount = [amount.to_i,1].max
    files = get_files(filename: filename, lang: lang, **options)
    return [] unless files.present?

    files.sort_by!{|file_h| file_h[:hearing_impaired] ? 1 : -1} if hearing_impaired_last

    srt_texts = files[0...amount].map do |file_h|
      download_file(file_id: file_h[:file_id])
    end
  end

private

  def get_jwt(username, password)
    params = {
      username: username,
      password: password,
    }

    res = HTTP.follow.headers(@headers).post('https://api.opensubtitles.com/api/v1/login', json: params)
    hash = JSON.parse(res)
    hash['token']
  end

end
