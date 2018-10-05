class syslog {
  include ::packages

  file {
    '/etc/logrotate.d/martians':
      require => Package['logrotate'],
      source  => 'puppet:///modules/syslog/etc_logrotate.d_martians';

    '/etc/logrotate.d/puavo-rest':
      require => Package['logrotate'],
      source  => 'puppet:///modules/syslog/etc_logrotate.d_puavo-rest';

    '/usr/local/lib/puavo-caching-syslog-sender':
      mode    => '0755',
      require => File['/var/log/puavo'],
      source  => 'puppet:///modules/syslog/puavo-caching-syslog-sender';

    '/var/log/puavo':
      mode   => '0640',
      ensure => directory;
  }

  Package <| title == logrotate
          or title == rsyslog |>
}
