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
  include ::locales
  include ::motd
  include ::nightly_updates
  include ::nss
  include ::packages
  include ::pam
  include ::plymouth
  include ::puavo_bash_completions
  include ::puavo_external_files
  include ::puavomenu
  include ::puavo_shutdown
  include ::rpcgssd
  include ::ssh_client
  include ::ssh_server
  include ::sysctl
  include ::syslog
  include ::systemd
  include ::tlp
  include ::tmux
  include ::udev
  include ::users
  include ::use_urandom
  include ::woeusb
  include ::zram_configuration

  Package <| title == ltsp-client
          or title == puavo-ltsp-client
          or title == puavo-ltsp-install |>
}
