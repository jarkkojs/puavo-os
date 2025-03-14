class image::bundle::desktop {
  include ::accountsservice
  include ::blueman
  include ::bluetooth
  include ::chromium
  include ::desktop
  include ::desktop_cups
  include ::disable_unclutter
  include ::exammode
  include ::exec_restrictions
  include ::firefox
  include ::fuse
  include ::gdm
  include ::gnome_terminal
  include ::graphics_drivers
  include ::homedir_management
  include ::ibus
  include ::image::bundle::basic
  include ::java
  include ::libdvdcss
  include ::network_manager
  include ::nextcloud
  include ::password_expiration
  include ::packages::languages::de
  include ::packages::languages::en
  include ::packages::languages::fi
  include ::packages::languages::fr
  include ::packages::languages::sv
  include ::packages::languages::uk
  include ::picaxe_udev_rules
  include ::polkit_printers
  include ::progressive_web_applications::apps
  include ::puavo_pkg::packages
  include ::run_once_on_desktop_session
  include ::scribus
  include ::supplementary_groups
  include ::tts_setup
  include ::tuxpaint
  include ::udisks2
  include ::veyon
  include ::vym
  include ::wine
  include ::xorg

  Package <| tag == 'tag_debian_desktop'
          or tag == 'tag_debian_desktop_backports' |>
}
