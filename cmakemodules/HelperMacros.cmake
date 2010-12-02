# Copyright (c) 2008, Lawrence Livermore National Security, LLC. 
# Written by Martin Schulz, schulzm@llnl.gov, LLNL-CODE-402774,
# All rights reserved - please read information in "LICENCSE"

# TODO Martin please add the copyright statment of your choice, as well as 
#      a reference to the license or license file!
#
# This files is partially from the MUST project and bears the follwing copyright.
# Copyright (c) 2009, ZIH, Technische Universitaet Dresden, Federal Republic of Germany
# Copyright (c) 2009, LLNL, United States of America
#
# @file HelperMacros.cmake
#       Contains helpful macros.
#
# @author Tobias Hilbrich
# @date 16.03.2009

#=========================================================
# Macro
# Does:
#   Gets the name of a library, Gets the path to the 
#   P^nMPI patcher, Creates a CMake script in the binary
#   directory which executes the patcher for the given 
#   library. The result is placed in the P^nMPI library 
#   directory. The script is added as a install script.
#   (executed at install time)
#=========================================================
MACRO (PNMPI_MAC_PATCH_LIB targetname patcher)
    #TODO: test whether this works with Windows pathes (spaces and such)
    #SET (lib ${CMAKE_SHARED_MODULE_PREFIX}${targetname}${CMAKE_SHARED_MODULE_SUFFIX}.${version})
    #Modules shouldn't have prefixes
    SET (libin ${CMAKE_SHARED_MODULE_PREFIX}${targetname}${CMAKE_SHARED_MODULE_SUFFIX})
    SET (libout ${targetname}${CMAKE_SHARED_MODULE_SUFFIX})
    
    FILE (WRITE ${PROJECT_BINARY_DIR}/install-scripts/patch-${libout}.cmake 
        "MESSAGE (\"Patching ${libout}\")\n"
        "EXECUTE_PROCESS (COMMAND mkdir -p ${CMAKE_INSTALL_PREFIX}/modules"
        "   RESULT_VARIABLE result"
        "   OUTPUT_VARIABLE output"
        "   ERROR_VARIABLE output)\n"
        "IF (result)\n"
        "   MESSAGE (FATAL_ERROR MKDIR MODULES \${output})\n"
        "ENDIF (result)\n"
        "EXECUTE_PROCESS (COMMAND ${patcher}"
        "   ${LIBRARY_OUTPUT_PATH}/${libin} ${CMAKE_INSTALL_PREFIX}/modules/${libout}"
        "   WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/install-scripts"
        "   RESULT_VARIABLE result"
        "   OUTPUT_VARIABLE output"
        "   ERROR_VARIABLE output)\n"
        "IF (result)\n"
        "   MESSAGE (FATAL_ERROR PATCHING \${output})\n"
        "ENDIF (result)\n"
        )
    INSTALL (SCRIPT ${PROJECT_BINARY_DIR}/install-scripts/patch-${libout}.cmake)
ENDMACRO (PNMPI_MAC_PATCH_LIB)

#=========================================================
# Macro
# Does:
#   Takes a targetname and a list of source files.
#   Adds a module with given name and sources, installs 
#   patches and versions it.
# 
# language: in C, CXX, FORTRAN
#=========================================================
MACRO (PNMPI_MAC_ADD_MODULE targetname sources language)
    #Add target and its dependency on the patcher
    ADD_LIBRARY(${targetname} MODULE ${sources})
    ADD_DEPENDENCIES(${targetname} ${TARGET_PATCHER})
    
    #Set lib version
    ## Removed versions here, MAC doesn't likes that, actually versions might really not make much sense for a module
    #SET_TARGET_PROPERTIES (${targetname} PROPERTIES
    #    VERSION ${PNMPI_VERSION}
    #    SOVERSION ${PNMPI_LIB_INTERFACE_VERSION}
    #    )  
    
    #For Apple set that undefined symbols should be looked up dynamically
    #(On linux this is already the default)
    IF (APPLE)
        SET_TARGET_PROPERTIES(${targetname} PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
    ENDIF (APPLE)
       
     #Add avoid MPICXX header flags for C++                                                                                     
    IF ("${language}" STREQUAL "CXX")
        SET (TEMP "")
        FOREACH (skip_flag ${MPI_CXX_SKIP_FLAGS})
            SET (TEMP "${TEMP} ${skip_flag}")
        ENDFOREACH (skip_flag)
        SET_TARGET_PROPERTIES(${targetname} PROPERTIES COMPILE_FLAGS "${TEMP}")
    ENDIF ("${language}" STREQUAL "CXX") 
    
    #Install it with reasonable file permissions
    #INSTALL(TARGETS ${targetname}
    #    PERMISSIONS 
    #        OWNER_READ OWNER_WRITE OWNER_EXECUTE 
    #        GROUP_EXECUTE GROUP_READ 
    #        WORLD_EXECUTE
    #    RUNTIME DESTINATION bin
    #    LIBRARY DESTINATION modules
    #    ARCHIVE DESTINATION modules
    #    )
    
    #Patch it during installation
    PNMPI_MAC_PATCH_LIB (
        ${targetname}
        ${PATCHER}
        )       
ENDMACRO (PNMPI_MAC_ADD_MODULE)
