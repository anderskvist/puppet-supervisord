# Class: supervisord
#
# This class installs supervisord via pip
#
class supervisord(
  $package_ensure       = $supervisord::params::package_ensure,
  $package_name         = $supervisord::params::package_name,
  $package_provider     = $supervisord::params::package_provider,
  $package_install_options = $supervisord::params::package_install_options,
  $service_ensure       = $supervisord::params::service_ensure,
  $service_name         = $supervisord::params::service_name,
  $install_init         = $supervisord::params::install_init,
  $install_pip          = false,
  $init_defaults        = $supervisord::params::init_defaults,
  $init_template        = $supervisord::params::init_template,
  $setuptools_url       = $supervisord::params::setuptools_url,
  $executable_path      = $supervisord::params::executable_path,
  $executable           = $supervisord::params::executable,
  $executable_ctl       = $supervisord::params::executable_ctl,

  $scl_enabled          = $supervisord::params::scl_enabled,
  $scl_script           = $supervisord::params::scl_script,

  $log_path             = $supervisord::params::log_path,
  $log_file             = $supervisord::params::log_file,
  $log_level            = $supervisord::params::log_level,
  $logfile_maxbytes     = $supervisord::params::logfile_maxbytes,
  $logfile_backups      = $supervisord::params::logfile_backups,

  $run_path             = $supervisord::params::run_path,
  $pid_file             = $supervisord::params::pid_file,
  $nodaemon             = $supervisord::params::nodaemon,
  $minfds               = $supervisord::params::minfds,
  $minprocs             = $supervisord::params::minprocs,
  $config_include       = $supervisord::params::config_include,
  $config_include_purge = false,
  $config_file          = $supervisord::params::config_file,
  $config_dirs          = undef,
  $umask                = $supervisord::params::umask,

  $ctl_socket           = $supervisord::params::ctl_socket,

  $unix_socket          = $supervisord::params::unix_socket,
  $unix_socket_file     = $supervisord::params::unix_socket_file,
  $unix_socket_mode     = $supervisord::params::unix_socket_mode,
  $unix_socket_owner    = $supervisord::params::unix_socket_owner,
  $unix_socket_group    = $supervisord::params::unix_socket_group,
  $unix_auth            = $supervisord::params::unix_auth,
  $unix_username        = $supervisord::params::unix_username,
  $unix_password        = $supervisord::params::unix_password,

  $inet_server          = $supervisord::params::inet_server,
  $inet_server_hostname = $supervisord::params::inet_server_hostname,
  $inet_server_port     = $supervisord::params::inet_server_port,
  $inet_auth            = $supervisord::params::inet_auth,
  $inet_username        = $supervisord::params::inet_username,
  $inet_password        = $supervisord::params::inet_password,

  $user                 = undef,
  $identifier           = undef,
  $childlogdir          = undef,
  $environment          = undef,
  $env_var              = undef,
  $directory            = undef,
  $strip_ansi           = false,
  $nocleanup            = false,

  $eventlisteners       = {},
  $fcgi_programs        = {},
  $groups               = {},
  $programs             = {}

) inherits supervisord::params {

  validate_bool($install_pip)
  validate_bool($install_init)
  validate_bool($nodaemon)
  validate_bool($unix_socket)
  validate_bool($unix_auth)
  validate_bool($inet_server)
  validate_bool($inet_auth)
  validate_bool($strip_ansi)
  validate_bool($nocleanup)

  validate_hash($eventlisteners)
  validate_hash($fcgi_programs)
  validate_hash($groups)
  validate_hash($programs)

  validate_absolute_path($config_include)
  validate_absolute_path($log_path)
  validate_absolute_path($run_path)
  if $childlogdir { validate_absolute_path($childlogdir) }
  if $directory { validate_absolute_path($directory) }

  $log_levels = ['^critical$', '^error$', '^warn$', '^info$', '^debug$', '^trace$', '^blather$']
  validate_re($log_level, $log_levels, "invalid log_level: ${log_level}")
  validate_re($umask, '^0[0-7][0-7]$', "invalid umask: ${umask}.")
  validate_re($unix_socket_mode, '^[0-7][0-7][0-7][0-7]$', "invalid unix_socket_mode: ${unix_socket_mode}")
  validate_re($ctl_socket, ['^unix$', '^inet$'], "invalid ctl_socket: ${ctl_socket}")

  if ! is_integer($logfile_backups) { fail("invalid logfile_backups: ${logfile_backups}.")}
  if ! is_integer($minfds) { fail("invalid minfds: ${minfds}.")}
  if ! is_integer($minprocs) { fail("invalid minprocs: ${minprocs}.")}
  if ! is_integer($inet_server_port) { fail("invalid inet_server_port: ${inet_server_port}.")}

  if $unix_socket and $inet_server {
    $use_ctl_socket = $ctl_socket
  }
  elsif $unix_socket {
    $use_ctl_socket = 'unix'
  }
  elsif $inet_server {
    $use_unix_socket = 'inet'
  }

  if $use_ctl_socket == 'unix' {
    $ctl_serverurl = "unix://${supervisord::run_path}/${supervisord::unix_socket_file}"
    $ctl_auth      = $supervisord::unix_auth
    $ctl_username  = $supervisord::unix_username
    $ctl_password  = $supervisord::unix_password
  }
  elsif $use_ctl_socket == 'inet' {
    $ctl_serverurl = "http://${supervisord::inet_server_hostname}:${supervisord::inet_server_port}"
    $ctl_auth      = $supervisord::inet_auth
    $ctl_username  = $supervisord::inet_username
    $ctl_password  = $supervisord::inet_password
  }

  if $unix_auth {
    validte_string($unix_username)
    validte_string($unix_password)
  }

  if $inet_auth {
    validte_string($inet_username)
    validte_string($inet_password)
  }

  if $env_var {
    validate_hash($env_var)
    $env_hash = hiera($env_var)
    $env_string = hash2csv($env_hash)
  }
  elsif $environment {
    validate_hash($environment)
    $env_string = hash2csv($environment)
  }

  if $config_dirs {
    validate_array($config_dirs)
    $config_include_string = join($config_dirs, ' ')
  }
  else {
    $config_include_string = "${config_include}/*.conf"
  }

  create_resources('supervisord::eventlistener', $eventlisteners)
  create_resources('supervisord::fcgi_program', $fcgi_programs)
  create_resources('supervisord::group', $groups)
  create_resources('supervisord::program', $programs)

  if $install_pip {
    include supervisord::pip
    Class['supervisord::pip'] -> Class['supervisord::install']
  }

  include supervisord::install, supervisord::config, supervisord::service, supervisord::reload

  anchor { 'supervisord::begin': }
  anchor { 'supervisord::end': }

  Anchor['supervisord::begin'] ->
  Class['supervisord::install'] ->
  Class['supervisord::config'] ->
  Class['supervisord::service'] ->
  Anchor['supervisord::end']

  Class['supervisord::config'] ~> Class['supervisord::reload']
  Class['supervisord::config'] -> Supervisord::Program <| |> -> Supervisord::Group <| |>
  Class['supervisord::config'] -> Supervisord::Fcgi_program <| |> -> Supervisord::Group <| |>
  Class['supervisord::config'] -> Supervisord::Eventlistener <| |> -> Supervisord::Group <| |>
  Class['supervisord::config'] -> Supervisord::Rpcinterface <| |>
  Class['supervisord::reload'] -> Supervisord::Supervisorctl <| |>
}
