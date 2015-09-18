#!/usr/bin/ruby
# This module contains all GTK Windows - well structured and organized
class Options < Gtk::Window
  def initialize()
    @main_vbox = Gtk::VBox.new(false,5)
    @hbox2 = Gtk::HBox.new(true,10) # save/discard buttons
    @hbox1 = Gtk::HBox.new # check buttons
    @main_vbox.add(@hbox1)
    @main_vbox.add(@hbox2)

    frame2 = Gtk::Frame.new
    frame3 = Gtk::Frame.new
    start_onboot = Gtk::CheckButton.new $t['start_onboot']
    start_minimized = Gtk::CheckButton.new $t['start_minimized']
    autodetect_ip = Gtk::CheckButton.new $t['autodetect_ip']
    start_onboot.signal_connect("toggled") { $c['start_onboot'] = start_onboot.active? }
    start_minimized.signal_connect("toggled") { $c['start_minimized'] = start_minimized.active? }
    autodetect_ip.signal_connect("toggled") { $c['autodetect_ip'] = autodetect_ip.active? }
    if $c['start_minimized'].nil?
        $c['start_minimized'] = false # default option if there is no config
    else
        start_minimized.active = $c['start_minimized']
    end

    if $c['autodetect_ip'].nil?
        $c['autodetect_ip'] = true
    else
        autodetect_ip.active = $c['autodetect_ip']
    end

    if $c['start_onboot'].nil?
        $c['start_onboot'] = true
          start_onboot.active = true
    else
        start_onboot.active = $c['start_onboot']
    end
    @vbox_options = Gtk::VBox.new
    @vbox_options.border_width = 10
    frame2_vbox = Gtk::VBox.new
    frame2_vbox.pack_start(start_onboot).pack_start(start_minimized)
    frame2.add(frame2_vbox)
    frame3.add(autodetect_ip)
    ### cron stuff : mins, hours & days
    # minutes menu
    @minutes = []
    minutes_menu = Gtk::Menu.new
    for x in 1..6 do
      @minutes[x] = Gtk::MenuItem.new(x.to_s + 0.to_s)
      minutes_menu.append(@minutes[x])
    end
    minutes_optionmenu = Gtk::OptionMenu.new
    minutes_optionmenu.menu = minutes_menu

    if $c['minutes'].nil?
      $c['minutes'] = 10;
      save
    else
      index = ($c['minutes'] / 10) - 1
      minutes_optionmenu.history = index
    end

    minutes_optionmenu.signal_connect('changed') { $c['minutes'] = (minutes_optionmenu.history + 1) * 10 }
    # minutes checkbox
    hbox = Gtk::HBox.new
    minutes_check = Gtk::CheckButton.new($t['minutes'])
    if $c['minutes_check'].nil?
      $c['minutes_check'] = true
      save
    else
      minutes_check.active = $c['minutes_check']
    end
    minutes_check.signal_connect("toggled") { $c['minutes_check'] = minutes_check.active? }
    hbox.add(minutes_optionmenu).add(minutes_check)
    #add the minutes to the options
    @vbox_options.add(hbox)
    # hours menu
    @hours = []
    hours_menu = Gtk::Menu.new
    for x in 1..24 do
      @hours[x] = Gtk::MenuItem.new(x.to_s)
      hours_menu.append(@hours[x])
    end
    hours_optionmenu = Gtk::OptionMenu.new
    hours_optionmenu.menu = hours_menu

    if $c['hours'].nil?
      $c['hours'] = 1;
      save
    else
      index = $c['hours'] - 1
      hours_optionmenu.history = index
    end
    hours_optionmenu.signal_connect('changed') { $c['hours'] = hours_optionmenu.history + 1 }
    # hours checkbox
    hbox = Gtk::HBox.new
    hours_check = Gtk::CheckButton.new($t['hours'])
    if $c['hours_check'].nil?
      $c['hours_check'] = false
      save
    else
      hours_check.active = $c['hours_check']
    end
    hours_check.signal_connect("toggled") { $c['hours_check'] = hours_check.active? }
    hbox.add(hours_optionmenu).add(hours_check)
    # add hours option menu's hbox to the global vbox of the window
    @vbox_options.add(hbox)
    # days menu
    @days = []
    days_menu = Gtk::Menu.new
    for x in 1..31 do
      @days[x] = Gtk::MenuItem.new(x.to_s)
      days_menu.append(@days[x])
    end
    days_optionmenu = Gtk::OptionMenu.new
    days_optionmenu.menu = days_menu

    if $c['days'].nil?
      $c['days'] = 1;
      save
    else
      index = $c['days'] - 1
      days_optionmenu.history = index
    end
    days_optionmenu.signal_connect('changed') { $c['days'] = days_optionmenu.history + 1}
    # days checkbox
    hbox = Gtk::HBox.new
    days_check = Gtk::CheckButton.new($t['days'])
    if $c['days_check'].nil?
      $c['days_check'] = false
      save
    else
      days_check.active = $c['days_check']
    end
    days_check.signal_connect("toggled") { $c['days_check'] = days_check.active? }
    hbox.add(days_optionmenu).add(days_check)

    @vbox_options.add(hbox)
    frame1 = Gtk::Frame.new($t['execute_every'])
    frame1.border_width = 10
    frame1.add(@vbox_options)
    frame_vbox = Gtk::VBox.new
    frame_hbox = Gtk::HBox.new
    frame_vbox.add(frame2).add(frame3)
    frame_hbox.add(frame1).add(frame_vbox)
    @hbox1.add(frame_hbox)
    # discard & save changes buttons
    discard_changes = Gtk::Button.new($t['discard_changes'])
    save_changes = Gtk::Button.new($t['save_changes'])
    @hbox2.pack_start(discard_changes,false,false,10).pack_start(save_changes,false,false,10)

    discard_changes.signal_connect("clicked") do
      self.destroy
      $list.show_all
    end

    save_changes.signal_connect("clicked") do
      if $c['service'] == true
        kill $pid
        cron
      else
        kill $pid
      end
      if $c['start_onboot']
        system("cp /usr/share/applications/dinaip.desktop #{ENV['HOME']}/.config/autostart")
      else
        system("rm -rf #{ENV['HOME']}/.config/autostart/dinaip.desktop")
      end
      id = $c['id']
      $c["#{id}_login"][:service] = $c['service']
      $c["#{id}_login"][:start_onboot] = $c['start_onboot']
      $c["#{id}_login"][:days] = $c['days']
      $c["#{id}_login"][:hours] = $c['hours']
      $c["#{id}_login"][:minutes] = $c['minutes']
      $c["#{id}_login"][:days_check] = $c['days_check']
      $c["#{id}_login"][:hours_check] = $c['hours_check']
      $c["#{id}_login"][:minutes_check] = $c['minutes_check']
      $c["#{id}_login"][:autodetect_ip] = $c['autodetect_ip']
      $c["#{id}_login"][:start_minimized] = $c['start_minimized']

      save
      self.destroy
      $list.show_all
    end

    super()
    self.set_window_position Gtk::Window::POS_CENTER
    self.title = "%s DinaIP" % $t['options']
    self.resizable = false
    self.set_size_request 500,250
    self.border_width = 15
    self.add(@main_vbox)
    self.show_all
  end
