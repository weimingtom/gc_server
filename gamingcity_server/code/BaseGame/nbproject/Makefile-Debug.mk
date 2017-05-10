#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Environment
MKDIR=mkdir
CP=cp
GREP=grep
NM=nm
CCADMIN=CCadmin
RANLIB=ranlib
CC=gcc
CCC=g++
CXX=g++
FC=gfortran
AS=as

# Macros
CND_PLATFORM=GNU-Linux
CND_DLIB_EXT=so
CND_CONF=Debug
CND_DISTDIR=dist
CND_BUILDDIR=build

# Include project Makefile
include Makefile

# Object Directory
OBJECTDIR=${CND_BUILDDIR}/${CND_CONF}/${CND_PLATFORM}

# Object Files
OBJECTFILES= \
	${OBJECTDIR}/BaseGameLuaScriptManager.o \
	${OBJECTDIR}/BaseGameServer.o \
	${OBJECTDIR}/BindBaseGameNetMessage.o \
	${OBJECTDIR}/GameDBManager.o \
	${OBJECTDIR}/GameDBSession.o \
	${OBJECTDIR}/GameGmManager.o \
	${OBJECTDIR}/GameLoginSession.o \
	${OBJECTDIR}/GameServerConfigManager.o \
	${OBJECTDIR}/GameSession.o \
	${OBJECTDIR}/GameSessionManager.o \
	${OBJECTDIR}/cfg/GameServerConfig.pb.o


# C Compiler Flags
CFLAGS=

# CC Compiler Flags
CCFLAGS=
CXXFLAGS=

# Fortran Compiler Flags
FFLAGS=

# Assembler Flags
ASFLAGS=

# Link Libraries and Options
LDLIBSOPTIONS=

# Build Targets
.build-conf: ${BUILD_SUBPROJECTS}
	"${MAKE}"  -f nbproject/Makefile-${CND_CONF}.mk ${CND_DISTDIR}/../../../lib/libbasegame.a

${CND_DISTDIR}/../../../lib/libbasegame.a: ${OBJECTFILES}
	${MKDIR} -p ${CND_DISTDIR}/../../../lib
	${RM} ${CND_DISTDIR}/../../../lib/libbasegame.a
	${AR} -rv ${CND_DISTDIR}/../../../lib/libbasegame.a ${OBJECTFILES} 
	$(RANLIB) ${CND_DISTDIR}/../../../lib/libbasegame.a

${OBJECTDIR}/BaseGameLuaScriptManager.o: BaseGameLuaScriptManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BaseGameLuaScriptManager.o BaseGameLuaScriptManager.cpp

${OBJECTDIR}/BaseGameServer.o: BaseGameServer.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BaseGameServer.o BaseGameServer.cpp

${OBJECTDIR}/BindBaseGameNetMessage.o: BindBaseGameNetMessage.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BindBaseGameNetMessage.o BindBaseGameNetMessage.cpp

${OBJECTDIR}/GameDBManager.o: GameDBManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameDBManager.o GameDBManager.cpp

${OBJECTDIR}/GameDBSession.o: GameDBSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameDBSession.o GameDBSession.cpp

${OBJECTDIR}/GameGmManager.o: GameGmManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameGmManager.o GameGmManager.cpp

${OBJECTDIR}/GameLoginSession.o: GameLoginSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameLoginSession.o GameLoginSession.cpp

${OBJECTDIR}/GameServerConfigManager.o: GameServerConfigManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameServerConfigManager.o GameServerConfigManager.cpp

${OBJECTDIR}/GameSession.o: GameSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameSession.o GameSession.cpp

${OBJECTDIR}/GameSessionManager.o: GameSessionManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameSessionManager.o GameSessionManager.cpp

${OBJECTDIR}/cfg/GameServerConfig.pb.o: cfg/GameServerConfig.pb.cc
	${MKDIR} -p ${OBJECTDIR}/cfg
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -Icfg -I/root/redis/deps/hiredis/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/cfg/GameServerConfig.pb.o cfg/GameServerConfig.pb.cc

# Subprojects
.build-subprojects:

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r ${CND_BUILDDIR}/${CND_CONF}

# Subprojects
.clean-subprojects:

# Enable dependency checking
.dep.inc: .depcheck-impl

include .dep.inc
