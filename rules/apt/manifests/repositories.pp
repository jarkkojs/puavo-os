class apt::repositories {
  include ::apt

  $other_releases = $debianversioncodename ? {
                      'buster' => {},
                      default  => {
                        'jessie' => 80,
                        'buster' => 60,
                      }
                    }

  define setup ($fasttrackmirror,
                $fasttrackmirror_path='',
                $localmirror='',
                $mirror,
                $mirror_path='',
                $securitymirror,
                $securitymirror_path='') {
    $::apt::repositories::other_releases.each |String $distrib_version,
                                               Integer $pin_priority| {
      ::apt::debian_repository {
        $distrib_version:
          fasttrackmirror      => $fasttrackmirror,
          fasttrackmirror_path => $fasttrackmirror_path,
          localmirror          => $localmirror,
          mirror               => $mirror,
          mirror_path          => $mirror_path,
          pin_priority         => $pin_priority,
          securitymirror       => $securitymirror,
          securitymirror_path  => $securitymirror_path;
      }
    }

    file {
      '/etc/apt/preferences.d/00-puavo.pref':
        content => template('apt/00-puavo.pref'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list':
        content => template('apt/sources.list'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list.d/debian-fasttrack.list':
        content => template('apt/debian-fasttrack.list'),
        require => [ Exec['apt update']
                   , File['/etc/apt/sources.list'] ];

      # Put the local this into a separate file so it can be excluded
      # in the image build along with the actual archive.
      '/etc/apt/sources.list.d/puavo-os-local.list':
        content => template('apt/puavo-os-local.list'),
        notify  => Exec['apt update'];

      '/etc/apt/sources.list.d/puavo-os-remote.list':
        content => template('apt/puavo-os-remote.list'),
        notify  => Exec['apt update'];

      '/etc/apt/trusted.gpg.d/opinsys.gpg':
        before => Exec['apt update'],
        source => 'puppet:///modules/apt/opinsys.gpg';
    }
  }
}
