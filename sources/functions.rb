#!/usr/bin/ruby
require 'net/http'
require 'uri'
require 'base64'
# encoding: UTF-8

# load YAML config file
HOME = ENV["HOME"]

def load_lang
  $t = YAML.load_file("i18n/#{$c['lang']}.yml")
end

def load_config(file=nil)
  if !file
    $c = YAML.load_file("#{HOME}/.dinaip/config.yml")
  else
    # Import Configuration
    config = YAML.load_file(file)
    id = config['id']
    if id == $c['id'] 
      $c['pass'] = Base64.decode64(config['pass'])
      $c["#{id}_login"] = CopyHash(config["#{id}_login"])
      $c["domains_#{id}"] = CopyHash(config["domains_#{id}"])
      config["domains_#{id}"].map do |d|
        $c["zone_file__#{d}"] = CopyHash(config["zone_file__#{d}"])
        $c["zone_mx__#{d}"] = CopyHash(config["zone_mx__#{d}"])
        $c["#{d}_autodetect_ip"] = config["#{d}_autodetect_ip"]
      end
      if !$c['credentials'].nil?
          $c['credentials'].map do |c|
            if c[:user] == id
              c[:pass] = $c['pass']
              c[:remember_id] = $c["#{id}_login"][:remember_id]
            end
          end
      end
      $c['remember_pass'] = $c["#{id}_login"][:remember_pass]
      if !$c["#{id}_login"][:service].nil?
        $c['service'] = $c["#{id}_login"][:service]
        $c['start_onboot'] = $c["#{id}_login"][:start_onboot]
        $c['days'] = $c["#{id}_login"][:days]
        $c['hours'] = $c["#{id}_login"][:hours]
        $c['minutes'] = $c["#{id}_login"][:minutes]
        $c['days_check'] = $c["#{id}_login"][:days_check]
        $c['hours_check'] = $c["#{id}_login"][:hours_check]
        $c['minutes_check'] = $c["#{id}_login"][:minutes_check]
        $c['autodetect_ip'] = $c["#{id}_login"][:autodetect_ip]
        $c['start_minimized'] = $c["#{id}_login"][:start_minimized]
      end
      if $c['remember_pass_of_users'].nil?
        $c['remember_pass_of_users'] = []
      end
      if $c['remember_pass']
        $c['remember_pass_of_users'].push(id)
      else
        $c['remember_pass_of_users'].delete(id)
      end
      $c['remember_pass_of_users'].uniq!
    else
      error_dialog($t['wrong_file'])
    end
  end
  id = $c['id']
  $c["domains_#{id}"] = [] if $c["domains_#{id}"].nil?
end

# save YAML config file
def save(file=nil)
  if !file
    File.open("#{HOME}/.dinaip/config.yml", 'w') {|f| f << $c.to_yaml }
  else
    # Export Configuration
    id = $c['id']
    config = {}
    config["#{id}_login"] = CopyHash($c["#{id}_login"])
    config["domains_#{id}"] = CopyHash($c["domains_#{id}"])
    if !$c["domains_#{id}"].empty?
      $c["domains_#{id}"].map do |d|
        config["zone_file__#{d}"] = CopyHash($c["zone_file__#{d}"])
        config["zone_mx__#{d}"] = CopyHash($c["zone_mx__#{d}"])
        config["#{d}_autodetect_ip"] = $c["#{d}_autodetect_ip"]
      end
    end
    config['id'] = id
    if $c['remember_pass']
      config['pass'] = Base64.encode64($c['pass'])
    else
      config['pass'] = ""
    end
    File.open(file,'w') {|f| f << config.to_yaml }
  end
end

def CopyHash(x)
  Marshal.load(Marshal.dump(x))
end

def conn
  $srv = XMLRPC::Client.new2("https://dinahosting.com/special/dhRpc/interface.php")
end

def login(user, passwd, domain=false)
  # 'lin' stands for Linux version of the programme
  begin
    return $srv.call('loginDinaDNS', user, passwd, domain, 'lin')
  rescue
    begin
      return $srv.call('loginDinaDNS', user, passwd, domain, 'lin')
    rescue
      begin
        return $srv.call('loginDinaDNS', user, passwd, domain, 'lin')
      rescue
        error_dialog($t['no_connection'])
        return "no_net"
      end
    end
  end
end

