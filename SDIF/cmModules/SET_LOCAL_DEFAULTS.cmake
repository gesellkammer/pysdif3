# set defaults for install prefix and build type
INCLUDE(REPLACE_DEFAULT_VALUE_MACRO)
REPLACE_DEFAULT_VALUE(CMAKE_BUILD_TYPE  STRING release 0 "set build type, debug or release" )
REPLACE_DEFAULT_VALUE(CMAKE_CONFIGURATION_TYPES STRING "Release;Debug;MinSizeRel;RelWithDebInfo" 0 "set supported configuration types")
IF(EXISTS /u/formes/share)
  REPLACE_DEFAULT_VALUE(CMAKE_INSTALL_PREFIX PATH /u/formes/share 0 "install prefix" )
ENDIF(EXISTS /u/formes/share)
IF("$ENV{HOST}" MATCHES ".*ircam.fr$" )
  SET(DOCSERVER files.rd.ircam.fr)
  SET(DOCDIR wikiRD/anasyn/docs/development/Easdif)
ENDIF("$ENV{HOST}" MATCHES ".*ircam.fr$" )
MESSAGE(STATUS "Configure for mode = ${CMAKE_BUILD_TYPE}")
