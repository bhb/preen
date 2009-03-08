require 'rubygems'
require 'open-uri'
require 'mechanize'
require 'ick'
require 'logger'

class Preen::HackerNews
  Ick::Returning.belongs_to self
  
  def initialize(home_url = "http://www.reddit.com/r/programming/",
                 log      = Logger.new($stderr))
    @home_url = home_url
    @log      = log
    @agent    = WWW::Mechanize.new
    if $DEBUG
      require 'logger'
      logger = Logger.new($stderr)
      logger.level = Logger::DEBUG
      @agent.log = logger
    end
  end

  # Starting at +home_url+, scan +num_pages+ for a Reddit entry that matches
  # +url_pattern+
  def scan_pages(num_pages, url_pattern)
    returning([]) do |mentions|
      current_page = nil
      num_pages.times do |page_number|
        current_page = get_next_page(current_page)
        @log.info "Scanning #{current_page.uri} for #{url_pattern}"
        current_page.search('//tr[td[@class="title"]]').each do |entry|
          link_anchor = entry.xpath('td[3]/a').first
          comment_anchor = entry.xpath("following-sibling::tr[1]/td[2]/a[2]").first
          link = nil
          if(link_anchor)
            link = link_anchor['href']
          end
          if url_pattern === link && comment_anchor
            comment_url = comment_anchor['href']
            mentions << Preen::Mention.new(link, comment_url)
          end
        end
      end
    end
  end

  private
  
  def get_next_page(current_page)
    case current_page
    when nil
      @agent.get(@home_url)
    else
      current_page.link_with(:text => 'More').click
    end
  end

end
