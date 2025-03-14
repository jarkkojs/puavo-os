class puavo_pkg::packages {
  include ::puavo_conf
  include ::puavo_pkg

  # list removed puavo-pkg packages here
  ::puavo_conf::definition {
    'puavo-pkg-removed.json':
      source => 'puppet:///modules/puavo_pkg/puavo-pkg-removed.json';
  }

  # List some of the available puavo-pkg packages that we want to
  # install by default.  There may be other puavo-pkg packages available.
  $available_packages = [ 'abicus'
			, 'abitti-naksu'
			, 'appinventor'
			, 'arduino-ide'
			, 'arduino-ottodiylib'
			, 'arduino-radiohead'
			, 'arduino-tm1637'
			, 'bluegriffon'
			, 'cmaptools'
			, 'cnijfilter2'
			, 'drawio-desktop'
			, 'dropbox'
			, 'ekapeli-alku'
			, 'extra-xkb-symbols'
			, 'filius'
			, 'firefox'
			, 'flashforge-flashprint'
			, 'geogebra'
			, 'geogebra6'
			, 'google-chrome'
			, 'google-earth'
			, 'idid'
			, 'kojo'
			, 'marvinsketch'
			, 'musescore-appimage'
			, 'msttcorefonts'
			, 'nextcloud-desktop'
			, 'novoconnect'
                        , 'obsidian-icons'
			, 'ohjelmointi-opetuksessa'
			, 'puavo-firmware'
			, 'rustdesk'
			, 'schoolstore-ti-widgets'
			, 'scratux'
			, 'skype'
			, 'spotify-client'
			, 'tela-icon-theme'
			, 'tilitin'
			, 't-lasku'
			, 'tmux-plugins-battery'
			, 'ubuntu-trusty-libs'
			, 'ubuntu-wallpapers-bullseye'
			, 'veracrypt'
                        , 'wine-gecko'
                        , 'wine-mono'
                        , 'xournalpp' ]

  @puavo_pkg::install { $available_packages: ; }

  # "arduino-ottodiylib", "arduino-tm1637", "arduino-radiohead" and
  # "ohjelmointi-opetuksessa" require "arduino-ide" to be installed first.
  Puavo_pkg::Install['arduino-ide'] {
    before +> [ Puavo_pkg::Install['arduino-ottodiylib']
              , Puavo_pkg::Install['arduino-radiohead']
              , Puavo_pkg::Install['arduino-tm1637']
              , Puavo_pkg::Install['ohjelmointi-opetuksessa'] ],
  }
}
