class image::bundle::basic {
  include ::avahi_daemon
  include ::console
  include ::disable_drrs_conditionally
  include ::disable_hp_accel_module
  include ::disable_update_initramfs
  include ::extra_boot_scripts
  include ::gdm
  include ::grub
  include ::handle_utmp_logs
  include ::hwquirks
  include ::initramfs
  include ::infotv
  include ::kernels
  # include ::keyboard_hw_quirks        # XXX do we need this for Debian?
  include ::locales
  include ::motd
  include ::nightly_updates
  include ::nss
  include ::packages
  include ::pam
  include ::plymouth
  include ::puavo_external_files
  include ::puavo_shutdown
  include ::puavomenu
  include ::rpcgssd
  include ::ssh_client
  include ::sysctl
  include ::syslog
  include ::systemd
  include ::tmux
  include ::udev
  include ::use_urandom
  include ::wlanap
  include ::woeusb
  include ::zram_configuration

  Package <| title == ltsp-client
          or title == puavo-ltsp-client
          or title == puavo-ltsp-install |>
}
