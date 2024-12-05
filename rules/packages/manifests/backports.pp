class packages::backports {
  # This list is used by apt::backports so that these packages will be picked
  # up from backports instead of the usual channels.  The inclusion of a
  # package on this list does not trigger the installation of a package,
  # that has to be defined elsewhere.

  $package_list = [
    'kernel-wedge'      # needed by bpo kernel build

    # firmware packages
    , 'firmware-iwlwifi'        # needed by crisp kernel (from 6.11 onwards)

    # Libreoffice from backports
    , 'fonts-opensymbol'
    , 'liblibreoffice-java'
    , 'libreoffice'
    , 'libreoffice-base'
    , 'libreoffice-base-core'
    , 'libreoffice-base-drivers'
    , 'libreoffice-calc'
    , 'libreoffice-common'
    , 'libreoffice-core'
    , 'libreoffice-draw'
    , 'libreoffice-gnome'
    , 'libreoffice-gtk3'
    , 'libreoffice-help-common'
    , 'libreoffice-help-de'
    , 'libreoffice-help-en-gb'
    , 'libreoffice-help-fi'
    , 'libreoffice-help-fr'
    , 'libreoffice-help-sv'
    , 'libreoffice-impress'
    , 'libreoffice-java-common'
    , 'libreoffice-l10n-de'
    , 'libreoffice-l10n-en-gb'
    , 'libreoffice-l10n-en-za'
    , 'libreoffice-l10n-fi'
    , 'libreoffice-l10n-fr'
    , 'libreoffice-l10n-sv'
    , 'libreoffice-l10n-uk'
    , 'libreoffice-librelogo'
    , 'libreoffice-math'
    , 'libreoffice-nlpsolver'
    , 'libreoffice-report-builder'
    , 'libreoffice-report-builder-bin'
    , 'libreoffice-script-provider-bsh'
    , 'libreoffice-script-provider-js'
    , 'libreoffice-script-provider-python'
    , 'libreoffice-sdbc-firebird'
    , 'libreoffice-sdbc-hsqldb'
    , 'libreoffice-sdbc-mysql'
    , 'libreoffice-sdbc-postgresql'
    , 'libreoffice-style-colibre'
    , 'libreoffice-style-elementary'
    , 'libreoffice-wiki-publisher'
    , 'libreoffice-writer'
    , 'libuno-cppu3'
    , 'libuno-cppuhelpergcc3-3'
    , 'libunoloader-java'
    , 'libuno-purpenvhelpergcc3-3'
    , 'libuno-sal3'
    , 'libuno-salhelpergcc3-3'
    , 'python3-uno'
    , 'uno-libs-private'
    , 'ure'
    , 'ure-java'
  ]
}
