class packages::compat_32bit {
  include ::packages

  # i386-support packages for the amd64-architecture.
  # There are explicit or found-by-trial -dependencies of the following
  # software packages: adobereader-enu, skype, smartboard.
  if $architecture == 'amd64' {
    @package {
      [ 'gstreamer1.0-gl:i386'         # needed for better media support in wine
      , 'gstreamer1.0-vaapi:i386'      # needed for better media support in wine
      , 'libasound2:i386'
      , 'libasound2-plugins:i386'
      , 'libatk1.0-0:i386'
      , 'libatkmm-1.6-1v5:i386'
      , 'libbluetooth3:i386'
      , 'libc6:i386'
      , 'libcairo2:i386'
      , 'libcanberra-gtk-module:i386'
      , 'libcap-ng0:i386'
      , 'libcurl4:i386'
      , 'libdbus-1-3:i386'
      , 'libdbus-glib-1-2:i386'
      , 'libfakekey0:i386'
      , 'libfontconfig1:i386'
      , 'libfreetype6:i386'
      , 'libgcc-s1:i386'
      , 'libgif7:i386'                  # needed by RobboScratch2
      , 'libglib2.0-0:i386'
      , 'libgraphene-1.0-0:i386'             # needed for better media support in wine
      , 'libgstreamer-gl1.0-0:i386'          # needed for better media support in wine
      , 'libgstreamer-plugins-bad1.0-0:i386' # needed for better media support in wine
      , 'libgtk2.0-0:i386'
      , 'libice6:i386'
      # XXX buster , 'libjpeg9:i386'
      , 'libltdl7:i386'
      , 'libmp3lame0:i386'
      # XXX buster , 'libnspr4-0d:i386'
      , 'libnspr4:i386'
      , 'libnss3:i386'                  # needed by RobboScratch2
      , 'libpango1.0-0:i386'
      , 'libpangomm-1.4-1v5:i386'
      # XXX buster , 'libpng12-0:i386'               # needed by GlobiLab
      , 'libpulse0:i386'
      # , 'libqt4-dbus:i386'            # XXX missing from Bullseye
      # , 'libqt4-network:i386'
      # , 'libqt4-xml:i386'
      # , 'libqtcore4:i386'
      # , 'libqtgui4:i386'
      # , 'libqtwebkit4:i386'
      , 'libselinux1:i386'
      , 'libsm6:i386'
      , 'libssl3:i386'
      , 'libstdc++6:i386'
      , 'libudev1:i386'
      , 'libusb-1.0-0:i386'
      , 'libuuid1:i386'
      , 'libva-wayland2:i386'           # needed for better media support in wine
      , 'libvkd3d-shader1:i386'
      , 'libx11-6:i386'
      , 'libxext6:i386'
      , 'libxinerama1:i386'
      , 'libxkbfile1:i386'
      , 'libxml2:i386'
      , 'libxrender1:i386'
      , 'libxslt1.1:i386'
      , 'libxss1:i386'
      , 'libxtst6:i386'
      , 'libxv1:i386'
      , 'vkd3d-compiler:i386'
      , 'wine-devel-i386:i386'
      , 'zlib1g:i386' ]:
        ensure => present,
        tag    => [ 'tag_debian_desktop', 'tag_i386' ];
    }

    # XXX libnss-extrausers:i386 can not live with libnss-extrausers:amd64,
    # XXX the package multiarch-support should be updated.  But this hack
    # XXX does the trick:
    file {
      '/usr/lib/i386-linux-gnu/libnss_extrausers.so.2':
        ensure  => link,
        require => Package['libnss-extrausers'],
        target  => '/usr/lib32/libnss_extrausers.so.2';

      '/usr/lib/x86_64-linux-gnu/libnss_extrausers.so.2':
        ensure  => link,
        require => Package['libnss-extrausers'],
        target  => '/usr/lib/libnss_extrausers.so.2';
    }

    # XXX In case there is still something needing libudev0...
    # XXX we hope that libudev1 fits the bill.
    # XXX Remove later once it is more clear this is no longer
    # XXX needed.
    file {
      '/lib/i386-linux-gnu/libudev.so.0':
        ensure  => link,
        require => Package['libudev1:i386'],
        target  => 'libudev.so.1';

      '/lib/x86_64-linux-gnu/libudev.so.0':
        ensure  => link,
        require => Package['libudev1'],
        target  => 'libudev.so.1';
    }

    Package <|
         title == libnss-extrausers
      or title == libudev1
      or title == "libudev1:i386"
    |>
  }
}
