#!/bin/csh

#########################################################                                                
# SETUP IDL ENVIRONMENT                                                                                   
#########################################################                                                
if (-e /Applications/exelis) then
set IDLDIR='/Applications/exelis/idl'
else
set IDLDIR='/Applications/itt/idl/idl'
endif

setenv IDL_STARTUP ${HOME}/projects/VUMPS/REDUCTION/.idl_startup.pro

# ADD DEPENDENCIES TO PATH:
# 1st and 2nd dependencies: IDLAstro Package and the built in IDL lib:
# https://github.com/wlandsman/IDLAstro
setenv IDL_PATH +${IDLDIR}/lib
setenv IDL_PATH +${HOME}/projects/coyote:${IDL_PATH}
setenv IDL_PATH +${HOME}/projects/IDLAstro/pro:${IDL_PATH}

setenv IDL_PATH +${HOME}/idl:${IDL_PATH}
setenv IDL_PATH +${HOME}/projects/idlutils:${IDL_PATH}

setenv IDL_PATH +${HOME}/idl/mpfit:${IDL_PATH}
setenv IDL_PATH +${HOME}/projects/VUMPS/REDUCTION/code:${IDL_PATH}

set PROPATH = ${HOME}'/projects/VUMPS/REDUCTION/code'

echo "Now setting the path to "$IDL_PATH
echo "Now changing the directory to: "$PROPATH
cd $PROPATH
idl
