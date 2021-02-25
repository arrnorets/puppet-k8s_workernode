class k8s_workernode {
    # /* Top hash */
    $hash_from_hiera = lookup('k8s_workernode', { merge => 'deep' } )
    # /* END BLOCK */

    # /* Kubernetes config and certs root directory */
    $k8s_rootdir_array = $hash_from_hiera['rootdirs']
    file { $k8s_rootdir_array :
        ensure => directory,
        owner => root,
        group => root,
        mode => '0700',
    }

    # /* Container runtime backend */
    $container_backend_value = $hash_from_hiera['container_backend']

    # /* Certificates for authentication */
    $tls_credetials_hash = lookup('k8s_tls_certs', { merge => 'deep' })
    # /* END BLOCK */

    # /* Kube proxy parameters start here */
    $hash_from_hiera_kube_proxy = $hash_from_hiera['kube-proxy']
    $k8s_kube_proxy_pkg_name = $hash_from_hiera_kube_proxy['pkg_name'] ? { undef => 'present', default => $hash_from_hiera_kube_proxy['pkg_name'] }
    $k8s_kube_proxy_pkg_version = $hash_from_hiera_kube_proxy['pkg_version'] ? { undef => 'present', default => $hash_from_hiera_kube_proxy['pkg_version'] }
    $k8s_kube_proxy_parameter_hash = $hash_from_hiera_kube_proxy['parameters'] ? { undef => 'false', default => $hash_from_hiera_kube_proxy['parameters'] } 
    $k8s_kube_proxy_service_enable_value = $hash_from_hiera_kube_proxy['enable'] ? { undef => false, default => $hash_from_hiera_kube_proxy['enable'] }
    # /* END BLOCK */

    # /* Kubelet parameters start here */
    $hash_from_hiera_kubelet = $hash_from_hiera['kubelet']
    $k8s_kubelet_pkg_name = $hash_from_hiera_kubelet['pkg_name'] ? { undef => 'present', default => $hash_from_hiera_kubelet['pkg_name'] }
    $k8s_kubelet_pkg_version = $hash_from_hiera_kubelet['pkg_version'] ? { undef => 'present', default => $hash_from_hiera_kubelet['pkg_version'] }
    $k8s_kubelet_parameter_hash = $hash_from_hiera_kubelet['parameters'] ? { undef => 'false', default => $hash_from_hiera_kubelet['parameters'] } 
    $k8s_kubelet_service_enable_value = $hash_from_hiera_kubelet['enable'] ? { undef => false, default => $hash_from_hiera_kubelet['enable'] }
    # /* END BLOCK */

    # /* CNI plugin and crictl packages */
    $k8s_cni_plugins_pkg_version = $hash_from_hiera['cni']['pkg_version']
    $k8s_crictl_pkg_name = $hash_from_hiera['crictl']['pkg_name']
    $k8s_crictl_pkg_version = $hash_from_hiera['crictl']['pkg_version']
     # /* END BLOCK */

    # /* Common kubeconfigs */
    $k8s_kubeconfigs_hash = lookup ( 'k8s_kubeconfigs', { merge => 'first' } )
    # /* END BLOCK */

    # /* Per worker node kubelet settings */
    $k8s_per_node_kubelet_conf = lookup( 'per_node_kubelet_conf', { merge => 'first' } )
    # /* END BLOCK */

    class { "k8s_workernode::install" :
        kube_proxy_pkg_name => $k8s_kube_proxy_pkg_name,
        kube_proxy_pkg_version => $k8s_kube_proxy_pkg_version,
        kubelet_pkg_name => $k8s_kubelet_pkg_name,
        kubelet_pkg_version => $k8s_kubelet_pkg_version,
        crictl_pkg_name => $k8s_crictl_pkg_name,
        crictl_pkg_version => $k8s_crictl_pkg_version,
        cni_plugins_pkg_version => $k8s_cni_plugins_pkg_version,
        container_backend => $container_backend_value
    }

    class { "k8s_workernode::kube_proxy_config" :
        kube_proxy_config_hash => $k8s_kube_proxy_parameter_hash,
        kubeconfigs_hash => $k8s_kubeconfigs_hash
    }

    class { "k8s_workernode::kubelet_config" :
        per_node_kubelet_conf => $k8s_per_node_kubelet_conf,
        kubelet_config_hash => $k8s_kubelet_parameter_hash,
        tls_hash => $tls_credetials_hash
    }

    class { "k8s_workernode::service" :
        k8s_kube_proxy_service_enable => $k8s_kube_proxy_service_enable_value,
        k8s_kubelet_service_enable => $k8s_kubelet_service_enable_value
    }

}

