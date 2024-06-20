class desktop_cups {
  include ::puavo_conf

  file {
    '/etc/cups/cupsd.conf':
      source => 'puppet:///modules/desktop_cups/etc_cups_cupsd.conf';

    '/usr/local/bin/puavo-show-printer-restrictions':
      mode    => '0755',
      require => ::Puavo_conf::Script['setup_desktop_printer_restrictions'],
      source  => 'puppet:///modules/desktop_cups/puavo-show-printer-restrictions';
  }

  ::puavo_conf::script {
    'fix_cups_certs':
      source => 'puppet:///modules/desktop_cups/fix_cups_certs';

    'setup_cups_browsed':
      source => 'puppet:///modules/desktop_cups/setup_cups_browsed';

    'setup_desktop_printer_restrictions':
      source => 'puppet:///modules/desktop_cups/setup_desktop_printer_restrictions';
  }
}
