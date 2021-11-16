class kernels {
  include ::kernels::dkms
  include ::kernels::grub_update
  require ::packages

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

  $default_kernel = '4.9.0-16-amd64'
  $fresh_kernel   = '4.19.0-0.bpo.18-amd64'
  $legacy_kernel  = '3.16.0-6-amd64'

  ::kernels::all_kernel_links {
    'default': kernel => $default_kernel;
    'fresh':   kernel => $fresh_kernel;
    'legacy':  kernel => $legacy_kernel;
  }
}
