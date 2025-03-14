#!/usr/bin/rake -f

require 'fileutils'
require 'json'

Image_dir        = ENV['image_dir']
Images_json_path = ENV['images_json_path']
Images_urlbase   = ENV['images_urlbase']
Mirror_dir       = ENV['mirror_dir']
Mode             = ENV['mode']

raise '"image_dir" environment variable not defined' \
  if Image_dir.nil? || Image_dir.empty?

raise '"images_urlbase" environment variable not defined' \
  if Images_urlbase.nil? || Images_urlbase.empty?

raise '"mirror_dir" environment variable not defined' \
  if Mirror_dir.nil? || Mirror_dir.empty?

Checksums_dir  = "#{ Mirror_dir }/.checksums"
Metadata_dir   = "#{ Mirror_dir }/meta"
Rdiffs_dir     = "#{ Mirror_dir }/rdiffs"
Signatures_dir = "#{ Mirror_dir }/.signatures"

Cksums_file = "#{ Mirror_dir }/CKSUMS"

directory Checksums_dir
directory Metadata_dir
directory Rdiffs_dir
directory Signatures_dir

$all_cksum_files = []

def calc_checksum(cmd, source_file_path, output_path)
  basename = File.basename(source_file_path)
  dirname  = File.dirname(source_file_path)

  tmpfile = "#{ output_path }.tmp"

  pid = spawn(cmd, basename, :chdir => dirname, :out => tmpfile)
  Process.wait(pid)
  raise "Error running command #{ cmd } #{ source_file_path }" \
    unless $?.exitstatus == 0

  mv tmpfile, output_path
end

def find_rdiff_file(source_image, target_image)
  image_regexp = /^(.*?)-(\d{4}-\d{2}-\d{2}-\d{6})-(.*?).img$/

  source_match = source_image.match(image_regexp)
  raise "Bad image format '#{ source_image }'" unless source_match

  target_match = target_image.match(image_regexp)
  raise "Bad image format '#{ target_image }'" unless target_match

  return sprintf('%s-%s--%s-%s.rdiff',
		 source_match[1],
		 source_match[2],
		 target_match[2],
		 source_match[3])
end

def generate_development_image_series()
  image_series = {}

  image_paths = Dir.glob("#{ Image_dir }/*.img").map { |p| File.basename(p) }
  image_paths.each do |path|
    m = path.match(/\A(.*?)-\d/)
    if m then
      series_name = "#{ m[1] }-devel"
      image_series['images'] ||= []
      (image_series['images'][ series_name ] ||= []) << path
    end
  end
  image_series.each do |series_name, series_spec|
    # take only the latest four images after sorting each series
    image_series['images'][series_name] = series_spec['images'].sort.last(4)
  end

  image_series
end

def get_cksum_path(filename)
  "#{ Checksums_dir }/#{ filename }.cksum"
end

def get_sha256sum_path(filename)
  "#{ Checksums_dir }/#{ filename }.sha256sum"
end

def get_sha512sum_path(filename)
  "#{ Checksums_dir }/#{ filename }.sha512sum"
end

def get_image_version(image_name)
  return get_version(image_name, /-(\d+)-(\d+)-(\d+)-(\d+).*\.img\z/)
end

def get_rdiff_version(rdiff_file)
  return get_version(rdiff_file, /-(\d+)-(\d+)-(\d+)-(\d+)--.*\.rdiff\z/)
end

def get_version(name, version_re)
  versionmatch = name.match(version_re)
  raise "Could not determine version for #{ name }" unless versionmatch
  return versionmatch[1..4].join
end

def make_metadata_file(series_name, series_metadata, series_metadata_file)
  series_metadata['images'].each do |image_metadata|
    imagename = image_metadata['filename']
    image_metadata['cksum'] = read_cksum(imagename)
    image_metadata['sha256'] = read_sha256sum(imagename)
    image_metadata['sha512'] = read_sha512sum(imagename)

    image_metadata['diffs'].each do |rdiff_metadata|
      rdiff_file = rdiff_metadata['filename']
      rdiff_metadata['size'] = File.size("#{ Rdiffs_dir }/#{ rdiff_file }")
      rdiff_metadata['cksum'] = read_cksum(rdiff_file)
      rdiff_metadata['sha256'] = read_sha256sum(rdiff_file)
      rdiff_metadata['sha512'] = read_sha512sum(rdiff_file)
    end
  end

  series_metadata_by_series_name = { series_name => series_metadata }

  tmpfile = "#{ series_metadata_file }.tmp"
  File.open(tmpfile, 'w') do |f|
    f.write(series_metadata_by_series_name.to_json)
  end
  mv tmpfile, series_metadata_file
