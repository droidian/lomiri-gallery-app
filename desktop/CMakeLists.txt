include(FindGettext)

install(DIRECTORY icons/hicolor DESTINATION
        ${CMAKE_INSTALL_DATADIR}/icons FILES_MATCHING PATTERN *.png)

set(ICON "${GALLERY}")
set(SPLASH_DIR "${GALLERY_DIR}")
set(APP_EXEC "${GALLERY}")

set(SPLASH "${SPLASH_DIR}/${GALLERY}-splash.svg")

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
