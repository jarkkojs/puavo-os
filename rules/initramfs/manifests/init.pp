class initramfs {
  include ::packages

  exec {
    'update initramfs':
      command     => '/usr/sbin/update-initramfs -k all -u',
      refreshonly => true,
      require     => File['/etc/initramfs-tools/initramfs.conf'];
  }

  file {
    '/etc/initramfs-tools/initramfs.conf':
      require => Package['initramfs-tools'],
      source  => 'puppet:///modules/initramfs/initramfs.conf';

    '/etc/initramfs-tools/modules':
      require => Package['initramfs-tools'],
      source  => 'puppet:///modules/initramfs/etc_initramfs-tools_modules';
  }

  Package <| title == initramfs-tools |>
}