end

def parse_image_series(json_path)
  image_series = JSON.parse( File.read(json_path) )

  raise 'expecting hash' unless image_series.kind_of?(Hash)
  image_series.each do |key, value|
    raise 'expecting string as key' unless key.kind_of?(String)
    raise 'expecting hash as value' unless value.kind_of?(Hash)
    raise 'expecting images key in a hash' unless value['images'].kind_of?(Array)
    value['images'].each do |image|
      raise 'expecting string as an image value' unless image.kind_of?(String)
    end
  end

  return image_series
end

def read_checksum_from_file(path)
  data = IO.read(path)
  checksum = (data.split)[0]
  raise "Could not read checksum from file '#{ path }'" \
    if checksum.nil? || checksum.empty?
  return checksum
end

def read_cksum(filename)
  read_checksum_from_file( get_cksum_path(filename) )
end

def read_sha256sum(filename)
  read_checksum_from_file( get_sha256sum_path(filename) )
end

def read_sha512sum(filename)
  read_checksum_from_file( get_sha512sum_path(filename) )
end

def setup_checksum_tasks(filename, absolute_source_path)
  cksum_file = get_cksum_path(filename)
  $all_cksum_files << cksum_file

  file cksum_file => [ Checksums_dir, absolute_source_path ]
  file cksum_file do |t|
    calc_checksum('cksum', absolute_source_path, t.name)
  end

  sha256sum_file = get_sha256sum_path(filename)
  sha512sum_file = get_sha512sum_path(filename)

  file sha256sum_file => [ Checksums_dir, absolute_source_path ]
  file sha256sum_file do |t|
    calc_checksum('sha256sum', absolute_source_path, t.name)
  end

  file sha512sum_file => [ Checksums_dir, absolute_source_path ]
  file sha512sum_file do |t|
    calc_checksum('sha512sum', absolute_source_path, t.name)
  end

  return [ cksum_file, sha256sum_file, sha512sum_file ]
end

def get_puavo_conf_defaults(target_image_file_fp)
  definitions_path = '/usr/share/puavo-conf/definitions'
  mnt_done         = false
  mnt_path         = '/mnt'

  puavo_conf = {}

  begin
    system('umount', mnt_path, :err => File::NULL)
    system('mount', target_image_file_fp, mnt_path,
           :out => File::NULL, :err => File::NULL) \
      or raise "could not mount #{ target_image_file_fp } to #{ mnt_path }"
    mnt_done = true

    Dir.glob("#{ mnt_path }#{ definitions_path }/*.json").each do |json_path|
      new_values = JSON.parse( File.read(json_path) )
      raise "JSON in #{ json_path } is not in a hash format" \
        unless new_values.kind_of?(Hash)

      new_values.each do |key, value|
        raise "Duplicate definition of '#{ key }' in '#{ json_path }'" \
          if puavo_conf.has_key?(key)
        puavo_conf[key] = value
      end
    end
  ensure
    if mnt_done then
      system('umount', mnt_path) \
        or raise "could not unmount #{ mnt_path }"
    end
  end

  return puavo_conf
end

def setup_rdiff_tasks(source_image_file, target_image_file, metadata_file)
  source_image_file_fp = "#{ Image_dir }/#{ source_image_file }"

  rdiff_file = find_rdiff_file(source_image_file, target_image_file)
  rdiff_file_fp = "#{ Rdiffs_dir }/#{ rdiff_file }"

  source_image_signature_file = "#{ source_image_file }.rdiff_signature"
  source_image_signature_file_fp =
      "#{ Signatures_dir }/#{ source_image_signature_file }"

  unless Rake::Task::task_defined?(source_image_signature_file_fp) then
    file source_image_signature_file_fp => Signatures_dir
    file source_image_signature_file_fp => source_image_file_fp do |t|
      tmpfile = "#{ source_image_signature_file_fp }.tmp"
      FileUtils.rm_f(tmpfile)
      sh 'rdiff', '--block-size=128', 'signature', source_image_file_fp, tmpfile
      mv tmpfile, t.name
    end
  end

  target_image_file_fp = "#{ Image_dir }/#{ target_image_file }"

  task rdiff_file => rdiff_file_fp

  unless Rake::Task::task_defined?(rdiff_file_fp) then
    file rdiff_file_fp => [ Rdiffs_dir,
                            source_image_signature_file_fp,
                            target_image_file_fp ]
    file rdiff_file_fp do |t|
      tmpfile = "#{ rdiff_file_fp }.tmp"
      FileUtils.rm_f(tmpfile)
      sh 'rdiff', '--block-size=128', 'delta', source_image_signature_file_fp,
        target_image_file_fp, tmpfile
      mv tmpfile, t.name
    end
  end

  checksum_files = setup_checksum_tasks(rdiff_file, rdiff_file_fp)

  file metadata_file => [ rdiff_file_fp ] + checksum_files

  return {
    'filename' => rdiff_file,
    'urls'     => [ "#{ Images_urlbase }/rdiffs/#{ rdiff_file }" ],
    'version'  => get_rdiff_version(rdiff_file),
   }
