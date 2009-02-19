Given /^this is the first time I have run preen$/ do
  FileUtils.rm_rf PREEN_DIR
end

Given /^I have run "(.*)" once already$/ do |command|
  When "I run \"#{command}\""
end

Given /^that I have initialized preen$/ do
  When "I run \"preen init --pingfm-key #{PINGFM_USER_KEY} --url-pattern http://johndoe.example.com/\""
end

Given /^reddit is serving the following pages:$/ do |pages_table|
  pages_table.hashes.each do |page|
    @reddit.add_page(page['path'], IO.read(File.join(HTML_DIR, page['file'])))
  end
end

When /^I run "(.*)"$/ do |command|
  @reddit.run do
    with_test_env do
      response = `#{command}`
      unless $? == 0
        raise "Command `#{command}` failed (#{$?}) with output: '#{response}'"
      end
    end
  end
end

Then /^preen should remember that my (.*) is (.*)$/ do |key, value|
  with_test_env do
    key             =  Regexp.escape(key)
    value           =  Regexp.escape(value)
    response        =  `preen info`
    response.should =~ /#{key}:\s+#{value}/mi
  end
end

Then /^preen should announce "(.*)" on Ping\.fm$/ do |reddit_path|
  pattern = make_pingfm_request_pattern(reddit_path)
  @pingfm.should have_received_request(pattern)
end

Then /^preen should not announce "(.*)" on Ping\.fm$/ do |path|
  pattern = make_pingfm_request_pattern(reddit_path)
  @pingfm.should_not have_received_request(pattern)
end

Then /^preen should not announce any articles on Ping\.fm$/ do
  @pingfm.should have(0).requests
end

Then /^preen should scan the Reddit path "(.*)"$/ do |path|
  puts @reddit.requests.inspect
  @reddit.should have_received_request(:path_info => path)
end

Then /^preen should not scan the Reddit path "(.*)"$/ do |path|
  @reddit.should_not have_received_request(:path_info => path)
end
