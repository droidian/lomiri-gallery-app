if(CLICK_MODE)
    execute_process(
      COMMAND dpkg-architecture -qDEB_HOST_ARCH
      OUTPUT_VARIABLE CLICK_ARCH
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json
            DESTINATION ${CMAKE_INSTALL_PREFIX})
    install(FILES gallery.apparmor gallery-content.json
            DESTINATION ${CMAKE_INSTALL_PREFIX})
endif(CLICK_MODE)

if(NOT CLICK_MODE)
    install(FILES gallery-content.json
            DESTINATION ${CMAKE_INSTALL_DATADIR}/lomiri-content-hub/peers/ RENAME lomiri-gallery-app)
endif(NOT CLICK_MODE)

