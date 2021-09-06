    # project name and programming language
    project('com.github.levoment.dynagenic', 'vala', 'c')

    configure_file(input : 'src/MainApplication.glade',
        output : 'MainApplication.glade',
        copy: true
    )


    configure_file(input : 'data/ApiVersions.json',
        output : 'ApiVersions.json',
        copy: true
    )

    configure_file(input : 'data/com.github.levoment.dynagenic.desktop',
        output : 'com.github.levoment.dynagenic.desktop',
        copy: true
    )


    # Create a new executable, list the files we want to compile, list the dependencies we need, and install
    executable(
        meson.project_name(),
        'src/Dynagenic.vala',
        'src/Versions.vala',
        'src/LoaderVersions.vala',
        'src/ApiVersions.vala',
        'src/InputVerifier.vala',
        dependencies: [
            dependency('gtk+-3.0'),
            dependency('gee-0.8'),
            dependency('libsoup-2.4'),
            dependency('json-glib-1.0'),
            dependency('libarchive')
        ],
        install: true
    )

    icon_sizes = ['16', '24', '32', '48', '64', '128', '256']

    #Install icons
    foreach i : icon_sizes
        install_data(
            join_paths('data/icons', i, meson.project_name() + '.svg'),
            install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
        )
        install_data(
            join_paths('data/icons', i, meson.project_name() + '.svg'),
            install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
        )

    endforeach

    #Install scalable icon
    install_data(
        join_paths('data/icons/256', meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
    )

    configure_file(input : join_paths('data/icons', meson.project_name() + '.png'),
        output : join_paths(meson.project_name() + '.png'),
        copy: true
    )

    # #Install ApiVersions file
    install_data(
        join_paths('data', 'ApiVersions.json'),
        install_dir: join_paths(get_option('datadir'), 'dynagenic', 'resources'),
        install_mode: 'rw-rw-rw-'
    )


    # #Install glade file
    install_data(
        join_paths('src', 'MainApplication.glade'),
        install_dir: join_paths(get_option('datadir'), 'dynagenic', 'resources')
    )

    #Install our .desktop file so the Applications Menu will see it
    install_data(
        join_paths('data', meson.project_name() + '.desktop'),
        install_dir: join_paths(get_option('datadir'), 'applications')
    )

    #meson.add_install_script('meson/makeDirectories.sh', join_paths(get_option('prefix'), get_option('datadir')))
    meson.add_install_script('meson/post_install.py', join_paths(get_option('prefix'), get_option('datadir'), 'dynagenic'))
