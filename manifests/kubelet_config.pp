class k8s_workernode::kubelet_config ( Hash $per_node_kubelet_conf, Hash $kubelet_config_hash, Hash $tls_hash ) {

    $k8s_kubelet_binarypath = $kubelet_config_hash["binarypath"]
    $kubelet_yamlconfig = $kubelet_config_hash["common"]["config"]
    $kubelet_kubeconfig = keys( $per_node_kubelet_conf["kubeconfig"] )[0]
    $kubelet_vardir = $per_node_kubelet_conf["vardir"]

    $own_ca_crt_path = $kubelet_config_hash["conf"][ "${kubelet_yamlconfig}" ]["authentication"]["x509"]["clientCAFile"]

    $own_ca_crt = $tls_hash["entities"]["ca"]["cert"]
    $kubelet_tls_key = $per_node_kubelet_conf["tlsPrivateKeyFile"]["value"]
    $kubelet_tls_cert = $per_node_kubelet_conf["tlsCertFile"]["value"]

    $kubelet_yamlconfig_main_part = hash2yml( $kubelet_config_hash["conf"][ "${kubelet_yamlconfig}" ] )
    $kubelet_yamlconfig_tls_cert_path = $per_node_kubelet_conf["tlsCertFile"]["name"]
    $kubelet_yamlconfig_tls_key_path = $per_node_kubelet_conf["tlsPrivateKeyFile"]["name"]

    $node_ip = $per_node_kubelet_conf["node-ip"]

    file { "${kubelet_vardir}":
        ensure => directory,
        mode => '0700',
        owner => root,
        group => root
    }

    file { "${own_ca_crt_path}" :
        ensure => file,
        mode => '0644',
        owner => root,
        group => root,
        content => inline_template( $own_ca_crt )
    }

    file { "${kubelet_yamlconfig_tls_cert_path}" :
        ensure => file,
        mode => '0644',
        owner => root,
        group => root,
        content => inline_template( $kubelet_tls_cert )
    }

    file { "${kubelet_yamlconfig_tls_key_path}" :
        ensure => file,
        mode => '0600',
        owner => root,
        group => root,
        content => inline_template( $kubelet_tls_key )
    }

    file { "${kubelet_kubeconfig}" :
        ensure => file,
        mode => '0600',
        owner => root,
        group => root,
        content => inline_template( hash2yml( $per_node_kubelet_conf["kubeconfig"][ $kubelet_kubeconfig ] ) )
    }


    file { "${kubelet_yamlconfig}" :
        ensure => file,
        mode => '0600',
        owner => root,
        group => root,
        content => inline_template( "${kubelet_yamlconfig_main_part}tlsCertFile: ${kubelet_yamlconfig_tls_cert_path}\ntlsPrivateKeyFile: ${kubelet_yamlconfig_tls_key_path}\n")
    }

    $exec_start_string = create_k8s_kubelet_exec_start( $k8s_kubelet_binarypath, $kubelet_config_hash, $kubelet_kubeconfig, $node_ip )

    file { "/etc/systemd/system/k8s-kubelet.service" :
        ensure => file,
        mode => '0644',
        owner => root,
        group => root,
        content => template("k8s_workernode/k8s-kubelet.systemd.erb")
    }

    exec { "systemd_reload_by_k8s_kubelet":
        command => 'systemctl daemon-reload',
        path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin" ],
        refreshonly => true,
        subscribe => File[ "/etc/systemd/system/k8s-kubelet.service" ]
    }
}