def get_zones(domain)
  if !$username or !$password
    $username = $c['id']
    $password = $c['pass']
  end
  if $c['id'] == domain
    sld, tld = $c['id'].split(".")
    res = Net::HTTP.post_form(URI.parse('https://apisms.gestiondecuenta.com/php/comun/ejecutarComando.php'),
      { "command" => "dom_getZones", "uid" => $c['id'], "pw" => $c['pass'], 
          "sld" => sld, "tld" => tld })
    return res.body
  else
    begin
      return $srv.call('getZonesDomain', $username, $password, domain)
    rescue
      begin
        return $srv.call('getZonesDomain', $username, $password, domain)
      rescue
        return false
      end
    end
  end
end

def save_zones(domain,zone)
  if !$username or !$password
    $username = $c['id']
    $password = $c['pass']
  end
  if $c['id'] == domain
    sld, tld = $c['id'].split(".")
    hash_zone = Hash[zone.split("&").map{|i| i.scan(/^(.*)=(.*)$/).flatten}]
    hash_cmd = { "command" => "dom_setZones", "uid" => $c['id'], "pw" => $c['pass'], 
          "sld" => sld, "tld" => tld }
    hash = hash_cmd.merge(hash_zone)
    res = Net::HTTP.post_form(
      URI.parse('https://apisms.gestiondecuenta.com/php/comun/ejecutarComando.php'),
        hash)
    return res.body
  else
    begin
      conn
      return $srv.call('setZonesDomain', $username, $password, domain, zone)
    rescue
      error_dialog($t['no_connection'])
    end
  end
end

def get_current_ip
  begin
    return open('http://dinadns01.dinaserver.com/').read
  rescue
    begin
      return open('http://dinadns02.dinaserver.com/').read
    rescue
    end
  end
end

### cron ###
def kill(pid)
  pid = pid.to_i
  return if pid == 0
  begin
    Process.kill("HUP", pid)
  rescue
  end
  $pid = 0
  File.delete("#{HOME}/.dinaip/pid") if File.exist?("#{HOME}/.dinaip/pid")
end

def cron
  $pid = fork { 
    #Signal.trap("HUP") { puts "Ouch!"; exit }
    require 'cron.rb'
  }
  Process.detach($pid)
  File.open("#{HOME}/.dinaip/pid", 'w') {|f| f << $pid}
end

def save_zone(domain, zone_file, zone_mx)
  zone = "" # new empty zone
  num_zones = zone_file.length + zone_mx.length
  temp_zone = []
  temp_zone = zone_file | zone_mx
  temp_zone.map do |z|
    case z[:type]
    when "cnam"
      z[:type] = "CNAME"
    when "redi"
      z[:type] = "URL"
    when "r301"
      z[:type] = "URL_301"
    when "spf"
      z[:type] = "SPF"
    when "fram"
      z[:type] = "FRAME"
    when "TXT"
      z[:type] = "TXT"
    end
  end

  zone << "NumZones=#{num_zones}"
  zone_file.map do |z|
    n = zone_file.index(z)
    zone << "&Host#{n}=#{z[:host]}&Type#{n}=#{z[:type]}&Address#{n}=#{z[:addr]}"
  end
  zone_mx.map do |m|
    n = zone_mx.index(m) + zone_file.length
    zone << "&Host#{n}=#{m[:host]}&Type#{n}=#{m[:type]}&Address#{n}=#{m[:addr]}"
  end
  save_zones(domain, zone)
end
class Combo < Gtk::ComboBoxEntry
  def Combo.valor_defecto
    nil
  end
  def initialize
    super()
  end
  def make_list(vals)
    @vals = vals
    model = Gtk::ListStore.new(String)
    @vals.each do |v|
      append_text(v)
      iter = model.append
      iter[0] = v
    end
    comp = Gtk::EntryCompletion.new
    child.completion = comp
    comp.model = model
    comp.text_column = 0
    self
  end
end

def update(url)
  cmd = "wget #{url} -O -| tar zxf - -C /usr/local/dinaip/"
  system(cmd)
  cmd = "rm -rf /usr/local/dinaip/i18n/"
  system(cmd)
  cmd = "mv /usr/local/dinaip/dinaIP/* /usr/local/dinaip/"
  system(cmd)
  restart()
end

def restart
  pid = fork {
    IO.popen("/usr/local/dinaip/dinaip")
  }
  Process.detach(pid)
  Process.kill("SIGHUP", Process.pid)
end


def error_dialog(msg)
  dialog = Gtk::Dialog.new(
    "Error",
    $list,
    Gtk::Dialog::MODAL,
    [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK]
  )
  label = Gtk::Label.new(msg)
  hbox = Gtk::HBox.new(false,10)
  hbox.border_width = 10
  hbox.pack_start_defaults(label)
  dialog.vbox.add(hbox)
  dialog.show_all
  dialog.run
  dialog.destroy 
end

