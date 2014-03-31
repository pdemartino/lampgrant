# file { '/etc/apt/sources.list':
#   ensure => 'present',
#   target => '/vagrant/vagrant/puppet/apt/sources.list',
#   notify => [Exec['Import Aptitude GPG keys'], Exec['apt-update']],
# }

# exec { 'Import Aptitude GPG keys':
#   command     => '/usr/bin/apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 3B4FE6ACC0B21F32',
#   require     => File['/etc/apt/sources.list'],
#   refreshonly => true,
# }

# exec { 'apt-update':
#   command     => '/usr/bin/apt-get update',
#   require     => Exec['Import Aptitude GPG keys'],
#   refreshonly => true,
# }

exec { 'apt-update':
  command     => '/usr/bin/apt-get update',
  #refreshonly => true,
}

Exec["apt-update"] -> Package <| |>

# Misc. dependencies


$essential = [
   'vim',
   'colordiff',
   'tmux',
   'tree',
   'curl',
   'unzip', 'tar'
]
package {$essential: ensure => 'latest'}

$versioning = [
   'git',
   'subversion'
]
package {$versioning: ensure => 'latest'}

$remote_fs = [
   'sshfs',
   'curlftpfs',
]
package {$remote_fs: ensure => 'latest'}

# Shared folders
class nfs-server {
   package {'nfs-server':
      ensure => 'latest',
   }
   service {'nfs-kernel-server':
      ensure => 'running',
      enable => 'true',
      require => Package['nfs-server']
   }
   file {'/etc/exports':
      ensure => 'present',
      require => Package['nfs-server'],
      target => '/vagrant/puppet/data/etc/exports',
      notify => Service['nfs-kernel-server']
   }
}
include nfs-server

# Setup Apache
class apache2 {
   package { 'apache2':
      ensure  => 'present',
      require => Exec['apt-update'],
   }
   service { 'apache2':
      ensure  => 'running',
      enable  => 'true',
      require => Package['apache2'],
   }
   #Enable mod_rewrite
   exec { 'ModRewrite-Enable':
      command => '/usr/sbin/a2enmod rewrite',
      require => Package['apache2'],
      notify => Service['apache2']
   }
}
include apache2
# file { '/etc/apache2/ports.conf':
#   notify  => Service['apache2'],
#   require => Package['apache2'],
#   ensure  => 'file',
#   source  => '/vagrant/vagrant/puppet/apache/ports.conf',
# }

# file { '/etc/apache2/sites-available/default':
#   notify  => Service['apache2'],
#   require => Package['apache2'],
#   ensure  => 'file',
#   source  => '/vagrant/vagrant/puppet/apache/default_vhost.conf',
# }

# file { '/etc/apache2/sites-available/default-ssl.conf':
#   require => Package['apache2'],
#   ensure  => 'absent',
# }

# file { 'Enable mod_rewrite':
#   path    => '/etc/apache2/mods-enabled/rewrite.load',
#   notify  => Service['apache2'],
#   require => Package['apache2'],
#   ensure  => 'link',
#   target  => '/etc/apache2/mods-available/rewrite.load',
# }

# Setup MySQL

package { 'mysql-server':
  ensure  => 'present',
  require => Exec['apt-update'],
}

service { 'mysql':
  ensure  => 'running',
  enable  => 'true',
  require => Package['mysql-server'],
}

# exec { 'Drop anonymous MySQL users':
#   require  => Package['mysql-server'],
#   command  => '/bin/echo "DELETE FROM mysql.user WHERE User = \'\'" | /usr/bin/mysql -u root',
#   onlyif   => "/usr/bin/mysql -u root -e \"SELECT User FROM mysql.user WHERE User LIKE ''\" | /bin/grep 'User'",
# }

# Install PHP and required PHP extensions

 package { 'php5':
   ensure  => 'present',
   notify  => Service['apache2'],
   require => Exec['apt-update'],
 }

package { 'php5-extensions':
   name    => [
     'php-pear',
     'php5-fpm',
     'php5-curl',
     'php5-dev',
     'php5-intl',
     'php5-gd',
     'php5-mcrypt',
     'php5-memcache',
     'php5-mysql',
     'php5-xdebug'
   ],
   ensure  => 'present',
   notify  => Service['apache2'],
   require => Package['php5'],
}

# php5 configuration
file {'/etc/apache2/mods-available/php5.conf':
   ensure => 'present',
   require => Package['apache2', 'php5'],
   target => '/vagrant/puppet/data/etc/apache2/mods-available/php5.conf',
   #notify => Exec['force-reload-apache2']
   notify => Service['apache2']
}
# Apache Welcome Page
file { '/var/www/index.php':
  ensure => 'present',
  require => Package['apache2', 'php5'],
  target => '/vagrant/puppet/data/var/www/index.php',
}


# # phpMyAdmin

# exec { 'Download phpMyAdmin':
#   require => [Package['php5'], Package['git']],
#   cwd     => '/var/www/html',
#   command => '/usr/bin/git clone --depth 1 https://github.com/phpmyadmin/phpmyadmin.git',
#   creates => '/var/www/html/phpmyadmin',
# }

# file { '/var/www/html/phpmyadmin/config.inc.php':
#   require => Exec['Download phpMyAdmin'],
#   ensure  => 'file',
#   source  => '/vagrant/vagrant/puppet/phpmyadmin/config.inc.php',
# }

# # Install Composer

# exec { 'Install PHP Composer':
#   require => [Package['php5'], Package['curl']],
#   cwd     => '/usr/bin',
#   command => '/usr/bin/curl -sS https://getcomposer.org/installer | /usr/bin/php',
#   creates => '/usr/bin/composer.phar',
# }

# file { '/usr/bin/composer':
#   ensure => 'link',
#   target => '/usr/bin/composer.phar',
# }
