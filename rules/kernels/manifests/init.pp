class kernels {
  include ::kernels::dkms
  include ::kernels::grub_update
  include ::packages

  define kernel_link ($kernel, $linkname, $linksuffix) {
    file {
      "/boot/${linkname}${linksuffix}":
        ensure  => link,
        require => Packages::Kernels::Kernel_package[$kernel],
        target  => "${linkname}-${kernel}";
    }

    Packages::Kernels::Kernel_package <| title == $kernel |>
  }

  define all_kernel_links ($kernel='') {
    $subname = $title

    $linksuffix = $subname ? { 'default' => '', default => "-$subname", }

    ::kernels::kernel_link {
      "initrd.img-${kernel}-${subname}":
        kernel => $kernel, linkname => 'initrd.img', linksuffix => $linksuffix;

      "vmlinuz-${kernel}-${subname}":
        kernel => $kernel, linkname => 'vmlinuz', linksuffix => $linksuffix;
    }
  }

  $default_kernel = '6.1.0-3-amd64'
  # XXX $recent_kernel  = '6.0.0-0.deb11.6-amd64'

  ::kernels::all_kernel_links {
    'default': kernel => $default_kernel;
    # XXX 'recent':  kernel => $recent_kernel;
  }
}
