include(FindGettext)

if(CLICK_MODE)
    install(FILES ${GALLERY}.svg
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons)
    set(ICON   "${CMAKE_INSTALL_DATADIR}/icons/${GALLERY}.svg")
    set(SPLASH_DIR "${CMAKE_INSTALL_DATADIR}/icons")
    set(APP_EXEC "lomiri-gallery-app-migrate.py ${GALLERY}")
else(CLICK_MODE)
    install(DIRECTORY icons/hicolor
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons)
    install(FILES ${GALLERY}.svg
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
    set(ICON "${GALLERY}")
    set(SPLASH_DIR "${GALLERY_DIR}")
    set(APP_EXEC "${GALLERY}")
endif(CLICK_MODE)

set(SPLASH "${SPLASH_DIR}/${GALLERY}-splash.svg")
set(GALLERY_URL_DISPATCHER ${GALLERY}.url-dispatcher)

configure_file(${DESKTOP_FILE}.in.in ${DESKTOP_FILE}.in @ONLY)
add_custom_target(${DESKTOP_FILE} ALL
    COMMENT "Merging translations into ${DESKTOP_FILE}"
    COMMAND ${GETTEXT_MSGFMT_EXECUTABLE}
            --desktop --template=${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}.in
            -o ${DESKTOP_FILE}
            -d ${CMAKE_SOURCE_DIR}/po
    )

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)

install(FILES ${GALLERY_URL_DISPATCHER}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/lomiri-url-dispatcher/urls
    )

install(FILES ${GALLERY}-splash.svg
    DESTINATION ${SPLASH_DIR}
    )
