class gdm {
  include ::art
  include ::dconf::schemas
  include ::dpkg
  include ::guest
  include ::packages
  include ::puavo_pkg::packages
  include ::puavo_conf

  ::dpkg::simpledivert {
    '/usr/share/glib-2.0/schemas/org.gnome.login-screen.gschema.xml':
      require => Package['gdm3'];
  }

  exec {
    '/usr/sbin/dpkg-reconfigure gdm3':
      refreshonly => true,
      require     => Dpkg::Simpledivert['/usr/share/glib-2.0/schemas/org.gnome.login-screen.gschema.xml'];
  }

  file {
    '/etc/gdm3/background.img':
      ensure  => link,
      replace => false, # just initial setup, see setup_loginscreen_background
      require => [ Package['gdm3']
                 , Puavo_pkg::Install['ubuntu-wallpapers-bullseye'], ],
      target  => '/usr/share/backgrounds/Grass_by_Jeremy_Hill.jpg';

    '/etc/gdm3/daemon.conf':
      notify  => Exec['/usr/sbin/dpkg-reconfigure gdm3'],
      require => Package['gdm3'],
      source  => 'puppet:///modules/gdm/daemon.conf';

    '/etc/gdm3/PostLogin/Default':
      mode    => '0755',
      require => [ File['/etc/guest-session'], Package['gdm3'], ],
      source  => 'puppet:///modules/gdm/PostLogin_Default';

    '/etc/gdm3/PostSession/Default':
      mode    => '0755',
      require => [ File['/etc/guest-session'], Package['gdm3'], ],
      source  => 'puppet:///modules/gdm/PostSession_Default';

    '/usr/share/gdm/greeter/autostart/start-puavo-desktop-applet.desktop':
      ensure  => link,
      require => [ Package['gdm3'], Package['puavo-desktop-applet'], ],
      target  => '/etc/xdg/autostart/start-puavo-desktop-applet.desktop';
  }

  ::dconf::schemas::schema {
    'org.gnome.login-screen.gschema.xml':
      require => Dpkg::Simpledivert['/usr/share/glib-2.0/schemas/org.gnome.login-screen.gschema.xml'],
      srcfile => 'puppet:///modules/gdm/org.gnome.login-screen.gschema.xml';
  }

  ::puavo_conf::script {
    'setup_gdm':
      require => ::Puavo_conf::Definition['puavo-art.json'],
      source  => 'puppet:///modules/gdm/setup_gdm';

    'setup_loginscreen_background':
      require => ::Puavo_conf::Definition['puavo-art.json'],
      source  => 'puppet:///modules/gdm/setup_loginscreen_background';

    'setup_xsessions':
      require => Package['puavo-ltsp-client'],
      source  => 'puppet:///modules/gdm/setup_xsessions';
  }

  user {
    # We add Debian-gdm to puavodesktop group so that
    # /usr/lib/puavo-ltsp-client/admin-remote-connections can work also in
    # the login screen.
    'Debian-gdm':
      groups     => [ 'puavodesktop' ],
      membership => minimum,
      require    => [ Package['gdm3'], Package['puavo-ltsp-client'], ];
  }

  Package <|
       title == gdm3
    or title == puavo-ltsp-client
  |>

  Puavo_pkg::Install <| title == 'ubuntu-wallpapers-bullseye' |>
}
