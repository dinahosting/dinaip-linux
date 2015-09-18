#!/usr/bin/ruby
# encoding: UTF-8
require 'rubygems'
require 'yaml'
require 'rexml/document'
require 'xmlrpc/client'
require 'open-uri'

require './functions.rb'

load_config
loop_time = 0
if $c['minutes_check']
  loop_time += $c['minutes'] * 60
end
if $c['hours_check']
  loop_time += $c['hours'] * 3600
end
if $c['days_check']
  loop_time += $c['days'] * 86400
end
exit if loop_time == 0
while 1 do
  # check if autodetect ip in options is true
  #exit if $c['autodetect_ip'] == false

  # determine type of login we use 1=user,2=domain
  if $c['type'] == 1
    $domain = false
  elsif $c['type'] == 2
    $domain = true
  end
  conn
  res = login($c['id'], $c['pass'], $domain)
  exit if !res
  domains = $c["domains_#{$c['id']}"]
  domains.each do |d|
    #next if $c["#{d}_autodetect_ip"] == false
    hosts = []; types = []; addresses = []; zones_count = []
    original_zone = get_zones(d)
    doc = REXML::Document.new(original_zone)
    doc.elements.each('interface-response/zone/host') do |e|
      hosts << e.text
    end
    doc.elements.each('interface-response/zone/type') do |e|
      types << e.text
    end
    doc.elements.each('interface-response/zone/address') do |e|
      addresses << e.text
    end
    new_zone_file = []
    new_zone_mx = []
    for x in 0..hosts.count-1
      case types[x]
      when "A", "AAAA", "cnam", "CNAME", "fram", "FRAME", "redi", "r301", "TXT"
        dynamic = false
        if $c.include? "zone_file__#{d}"
          if $c["zone_file__#{d}"]
            $c["zone_file__#{d}"].map do |cd|
              if hosts[x] == cd[:host]
                dynamic = cd[:dynamic]
              end
            end
          end
        end
        if dynamic == false
          new_zone_file << { :host => hosts[x], :type => types[x], :addr => addresses[x], :dynamic => false }
        else
          ip = get_current_ip
          new_zone_file << { :host => hosts[x], :type => types[x], :addr => ip, :dynamic => true }
        end # if
      else
        new_zone_mx << { :host => hosts[x], :type => types[x], :addr => addresses[x] }
      end # when
    end # for
    save_zone(d, new_zone_file, new_zone_mx)
    $c["zone_file__#{d}"] = new_zone_file
    $c["zone_mx__#{d}"] = new_zone_mx
    save
  end # domain.map
  sleep loop_time
end