end

class Login < Gtk::Window
  def initialize()


    # main boxes
    # horizontal
    hbox = Gtk::HBox.new(true, 40)
    # Main vertical
    vbox = Gtk::VBox.new(false, 10)
    # vertical second
    login_vbox = Gtk::VBox.new(true,10)
    login_vbox.border_width = 20
    c_frame = Gtk::Frame.new($t['connect'])
    bash_login_vbox = Gtk::VBox.new(false, 10)
    bash_login_vbox.border_width = 10
    c_frame.add(bash_login_vbox)
    vbox.add(c_frame)
    vbox.add(login_vbox)
    vbox.add(hbox)
    @eventbox = Gtk::EventBox.new
    @eventbox.add(vbox)
    
    # Type of identifier: User or Domain
    if $c['type'] == 1
      $domain = false
      type_user = Gtk::RadioButton.new($t['user'])
      type_domain = Gtk::RadioButton.new(type_user, $t['domain'])
    elsif $c['type'] == 2
      $domain = true
      type_domain = Gtk::RadioButton.new($t['domain'])
      type_user = Gtk::RadioButton.new(type_domain, $t['user'])
    end
    type_user.signal_connect("toggled") { $c['type'] = 1;  save; $domain = false }
    type_domain.signal_connect("toggled") { $c['type'] = 2; save; $domain = true }
    type_hbox= Gtk::HBox.new(true,50)
    type_hbox.pack_start(type_user,true,true,0)
    type_hbox.pack_start(type_domain,true,true,0)
    bash_login_vbox.pack_start(type_hbox,true,true,0)
    # user & pass
    user_label = Gtk::Label.new($t['identifier'])
    known_usernames = []
    if !$c['credentials'].nil?
      $c['credentials'].map do |cred|
        known_usernames << cred[:user] if cred[:remember_id]
      end
      known_usernames.uniq!
    end
    @user = Combo.new.make_list(known_usernames)
    @user.set_size_request(150,30)
    @user.child.text = $c['id'] if $c['remember_id']
    @user.child.signal_connect("changed") {
      if $c["#{@user.child.text}_login"]
        $c['connect'] = $c["#{@user.child.text}_login"][:connect]
        $c['newver'] = $c["#{@user.child.text}_login"][:newver]
        $c['remember_id'] = $c["#{@user.child.text}_login"][:remember_id]
        $c['remember_pass'] = $c["#{@user.child.text}_login"][:remember_pass]
        $c['lang'] = $c["#{@user.child.text}_login"][:lang]
        $c['type'] = $c["#{@user.child.text}_login"][:type]
        @check.active = $c['remember_id']
        @check2.active = $c['remember_pass']
        @check3.active = $c['connect']
        @check4.active = $c['newver']
        if $c['lang'] == 'en'
          @l_cb.set_active(0)
        else
          @l_cb.set_active(1)
        end
        if $c['type'] == 1
          $domain = false
        elsif $c['type'] == 2
          $domain = true
        end
      else
        @check.active = true
        @check2.active = true 
        @check3.active = true
        @check4.active = true
        $c['connect'] = true
      end

      if $c['remember_pass']
        if $c['remember_pass_of_users'].nil?
          $c['remember_pass_of_users'] = []
        end
        remembered_pass = ""
        if !$c['credentials'].nil?
          $c['credentials'].map do |cred|
            if cred[:user] == @user.child.text and $c['remember_pass_of_users'].include? @user.child.text
              remembered_pass = cred[:pass]
            end
          end
          @pass.text = remembered_pass
        end
      else
        @pass.text = ""
      end
    }
    user_hbox1 = Gtk::HBox.new(true, 10)
    user_hbox1.pack_start(user_label,true,true,0)
    user_hbox1.pack_start(@user,true,true,0)
    bash_login_vbox.pack_start(user_hbox1, true, true, 0)
    pass_label = Gtk::Label.new($t['password'])
    @pass = Gtk::Entry.new
    @pass.visibility=false
    if $c['remember_pass'] and $c['remember_id']
      @pass.text = $c['pass'] 
    end
    pass_hbox1 = Gtk::HBox.new(true, 10)
    pass_hbox1.pack_start(pass_label,true,true,0)
    pass_hbox1.pack_start(@pass,true,true,0)
    bash_login_vbox.pack_start(pass_hbox1, true, true, 0)

    # check boxes
    @check = Gtk::CheckButton.new($t['remember_id'])
    @check.active = $c['remember_id']
    @check.signal_connect("toggled") { $c['remember_id'] = @check.active? }
    login_vbox.add(@check)
    @check2 = Gtk::CheckButton.new($t['remember_pass'])
    @check2.active = $c['remember_pass']
    @check2.signal_connect("toggled") { $c['remember_pass'] = @check2.active? }
    login_vbox.add(@check2)
    @check3 = Gtk::CheckButton.new($t['connect_auto'])
    @check3.active = $c['connect']
    @check3.signal_connect("toggled") { $c['connect'] = @check3.active? }
    login_vbox.add(@check3)
    @check4 = Gtk::CheckButton.new($t['newver'])
    @check4.active = $c['newver']
    @check4.signal_connect("toggled") { $c['newver'] = @check4.active? }
    login_vbox.add(@check4)

    # language
    hbox_lang = Gtk::HBox.new(false,2)
    lang_label = Gtk::Label.new($t['lang'])
    @l_cb = Gtk::ComboBox.new
    @l_cb.append_text("English")
    @l_cb.append_text("Castellano")
    @l_cb.signal_connect("changed") {
      if @l_cb.active_text == "Castellano"
        $c['lang'] = 'es'
      else
        $c['lang'] = 'en'
      end
    }
    hbox_lang.pack_start(lang_label,false,false,0).pack_start(@l_cb,false,false,0)
    login_vbox.add(hbox_lang)
    if !$c["#{$c['id']}_login"].nil?
      $c['lang'] = $c["#{$c['id']}_login"][:lang]
    end
    if $c['lang'] == 'en'
      @l_cb.set_active(0)
    else
      @l_cb.set_active(1)
    end

    # login & exit
    button1 = Gtk::Button.new($t['accept'])
    button1.signal_connect("clicked") {
      if @user.child.text.length > 0 && @pass.text.length > 0
        @eventbox.window.cursor = $watch
        GLib::Idle.add {
        conn
        $res = login(@user.child.text, @pass.text, $domain)
        if $res and $res != "no_net"


          if $c['credentials'].nil?
            $c['credentials'] = []
          end
          if $c['remember_pass_of_users'].nil?
            $c['remember_pass_of_users'] = []
          end
          if $c['remember_pass']
            $c['remember_pass_of_users'].push(@user.child.text)
          else
            $c['remember_pass_of_users'].delete(@user.child.text)
          end
          $c['remember_pass_of_users'].uniq!
          $c['credentials'] << { :user => @user.child.text, :pass => @pass.text, :remember_id => $c['remember_id']}
          $c['credentials'].map do |cred|
            if cred[:user] == @user.child.text
              cred[:remember_id] = $c['remember_id']
            end
          end
          $c['credentials'].uniq!          

          $c['id'] = @user.child.text
          $c['pass'] = @pass.text

          if $c["#{@user.child.text}_login"].nil?
            $c["#{@user.child.text}_login"] = {}
          end
          $c["#{@user.child.text}_login"][:connect] = $c['connect']
          $c["#{@user.child.text}_login"][:newver] = $c['newver']
          $c["#{@user.child.text}_login"][:remember_id] = $c['remember_id']
          $c["#{@user.child.text}_login"][:remember_pass] = $c['remember_pass']
          $c["#{@user.child.text}_login"][:lang] = $c['lang']
          $c["#{@user.child.text}_login"][:type] = $c['type']
          id = @user.child.text
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
          save

          ver = $res['version']['version'].to_f
          url = $res['version']['url']
          type = $res['version']['nivel_auth']
          $t['update_required'].gsub!(/XXX/) { ver }
          $t['update_must'].gsub!(/XXX/) { ver }
          $t['update_optional'].gsub!(/XXX/) { ver }
          if $VERSION < ver && $c['newver']
            if type != "REQUIRED"
              dialog = Gtk::Dialog.new("Update", self,
                             Gtk::Dialog::MODAL,
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT],
                             [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])
              if type == "MUST"
                label = Gtk::Label.new($t['update_must'])
              elsif type == "OPTIONAL"
                label = Gtk::Label.new($t['update_optional'])
              end
              hbox = Gtk::HBox.new(false,10)
              hbox.border_width = 10
              hbox.pack_start_defaults(label)
              dialog.vbox.add(hbox)
              dialog.show_all
              dialog.run do |response|
                if response == Gtk::Dialog::RESPONSE_ACCEPT
                  update(url)
                end
                dialog.destroy
              end
            else
              dialog = Gtk::Dialog.new(
              "Update",
              self,
              Gtk::Dialog::MODAL,
              [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK]
              )
              label = Gtk::Label.new($t['update_required'])
              hbox = Gtk::HBox.new(false,10)
              hbox.border_width = 10
              hbox.pack_start_defaults(label)
              dialog.vbox.add(hbox)
              dialog.show_all
              dialog.run
              dialog.destroy
              update(url)
            end
          end
          # user & pass are correct, we'll use those for later API Calls
          $username = @user.child.text
          $passsword = @pass.text
          if @l_cb.active_text == "Castellano"
            $c['lang'] = 'es'
          elsif @l_cb.active_text == "English"
            $c['lang'] = 'en'
          end
          save
          load_lang
          $list = List.new
          $list.show_all
          self.destroy
          if $c['service'].nil?
            $c['service'] = true
            save
            cron if $pid.nil?
          else
            if $c['service'] == true and $pid.nil?
              cron
            end
          end
          $connected = true
        elsif $res == false
          dialog = Gtk::Dialog.new(
            "Error",
            self,
            Gtk::Dialog::MODAL,
            [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK]
          )
          label = Gtk::Label.new($t['wrong_credentials'])
          hbox = Gtk::HBox.new(false,10)
          hbox.border_width = 10
          hbox.pack_start_defaults(label)
          dialog.vbox.add(hbox)
          dialog.show_all
          dialog.run
          dialog.destroy
        end
        #@eventbox.window.cursor = $arrow
        false # this one is very important! stops the loop
        }
        $login.arrow
      end
    }


    hbox.pack_start(button1, true, false, 0)
    button2 = Gtk::Button.new($t['cancel'])
    button2.signal_connect("clicked") {
      kill $pid if $pid
      Gtk.main_quit
      false
    }
    hbox.pack_start(button2,true,false,0)

    super()
    self.set_window_position Gtk::Window::POS_CENTER
    self.title = "%s DinaIP" % $t['login']
    self.resizable = false
    self.border_width = 5
    self.add(@eventbox)
  end
  def arrow
    @eventbox.window.cursor = $arrow
  end
