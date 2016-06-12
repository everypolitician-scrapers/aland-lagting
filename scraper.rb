#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def scrape_list(url)
  noko = noko_for(url)
  links = noko.css('#block-views-ledamoter-pages-party-block a[href*="ledamoter"]/@href').map(&:text)
  raise "No links found" unless links.any?
  links.each do |link|
    scrape_mp(URI.join(url, link))
  end
 end

def scrape_mp(url)
  noko = noko_for(url)

  box = noko.css('div#news')
  om = noko.css('#block-views-ledamot-detaljer-info')
  contact = noko.css('#block-views-ledamot-detaljer-block-1')

  named = ->(t) { box.xpath("(.//strong[contains(.,'#{t}')] | .//b[contains(.,'#{t}')])/following-sibling::text()") }
  data = { 
    id: url.to_s.split("/").last,
    name: noko.css('h1').text.tidy,
    image: noko.css('img[typeof="foaf:Image"]/@src').text.sub(/\?.*/,''),
    email: contact.css('a[href*="mailto:"]').text,
    phone: contact.css('a[href*="tel:"]').text,
    party: om.xpath('.//span[strong[.="Lagtingsgrupp:"]]/following-sibling::span//text()').first.text.tidy,
    birth_date: om.xpath('.//span[strong[.="Född:"]]/following-sibling::span//text()').first.text.tidy,
    term: 2015,
    source: url.to_s,
  }
  data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.lagtinget.ax/ledamoter')
