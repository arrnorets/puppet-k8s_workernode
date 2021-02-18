class k8s_workernode::kube_proxy_config ( Hash $kube_proxy_config_hash, Hash $kubeconfigs_hash ) {

    $k8s_kube_proxy_binarypath = $kube_proxy_config_hash["binarypath"]
    $kube_proxy_yamlconfig = $kube_proxy_config_hash["common"]["config"]
    $kube_proxy_kubeconfig = $kube_proxy_config_hash["conf"][$kube_proxy_yamlconfig]["clientConnection"]["kubeconfig"]

    file { "${kube_proxy_kubeconfig}" :
        ensure => file,
        mode => '0600',
        owner => root,
        group => root,
        content => inline_template( hash2yml( $kubeconfigs_hash[ "${kube_proxy_kubeconfig}" ] ) )
    }

    file { "${kube_proxy_yamlconfig}" :
        ensure => file,
        mode => '0600',
        owner => root,
        group => root,
        content => inline_template( hash2yml( $kube_proxy_config_hash["conf"][ "${kube_proxy_yamlconfig}" ] ) ) 
    }

    $exec_start_string = create_k8s_kube_proxy_exec_start( $k8s_kube_proxy_binarypath, $kube_proxy_config_hash )

    file { "/etc/systemd/system/k8s-kubeproxy.service" :
        ensure => file,
        mode => '0644',
        owner => root,
        group => root,
        content => template("k8s_workernode/k8s-kubeproxy.systemd.erb")
    }

    exec { "systemd_reload_by_k8s_kube_proxy":
        command => 'systemctl daemon-reload',
        path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin" ],
        refreshonly => true,
        subscribe => File[ "/etc/systemd/system/k8s-kubeproxy.service" ]
    }
}