end

#
# main
#

case Mode
  when 'development'
    image_series = generate_development_image_series()
  when 'production'
    begin
      image_series = parse_image_series(Images_json_path)
    rescue StandardError => err
      warn "Error in parsing #{ Images_json_path }: #{ err.message }"
      exit 1
    end
  else
    raise "Unknown mode: #{ mode }"
end

#
# tasks
#

task :default => [ Cksums_file, :all_series ]

file Cksums_file

task :all_series

image_series.each do |series_name, series_spec|
  task series_name
  task :all_series => series_name

  series_metadata = { 'images' => [] }

  series_metadata_file = "#{ Metadata_dir }/#{ series_name }.json"
  task series_name => series_metadata_file

  file series_metadata_file => Metadata_dir

  target_image_rdiff_target = nil

  extra_rdiffs = series_spec['extra_rdiffs'] || {}
  image_list   = series_spec['images']

  image_list.each_index do |i|
    target_image_file = image_list[i]
    target_image_rdiff_target = "#{ target_image_file }-rdiffs"

    target_image_file_copy = "#{ Mirror_dir }/#{ target_image_file }"
    target_image_file_fp   = "#{ Image_dir }/#{ target_image_file }"

    task target_image_rdiff_target
    task series_name => target_image_rdiff_target
    task series_name => target_image_file_copy
    task series_name => Cksums_file

    file target_image_file_copy => target_image_file_fp do |t|
      # This presumes that source and target are in the same filesystem.
      # If this is not the case, fix your configuration.
      ln target_image_file_fp, t.name
    end

    puavo_conf = nil
    begin
      puavo_conf = get_puavo_conf_defaults(target_image_file_fp)
    rescue StandardError => e
      warn ">>> did not get puavo-conf for #{ target_image_file_fp }: " \
              + e.message
      exit(1)
    end
    image_metadata = {
      'diffs'      => [],
      'filename'   => target_image_file,
      'id'         => File.basename(target_image_file, '.img'),
      'puavo-conf' => puavo_conf,
      'size'       => File.size(target_image_file_fp),
      'urls'       => [ "#{ Images_urlbase }/#{ target_image_file }" ],
      'version'    => get_image_version(target_image_file),
     }

    checksum_files = setup_checksum_tasks(target_image_file,
      target_image_file_copy)

    file series_metadata_file => [ target_image_file_copy ] + checksum_files

    rdiff_source_files = []

    # make rdiffs only to the last three images in image list
    # (perhaps make this adjustable with a command line option in case
    # anyone wants to build the whole set?)
    if i >= (image_list.count - 3) then
      image_list.each_index do |j|
        source_image_file = image_list[j]
        next if source_image_file == target_image_file
        rdiff_source_files << source_image_file
      end
    end

    if extra_rdiffs[target_image_file] then
      rdiff_source_files += extra_rdiffs[target_image_file]
    end

    rdiff_source_files.uniq.each do |source_image_file|
      rdiff_metadata = setup_rdiff_tasks(source_image_file, target_image_file,
                         series_metadata_file)
      task target_image_rdiff_target = rdiff_metadata['filename']
      image_metadata['diffs'] << rdiff_metadata
    end

    series_metadata['images'] << image_metadata
  end

  file series_metadata_file do |t|
    make_metadata_file(series_name, series_metadata, series_metadata_file)
  end

  if target_image_rdiff_target then
    task "latest-#{ series_name }" => target_image_rdiff_target
  end
end

file Cksums_file => $all_cksum_files do |t|
  tmpfile = "#{ Cksums_file }.tmp"
  File.open(tmpfile, 'w') do |f|
    $all_cksum_files.each do |cksum_file|
      f.write( IO.read(cksum_file) )
    end
  end
  mv tmpfile, Cksums_file
end
