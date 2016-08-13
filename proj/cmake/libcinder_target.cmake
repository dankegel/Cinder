cmake_minimum_required( VERSION 3.0 FATAL_ERROR )

cmake_policy( SET CMP0022 NEW )

set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CINDER_PATH}/${CINDER_LIB_DIRECTORY} )
set( CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CINDER_PATH}/${CINDER_LIB_DIRECTORY} )

if( CINDER_VERBOSE )
	message( "CMAKE_ARCHIVE_OUTPUT_DIRECTORY: ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}" )
endif()

# The type is based on the value of the BUILD_SHARED_LIBS variable.
# When OFF ( default value ) Cinder will be built as a static lib
# and when ON as a shared library.
# See https://cmake.org/cmake/help/v3.0/command/add_library.html for more info.
add_library(
	cinder 
    ${CINDER_SRC_FILES}
)

target_include_directories( cinder BEFORE INTERFACE ${CINDER_INCLUDE_USER_INTERFACE} )
target_include_directories( cinder SYSTEM BEFORE INTERFACE ${CINDER_INCLUDE_SYSTEM_INTERFACE} )

target_include_directories( cinder BEFORE PRIVATE ${CINDER_INCLUDE_USER_PRIVATE} )
target_include_directories( cinder SYSTEM BEFORE PRIVATE ${CINDER_INCLUDE_SYSTEM_PRIVATE} )

target_link_libraries( cinder PUBLIC ${CINDER_LIBS_DEPENDS} )

target_compile_definitions( cinder PUBLIC ${CINDER_DEFINES} )

# Check compiler support for enabling c++11 or c++14.
include( CheckCXXCompilerFlag )
CHECK_CXX_COMPILER_FLAG( "-std=c++14" COMPILER_SUPPORTS_CXX14 )
CHECK_CXX_COMPILER_FLAG( "-std=c++11" COMPILER_SUPPORTS_CXX11 )

if( COMPILER_SUPPORTS_CXX14 )
	set( CINDER_CXX_FLAGS "-std=c++14" )
elseif( COMPILER_SUPPORTS_CXX11 )
	set( CINDER_CXX_FLAGS "-std=c++11" )
else()
	message( FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has neither C++11 or C++14 support. Please use a different C++ compiler." )
endif()

# TODO: it would be nice to the following, but we can't until min required cmake is 3.3
#target_compile_options( cinder PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${CINDER_CXX_FLAGS}> )
set( CMAKE_CXX_FLAGS ${CINDER_CXX_FLAGS} ${CMAKE_CXX_FLAGS} )
target_compile_options( cinder INTERFACE ${CINDER_CXX_FLAGS} )

# This file will contain all dependencies, includes, definition, compiler flags and so on..
export( TARGETS cinder FILE ${PROJECT_BINARY_DIR}/${CINDER_LIB_DIRECTORY}/cinderTargets.cmake )

# And this command will generate a file on the ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}
# that applications have to pull in order to link successfully with Cinder and its dependencies.
# This specific cinderConfig.cmake file will just hold a path to the above mention cinderTargets.cmake file which holds the actual info.
configure_file( ${CMAKE_CURRENT_LIST_DIR}/modules/cinderConfig.buildtree.cmake.in
	${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/cinderConfig.cmake
)

if( CINDER_INSTALL_LIBRARIES )
	# These commands cause 'make install' to do what many Unix/Linux
	# developers expect, i.e. install a copy of libcinder and its
	# headers, plus a pkgconfig file, to a global location so Cinder
	# can be used as a building block by apps that use pkgconfig
	# or bare -I's and -l's (rather than cmake features or
	# Cinder blocks) to find external libraries.
	# Using Cinder outside of its ecosystem like this is experimental,
	# so you will probably encounter many rough edges.
	# Install all the interface headers needed for users to use libcinder
	# Install into a "cinder" subdirectory to avoid clashing with
	# other installed headers.
	# Oh, dear me, cmake's install syntax is heinous.
	install(
		#DIRECTORY ${CINDER_PATH}/lib/${CINDER_TARGET_SUBFOLDER}/${CMAKE_BUILD_TYPE}/
		#DESTINATION lib/cinder/${CINDER_TARGET_GL}
		#FILES_MATCHING PATTERN libcinder*.a
		FILES ${CINDER_PATH}/lib/${CINDER_TARGET_SUBFOLDER}/${CMAKE_BUILD_TYPE}/libcinder.a
		DESTINATION lib/cinder/${CINDER_TARGET_GL}
	)
	install( DIRECTORY ${CINDER_INC_DIR}/cinder DESTINATION include/cinder )
	install( DIRECTORY ${CINDER_INC_DIR}/glload DESTINATION include/cinder )
	install( DIRECTORY ${CINDER_INC_DIR}/glm DESTINATION include/cinder )
	MESSAGE( "You are installing libcinder for external use.  External apps should:" )
	MESSAGE( "use -I ${CMAKE_INSTALL_PREFIX}/include/cinder to find cinder/cinder.h, and")
	MESSAGE( "use -L ${CMAKE_INSTALL_PREFIX}/lib/cinder to find -lcinder.")
	# FIXME: also install a .pc file with the preceding
endif()
