class packages::backports {
  # This list is used by apt::backports so that these packages will be picked
  # up from backports instead of the usual channels.  The inclusion of a
  # package on this list does not trigger the installation of a package,
  # that has to be defined elsewhere.

  $package_list = [ 'broadcom-sta-dkms'
                  , 'r8168-dkms' ]
}
