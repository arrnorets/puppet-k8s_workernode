class k8s_workernode::install ( String $kube_proxy_pkg_name, String $kube_proxy_pkg_version,
  String $kubelet_pkg_name, String $kubelet_pkg_version,
  String $crictl_pkg_name, String $crictl_pkg_version, String $cni_plugins_pkg_version,
  Hash $container_backend ) {
    
    package { "${kube_proxy_pkg_name}":
        ensure => $kube_proxy_pkg_version,
    }

    package { "${kubelet_pkg_name}":
        ensure => $kubelet_pkg_version,
    }

    package { "${crictl_pkg_name}":
        ensure => $crictl_pkg_version,
    }

    package { "cni-plugins":
        ensure => $cni_plugins_pkg_version,
    }

    file { [ "/etc/cni", "/etc/cni/net.d" ] :
        ensure => directory,
        owner => root,
        group => root,
        mode => '0700',
    }

    file { "/etc/cni/net.d/99-loopback.conf" :
        ensure => file,
        owner => root,
        mode => '0644',
        content => template( 'k8s_workernode/cni/99-loopback.conf.erb' ),
        require => Package[ "cni-plugins" ]
    }

    case $container_backend["name"] {
        'containerd': {
            package { $container_backend["pkg_name"] :
                ensure =>  $container_backend["pkg_version"]
            }
            file { "/etc/containerd/config.toml" :
                ensure => file,
                owner => root,
                group => root,
                mode => '0644',
                content => template( 'k8s_workernode/containerd/config.toml.erb' ),
                require => Package[ $container_backend["pkg_name"] ],
                notify => Service[ $container_backend["name"] ]
            }
            service { $container_backend["name"] :
                ensure => running,
                enable => true,
                subscribe => Package[ $container_backend["pkg_name"] ]
            }
	}
        default: {
            fail { "Unrecognized container backend: ${container_backend}" : }
        }
    }
}