end

class List < Gtk::Window
  def initialize()
    # eventbox
    @eventbox = Gtk::EventBox.new
    ## menu ##
    menubar = Gtk::MenuBar.new
    # File
    file_menu = Gtk::Menu.new
    file_item = Gtk::MenuItem.new($t['file'])
    add_item = Gtk::MenuItem.new($t['add_domain'])
    edit_item = Gtk::MenuItem.new($t['edit_domain'])
    delete_item = Gtk::MenuItem.new($t['delete_domain'])
    edit_item.sensitive = false
    delete_item.sensitive = false
    save_conf = Gtk::MenuItem.new($t['save_conf'])
    load_conf = Gtk::MenuItem.new($t['load_conf'])
    connect_item = Gtk::MenuItem.new($t['connect'])
    exit_item = Gtk::MenuItem.new($t['exit'])
    file_menu.append(connect_item).append(Gtk::SeparatorMenuItem.new).append(add_item).append(edit_item).append(delete_item).append(Gtk::SeparatorMenuItem.new).append(save_conf).append(load_conf).append(Gtk::SeparatorMenuItem.new).append(exit_item)
    file_item.set_submenu(file_menu)
    # Tools
    tools_menu = Gtk::Menu.new
    tools_item = Gtk::MenuItem.new($t['tools'])

    resume_item = Gtk::MenuItem.new($t['resume_service'])
    stop_item = Gtk::MenuItem.new($t['stop_service'])
    options_item = Gtk::MenuItem.new($t['options'])
    tools_menu.append(resume_item).append(stop_item).append(Gtk::SeparatorMenuItem.new).append(options_item)
    tools_item.set_submenu(tools_menu)

    if $c['service'].nil?
      $c['service'] = true
      resume_item.sensitive = false
      save
    else
      if $c['service'] == true
        resume_item.sensitive = false
        stop_item.sensitive = true
      else
        resume_item.sensitive = true
        stop_item.sensitive = false
      end
    end
    resume_item.signal_connect("activate") { 
      resume_item.sensitive = false
      stop_item.sensitive = true
      $c['service'] = true 
      save
      cron
    }
    stop_item.signal_connect("activate") { 
      resume_item.sensitive = true
      stop_item.sensitive = false
      $c['service'] = false 
      save
      kill $pid
    }

    # Help
    help_menu = Gtk::Menu.new
    help_item = Gtk::MenuItem.new($t['help'])

    about_item = Gtk::MenuItem.new($t['about'])
    help_menu.append(about_item)
    help_item.set_submenu(help_menu)

    ## menu signals
    # file signals
    connect_item.signal_connect("activate") {
      $c['connect'] = false
      save
      $list.destroy
      $login = Login.new()
      $login.show_all
    }
    save_conf.signal_connect("activate") { 
      pwd_dlg = Password.new
    }
    load_conf.signal_connect("activate") { 
      dialog = Gtk::FileChooserDialog.new(
        $t['load_from_file'],
        nil,
        Gtk::FileChooser::ACTION_OPEN,
        nil,
        [ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
        [ Gtk::Stock::APPLY, Gtk::Dialog::RESPONSE_APPLY ]
      )
      dialog.run do |response|
        if response == Gtk::Dialog::RESPONSE_APPLY
          @file = dialog.filename
        end
      end
      dialog.destroy
      load_config(@file)
      save
      $list.destroy
      $list = List.new
      $list.show_all
    }
    exit_item.signal_connect("activate") { kill $pid if $pid; Gtk.main_quit; false }

    add_item.signal_connect("activate") {
      self.hide
      choose_domain = AddDomain.new
    }
      
    edit_item.signal_connect("activate") {
      begin
        @eventbox.window.cursor = $watch
        GLib::Idle.add {
          edit_zone
          @eventbox.window.cursor = $arrow
          false
        }
      rescue
      end
    }

    delete_item.signal_connect("activate") {
      edit_item.sensitive = false
      delete_item.sensitive = false
      path = Gtk::TreePath.new($selected['id'])
      iter = $treestore.get_iter(path)
      $treestore.remove(iter)
      $c["domains_#{$c['id']}"].delete($selected['domain'])
      $c.delete "zone_mx__#{$selected['domain']}"
      $c.delete "zone_file__#{$selected['domain']}"
      save
      $selected = {}
    }
    # tools signals
    options_item.signal_connect("activate") { 
      self.hide
      $options = Options.new()
    } 
    # help signal
    about_item.signal_connect("activate") { 
    ### about dialog ###
    about_dialog = Gtk::AboutDialog.new
    about_dialog.name = "DinaIP"
    about_dialog.version = $VERSION.to_s
    about_dialog.copyright = "(C) 2011 Dinahosting"
    about_dialog.run
    about_dialog.destroy
    }
    # gather the items in the menu
    menubar.append(file_item).append(tools_item).append(help_item)
    ## menu EOF ##

    vbox = Gtk::VBox.new
    vbox.add(menubar)
    hbox = Gtk::HBox.new
    connect = Gtk::ToolButton.new(Gtk::Stock::DISCONNECT)
    connect.signal_connect("clicked") do
      $c['connect'] = false
      save
      $list.hide
      $login = Login.new()
      $login.show_all
    end

    domain_add = Gtk::ToolButton.new(Gtk::Stock::ADD)
    domain_delete = Gtk::ToolButton.new(Gtk::Stock::DELETE)
    domain_delete.sensitive = false
    domain_add.signal_connect("clicked") do 
      self.hide
      choose_domain = AddDomain.new
    end

    separator = Gtk::SeparatorToolItem.new
    hbox.add(connect).add(separator).add(domain_add).add(domain_delete)
    $treestore = Gtk::TreeStore.new(String)
    treeview = Gtk::TreeView.new($treestore)
    treeview.set_size_request(200,300)
    renderer = Gtk::CellRendererText.new
    col = Gtk::TreeViewColumn.new($t['domains'], renderer, :text => 0)
    treeview.append_column(col)
    domain_delete.signal_connect("clicked") do
      path = Gtk::TreePath.new($selected['id'])
      iter = $treestore.get_iter(path)
      $treestore.remove(iter)
      $c["domains_#{$c['id']}"].delete($selected['domain'])
      $c.delete "zone_mx__#{$selected['domain']}"
      $c.delete "zone_file__#{$selected['domain']}"
      save
      domain_delete.sensitive = false
      delete_item.sensitive = false
      edit_item.sensitive = false
      $selected = {}
    end
    if $c.include? "domains_#{$c['id']}"
      $c["domains_#{$c['id']}"].each do |d|
        parent = $treestore.append(nil)
        parent[0] = d
      end
    end
    $selected = {}
    treeview.signal_connect("button_release_event") do |widget,event|
      if widget.selection.selected
        $selected['domain'] = widget.selection.selected[0]
        $selected['id'] = widget.selection.selected.to_s
        domain_delete.sensitive = true
        edit_item.sensitive = true
        delete_item.sensitive = true
      end
    end

    treeview.signal_connect("row-activated") do |view, path, column|
      if iter = view.model.get_iter(path)
        @eventbox.window.cursor = $watch
        GLib::Idle.add {
          $selected['domain'] = iter[0]
          $selected['id'] = iter.to_s
          edit_zone
          @eventbox.window.cursor = $arrow
          false
        }
      end
    end
    vbox.add(hbox)
    vbox.add(treeview)
    @eventbox.add(vbox)

    super()
    self.set_window_position Gtk::Window::POS_CENTER
    self.title = "DinaIP"
    self.resizable = false
    self.border_width = 5
    self.add(@eventbox)
  end
  def arrow
    @eventbox.window.cursor = $arrow
  end
end

class AddDomain < Gtk::Window
  def initialize()
    vbox = Gtk::VBox.new
    hbox = Gtk::HBox.new
    @eventbox = Gtk::EventBox.new
    @eventbox.add(vbox)

    @cb = Gtk::ComboBox.new()
    $res['domains'].each do |d|
      if $c["domains_#{$c['id']}"].nil?
        $c["domains_#{$c['id']}"] = []
      end
      if !$c["domains_#{$c['id']}"].include? d['dominio']
        @cb.append_text(d['dominio'])
      end
    end

    label = Gtk::Label.new($t['add_domain_msg'])
    cancel = Gtk::Button.new($t['cancel'])
    accept = Gtk::Button.new($t['accept'])
    hbox.add(cancel).add(accept)
    cancel.signal_connect("clicked") do
      self.hide
      $list.show_all
    end
    accept.signal_connect("clicked") do
      if @cb.active_text # domain selected?
        @eventbox.window.cursor = $watch
        GLib::Idle.add {
        parent = $treestore.append(nil)
        parent[0] = @cb.active_text
        $c["domains_#{$c['id']}"].push(@cb.active_text)
        $c["#{@cb.active_text}_autodetect_ip"] = $c['autodetect_ip']
        @cb.remove_text(@cb.active)
        save
        self.destroy
        $list.show_all
        false
        }
      end
    end
    vbox.add(label)
    vbox.add(@cb)
    vbox.add(hbox)

    super()
    self.set_window_position(Gtk::Window::POS_CENTER)
    self.title = "%s DinaIP" % $t['add_domain']
    self.resizable = false
    self.border_width = 15
    self.add(@eventbox)
    self.show_all
  end

  def arrow
    @eventbox.window.cursor = $arrow
  end
end

class Password < Gtk::Window
  def initialize
    @vbox = Gtk::VBox.new
    @label = Gtk::Label.new($t['password'])
    @pass = Gtk::Entry.new
    @pass.visibility = false
    @hbox = Gtk::HBox.new
    @ok = Gtk::Button.new($t['accept'])
    @ok.signal_connect("clicked") {
      if @pass.text == $c['pass']
        dialog = Gtk::FileChooserDialog.new(
          $t['save_file_as'],
          nil,
          Gtk::FileChooser::ACTION_SAVE,
          nil,
          [ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
          [ Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_APPLY ]
        )
        dialog.run do |response|
          if response == Gtk::Dialog::RESPONSE_APPLY
            file = dialog.filename
            # Open for writing, write and close.
            save(file)
          end
        end
        dialog.destroy
      else
        error_dialog($t['wrong_pass'])
      end
      self.destroy
    }
    @hbox.add(@pass).add(@ok)
    @vbox.add(@label).add(@hbox)

    super()
    self.set_window_position(Gtk::Window::POS_CENTER)
    self.title = "%s DinaIP" % $t['password']
    self.resizable = false
    self.border_width = 15
    self.add(@vbox)
    self.show_all
  end
end

########  Zone Window Class ##########
class Zone < Gtk::Window
  def initialize(domain, zone)
    @ip = get_current_ip
    @domain = domain
    @zone = zone

    # eventbox
    @eventbox = Gtk::EventBox.new

    # scrolled window
    @swin = Gtk::ScrolledWindow.new
    @swin.border_width = 10
    @swin.set_size_request(820, 400)
    @swin.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
    @viewport = Gtk::Viewport.new(@swin.hadjustment,@swin.vadjustment)
    @viewport.border_width = 10
    @vbox = Gtk::VBox.new(false,15)
    @table = Gtk::VBox.new(false,5)
    @swin.add_with_viewport(@table)
    @vbox.pack_start(@swin,false,false,0)
    
    @hbox_titles = Gtk::HBox.new(true,5)
    @host_label = Gtk::Label.new($t['host'])
    @type_label = Gtk::Label.new($t['type_label'])
    @addr_label = Gtk::Label.new($t['value'])
    @option_label = Gtk::Label.new($t['option'])
    @option_label2 = Gtk::Label.new($t['option'])
    @hbox_titles.pack_start(@host_label,true,false,0).pack_start(@type_label,true,false,0).pack_start(@addr_label,true,false,0).pack_start(@option_label,true,false,0).pack_start(@option_label2,true,false,0)
    @table.pack_start(@hbox_titles,false,false,0)

    load_config
    @rows, @host_e,@type_e,@addr_e,@dyn_cb,@del_b = [],[],[],[],[],[]

    #@zone_file = $c["zone_file__#{@domain}"]
    @zone_file = @zone
    @zone_file.map do |z|
      n = @zone_file.index(z)
      @rows[n] = Gtk::HBox.new(true,5)
      @host_e[n] = Gtk::Entry.new
      @type_e[n] = Gtk::ComboBox.new
      @addr_e[n] = Gtk::Entry.new
      @del_b[n] = Gtk::Button.new($t['delete'])

      for l in ["A", "AAAA", "CNAME", "FRAME", "URL", "URL_301", "TXT"]
        @type_e[n].append_text l
      end
      case z[:type]
      when "A"
        @type_e[n].set_active(0)
      when "AAAA"
        @type_e[n].set_active(1)
      when "cnam", "CNAME"
        @type_e[n].set_active(2)
      when "fram", "FRAME"
        @type_e[n].set_active(3)
      when "redi", "URL"
        @type_e[n].set_active(4)
      when "r301", "URL_301"
        @type_e[n].set_active(5)
      when "TXT"
        @type_e[n].set_active(6)
      else
        puts "ERR", z[:type]
        next # skip to next record if MX*
      end
      @host_e[n].text = z[:host]
      @addr_e[n].text = z[:addr]

      @dyn_cb[n] = Gtk::CheckButton.new($t['dynamic'])
      @dyn_cb[n].signal_connect("toggled") {
        if @dyn_cb[n].active?
          @addr_e[n].sensitive = false
        else
          @addr_e[n].sensitive = true
        end
      }
      if z[:type] == "A"
        if @zone_file[n][:addr] == @ip and $c['autodetect_ip'] == true
          @dyn_cb[n].set_active(true)
          @addr_e[n].sensitive = false
        end
        if @zone_file[n][:dynamic]
          @dyn_cb[n].set_active(true)
          @addr_e[n].sensitive = false
        end
      else
        @dyn_cb[n].sensitive = false
      end
      @type_e[n].signal_connect("changed") {
        if @type_e[n].active_text != "A"
          @dyn_cb[n].sensitive = false
          @dyn_cb[n].active = false
          @addr_e[n].sensitive = true
        else
          @dyn_cb[n].sensitive = true
        end
      }
      @addr_e[n].signal_connect("focus-in-event") {
        @addr_e[n].modify_base(Gtk::STATE_NORMAL, Gdk::Color.parse("#ffffff"))      
      }
      @host_e[n].signal_connect("focus-in-event") {
        @host_e[n].modify_base(Gtk::STATE_NORMAL, Gdk::Color.parse("#ffffff"))      
      }
      @del_b[n].signal_connect("clicked") {
        @rows[n].destroy
      }

      @rows[n].pack_start(@host_e[n],true,false,0).pack_start(@type_e[n],true,false,0).pack_start(@addr_e[n],true,false,0).pack_start(@dyn_cb[n],true,false,0).pack_start(@del_b[n],true,false,0)
      @table.pack_start(@rows[n],false,false,0)
    end

    # add record button
    @zone_num = @zone_file.count
    @add_record = Gtk::Button.new($t['add_new_zone'])
    @add_record.signal_connect("clicked") {
      n = @zone_num
      @rows[n] = Gtk::HBox.new(true,5)
      @host_e[n] = Gtk::Entry.new
      @type_e[n] = Gtk::ComboBox.new
      @addr_e[n] = Gtk::Entry.new
      @del_b[n] = Gtk::Button.new($t['delete'])
      @dyn_cb[n] = Gtk::CheckButton.new($t['dynamic'])

      @addr_e[n].signal_connect("focus-in-event") {
        @addr_e[n].modify_base(Gtk::STATE_NORMAL, Gdk::Color.parse("#ffffff"))      
      }
      @host_e[n].signal_connect("focus-in-event") {
        @host_e[n].modify_base(Gtk::STATE_NORMAL, Gdk::Color.parse("#ffffff"))      
      }
      @del_b[n].signal_connect("clicked") {
        @rows[n].destroy
      }
      @dyn_cb[n].signal_connect("toggled") {
        if @dyn_cb[n].active?
          @addr_e[n].sensitive = false
        else
          @addr_e[n].sensitive = true
        end
      }
      @type_e[n].signal_connect("changed") {
        if @type_e[n].active_text != "A"
          @dyn_cb[n].sensitive = false
          @dyn_cb[n].active = false
          @addr_e[n].sensitive = true
        else
          @dyn_cb[n].sensitive = true
        end
      }

      for l in ["A", "AAAA", "CNAME", "FRAME", "URL", "URL_301", "TXT"]
        @type_e[n].append_text l
      end
      @type_e[n].set_active(0)

      @rows[n].pack_start(@host_e[n],true,false,0).pack_start(@type_e[n],true,false,0).pack_start(@addr_e[n],true,false,0).pack_start(@dyn_cb[n],true,false,0).pack_start(@del_b[n],true,false,0)
      @table.pack_start(@rows[n],false,false,0)
      @table.show_all
      @swin.vadjustment.value = @swin.vadjustment.upper
      @zone_num +=1      
    }

    # add the hbox with autodect of domain + current ip
    hbox_bottom = Gtk::HBox.new(true, 50)

    @ip = get_current_ip
    @ip_label = Gtk::Label.new("#{$t['current_ip']}: #{@ip}")
    hbox_bottom.add(@ip_label)
    @vbox.add(hbox_bottom)

    # buttons
    hbox_buttons = Gtk::HBox.new(true,50)
    @cancel = Gtk::Button.new $t['cancel']
    @accept = Gtk::Button.new $t['accept']
    hbox_buttons.pack_start(@cancel,true,false,0).pack_start(@add_record,true,false,0).pack_start(@accept,true,false,0)
    @cancel.signal_connect("clicked") do
      self.destroy
      $list.show_all
    end
    @accept.signal_connect("clicked") do
      @eventbox.window.cursor = $watch
      GLib::Idle.add {
        @zone_file = []
        @error = false
        for x in 0..@zone_num
          if !@rows[x].nil?
            next if @rows[x].destroyed?
            if @host_e[x].text == ""
              @err_before = x
              @err = $t['ERROR_LACKS_HOST']
              @field = 'host'
            else
              @err_before = false
            end
            if @addr_e[x].text == ""
              @err_before = x
              @err = $t['ERROR_LACKS_ADDRESS']
              @field = 'value'
            else
              @err_before = false
            end
            if @dyn_cb[x].sensitive? and @dyn_cb[x].active?
              @addr_e[x].text = get_current_ip
              @zone_file << {:host => @host_e[x].text, :type => @type_e[x].active_text, :addr => @addr_e[x].text, :dynamic => @dyn_cb[x].active?}
            else
              @zone_file << {:host => @host_e[x].text, :type => @type_e[x].active_text, :addr => @addr_e[x].text, :dynamic => false}
            end
          end
        end
      if !@error
        @zone_mx = $c["zone_mx__#{@domain}"]
        res = save_zone(@domain, @zone_file, @zone_mx)
        @command_response = ""
        if res
          doc = REXML::Document.new(res)
          doc.elements.each('interface-response/CodeText') do |e|
            @command_response << e.text
          end
        end
        if @command_response == "Command completed successfully"
          $c["zone_file__#{@domain}"] = @zone_file
          save
          self.destroy
          $list.show_all
        else
          @error_msg = ""
          if res
            doc.elements.each('interface-response/errors/Err1') do |e|
              @error_msg << e.text
            end
          end
          @field = '' if !@err_before
          case @error_msg
          when "DOMINIO_INACTIVO"
            @err = $t['DOMINIO_INACTIVO']
          when "ERROR_DINAHOSTING_CANT_ANSWER"
            @err = $t['ERROR_DINAHOSTING_CANT_ANSWER']
          when /ERROR_LACKS_ADDRESS_(.*)/
            @err = $t['ERROR_LACKS_ADDRESS']
            @field = 'value'
          when /ERROR_LACKS_HOST_(.*)/
            @err = $t['ERROR_LACKS_HOST']
            @field = 'host'
          when /ERROR_LACKS_TYPE_(.*)/
            @err = $t['ERROR_LACKS_TYPE']
          when /ERROR_WRONG_CNAMESPECIAL_(.*)/
            @err = $t['ERROR_WRONG_CNAMESPECIAL']
            @field = 'host'
          when /ERROR_WRONG_FQDN_(.*)/
            @err = $t['ERROR_WRONG_FQDN']
            @field = 'host'
          when /ERROR_WRONG_HOST_(.*)/
            @err = $t['ERROR_WRONG_HOST']
            @field = 'host'
          when /ERROR_WRONG_IGUALES_(.*)/
            @err = $t['ERROR_WRONG_IGUALES']
            @field = 'host'
          when /ERROR_WRONG_IP_(.*)/
            @err = $t['ERROR_WRONG_IP']
            @field = 'value'
          when /ERROR_WRONG_NODEFINIDO_(.*)/
            @err = $t['ERROR_WRONG_NODEFINIDO']
          when /ERROR_WRONG_TYPE_(.*)/
            @err = $t['ERROR_WRONG_TYPE']
          when /ERROR_WRONG_URL_(.*)/
            @err = $t['ERROR_WRONG_URL']
            @field = 'value'
          when /REGISTRADOR_CAIDO/
            @err = $t['REGISTRADOR_CAIDO']
          when /WRONGIP_(.*)/
            @err = $t['WRONGIP']
            @field = 'value'
          when /WRONGMX_(.*)/
            @err = $t['WRONGMX']
            @field = 'host'
          when /WRONGRULE_(.*)/
            @err = $t['WRONGRULE']
          end

          if @err_before
            @err_zone = @err_before
          else
            @err_zone = Regexp.last_match(1)
            @err_zone = @err_zone.to_i
          end
          case @field
          when 'host'
            @host_e[@err_zone].modify_base(Gtk::STATE_NORMAL, Gdk::Color.parse("#FF0000")) if !@host_e[@err_zone].destroyed?
          when 'value'
            @addr_e[@err_zone].modify_base(Gtk::STATE_NORMAL, Gdk::Color.parse("#FF0000")) if !@addr_e[@err_zone].destroyed?
          end

          dialog = Gtk::Dialog.new(
            "Error",
            $list,
            Gtk::Dialog::MODAL,
            [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK]
          )
          label = Gtk::Label.new("#{$t['zone']} #{@err_zone + 1}: #{@err}")
          hbox = Gtk::HBox.new(false,10)
          hbox.border_width = 10
          hbox.pack_start_defaults(label)
          dialog.vbox.add(hbox)
          dialog.show_all
          dialog.run
          dialog.destroy 
        end
      end
      @eventbox.window.cursor = $arrow if !self.destroyed?
      false
      }
    end
    # add buttons to the bottom
    @vbox.pack_start(hbox_buttons,false,false,0)

    @eventbox.add(@vbox)

    super()
    self.set_window_position Gtk::Window::POS_CENTER
    self.title = "Zones DinaIP"
    self.resizable = false
    self.border_width = 5
    self.set_size_request(870, 500)
    self.add @eventbox
    self.show_all
  end
end
