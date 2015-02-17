require_relative './spec_helper.rb'

describe 'ReferencePageGenerator', fakefs:true do

  before(:each) do
    @site = Jekyll::Site.new(Jekyll.configuration({
      "skip_config_files" => true,
      "json_schema_schema_uri" => "http://json-schema.org/draft-04/schema#",
      "ramler_api_paths" => {
        'api.json' => '',
        '/productA/api.json' => '/productA/',
        'service.json' => '/'}
    }))
    @rpg = Jekyll::ReferencePageGenerator.new

    FakeFS.activate!
    Pry.config.history.should_save = false;
    Pry.config.history.should_load = false;

    FileUtils.mkdir_p('_layouts')
    File.open('_layouts/default.html', 'w') { |f| f << "{{ content }}" }

    File.open('api.json', 'w') do |f|
      f << JSON.pretty_generate(load_simple_raml)
    end

    FileUtils.mkdir_p('productA')
    File.open('productA/api.json', 'w') do |f|
      f << JSON.pretty_generate(load_simple_raml)
    end

    File.open('service.json', 'w') do |f|
      f << JSON.pretty_generate(load_simple_raml)
    end
  end

  after(:each) do
    FakeFS.deactivate!
  end

  context 'Configuration' do

    it 'reads "api.json" if no ramler_api_paths is provided' do
      @site.config.delete('ramler_api_paths')
      expect(File).to receive(:open).with('api.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      @rpg.generate(@site)
    end

    it 'reads ramls listed in the ramler_api_paths configuration mapping' do
      expect(File).to receive(:open).with('api.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      expect(File).to receive(:open).with('/productA/api.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      expect(File).to receive(:open).with('service.json').and_return(StringIO.new(JSON.pretty_generate(load_simple_raml)))
      @rpg.generate(@site)
    end

    it 'places generated content into folders based on the ramler_api_paths configuration mapping' do
      # Relying on some default values in this test
        
      @site.config['ramler_api_paths'].delete('api.json')
      @rpg.generate(@site)
      @site.process

      # Look for files generated from service.json
      expect(File.file?('_site/api.raml')).to be true
      expect(File.directory?('_site/resource')).to be true

      # Look for files generated from 
      expect(File.directory?('_site/productA')).to be true
      expect(File.file?('_site/productA/api.raml')).to be true
      expect(File.directory?('_site/productA/resource')).to be true
    end

    it 'defaults to web root for any unconfigured ramls'
    it 'throws an error if ramler_api_paths includes a value without a trailing slash'
    it 'defaults to "resource", "overview", and "security" for generated folders'
    it 'places generated content into folders based on ramler_generated_sub_dirs configuration mapping'
    it 'names downloadable descriptors "api.raml" and "api.json" by default'
    it 'names downloadable descriptors based on ramler_downloadable_basename'
  end
end
