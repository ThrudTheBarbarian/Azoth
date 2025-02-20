cmake_minimum_required(VERSION 3.10)

project(Azoth)

set (AZOTH_HEADER_DIR ${PROJECT_BINARY_DIR}/Azoth)
set (MODULE_HEADER ${AZOTH_HEADER_DIR}/Azoth.h)

file(GLOB_RECURSE SOURCES RELATIVE ${CMAKE_SOURCE_DIR} "Azoth/*.m")
file(GLOB_RECURSE HEADERS RELATIVE ${CMAKE_SOURCE_DIR} "Azoth/*.h")

add_executable(Azoth 
		${MODULE_HEADER}
		${SOURCES}
		)
		
add_custom_command(
	TARGET 				Azoth PRE_BUILD
    COMMAND 			make_directory(${AZOTH_HEADER_DIR})
    WORKING_DIRECTORY   ${PROJECT_BINARY_DIR}
)

add_custom_command(
    OUTPUT ${MODULE_HEADER}
    COMMAND ${CMAKE_COMMAND} -E copy ${HEADERS} ${AZOTH_HEADER_DIR}
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    DEPENDS ${AZOTH_HEADER_DIR}
)

target_include_directories(Azoth PUBLIC
		"${CMAKE_SOURCE_DIR}/Classes"
		"${CMAKE_SOURCE_DIR}/Classes/Utility"

		)

set_target_properties(Azoth PROPERTIES LINK_FLAGS "-Wl,-F/opt/SDL3")

target_link_libraries(Azoth PUBLIC -framework /opt/SDL3/SDL3.xcframework)
target_link_libraries(Azoth PUBLIC -framework /opt/SDL3/SDL3_image.xcframework)
target_link_libraries(Azoth PUBLIC -framework /opt/SDL3/SDL3_ttf.xcframework)

