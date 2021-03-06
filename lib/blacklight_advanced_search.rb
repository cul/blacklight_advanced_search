module BlacklightAdvancedSearch
  autoload :Controller, 'blacklight_advanced_search/controller'
  autoload :RenderConstraintsOverride, 'blacklight_advanced_search/render_constraints_override'
  autoload :CatalogHelperOverride, 'blacklight_advanced_search/catalog_helper_override'
  autoload :QueryParser, 'blacklight_advanced_search/advanced_query_parser'
  autoload :ParsingNestingParser, 'blacklight_advanced_search/parsing_nesting_parser'
  autoload :FilterParser, 'blacklight_advanced_search/filter_parser'

  require 'blacklight_advanced_search/version'
  require 'blacklight_advanced_search/engine'

  extend Blacklight::SearchFields # for search field config, so we can use same format as BL, or use ones already set in BL even. 
    
  # Has to be called in an after_initialize block, to have access
  # to Blacklight.config already configured, to look at it for defaults. 
  def self.init
    # apply defaults to anything not set. 
    BlacklightAdvancedSearch.config.reverse_merge!( BlacklightAdvancedSearch.config_defaults )
    
    logger.info("BlacklightAdvancedSearch.config: initialized with: #{ config.inspect }")
    Blacklight.config[:search_fields] << {:display_label => 'Advanced', :key => BlacklightAdvancedSearch.config[:url_key], :include_in_simple_select => false, :include_in_advanced_search => false} unless Blacklight.config[:search_fields].map { |x| x[:key] }.include?  BlacklightAdvancedSearch.config[:url_key]
  end

  def self.logger
    RAILS_DEFAULT_LOGGER
  end

  # Hash of our config. The :search_fields key in hash is used by
  # Blacklight::SearchFields module, must be an array of search field
  # definitions compatible with that module, or if missing will
  # inherit Blacklight.config[:search_fields]
  def self.config
    @config ||= {}
  end  

  # Has to be called in an after_initialize, to make sure Blacklight.config
  # is already defined. 
  def self.config_defaults
   config = {}
   config[:url_key] ||= "advanced"
   config[:qt] ||= Blacklight.config[:default_qt] ||  
      (Blacklight.config[:default_solr_params] && Blacklight.config[:default_solr_params][:qt])
   config[:form_solr_parameters] ||= {}

   
   config[:search_fields] ||= Blacklight.config[:search_fields].find_all do |field_def|
     (field_def[:qt].nil? || field_def[:qt] == config[:qt]) &&
     field_def[:include_in_advanced_search] != false
   end
   
   config
  end
  

  def self.solr_local_params_for_search_field(key)
  
    field_def = search_field_def_for_key(key)

    solr_params = (field_def[:solr_parameters] || {}).merge(field_def[:solr_local_parameters] || {})

    solr_params.collect do |key, val|
      key.to_s + "=" + solr_param_quote(val)
    end.join(" ")
    
    end

    def self.solr_param_quote(val)
      unless val =~ /^[a-zA-Z$_\-\^]+$/
        val = "'" + val.gsub("'", "\\\'").gsub('"', "\\\"") + "'"
      end
      return val
    end

end
