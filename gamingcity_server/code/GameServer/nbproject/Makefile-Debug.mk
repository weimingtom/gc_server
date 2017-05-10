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
	${OBJECTDIR}/GameServer.o \
	${OBJECTDIR}/stdafx.o


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
LDLIBSOPTIONS=-L/root/redis/deps/hiredis/ -L/usr/lib64 ../BaseGame/dist/../../../lib/libbasegame.a ../../../common/pb/dist/../../../server/lib/libpb.a ../ServerCommon/dist/../../../lib/libservercommon.a /usr/local/lib/liblua.a /usr/local/lib/libprotobuf.a /usr/local/lib/libboost_thread.a /usr/local/lib/libboost_system.a /lib64/mysql/libmysqlclient.so /usr/local/lib64/libmysqlcppconn.so ../../../3rdParty/pbc-cloudwu/build/libpbc.a

# Build Targets
.build-conf: ${BUILD_SUBPROJECTS}
	"${MAKE}"  -f nbproject/Makefile-${CND_CONF}.mk ${CND_DISTDIR}/../../../project/Debug/gameserver

${CND_DISTDIR}/../../../project/Debug/gameserver: ../BaseGame/dist/../../../lib/libbasegame.a

${CND_DISTDIR}/../../../project/Debug/gameserver: ../../../common/pb/dist/../../../server/lib/libpb.a

${CND_DISTDIR}/../../../project/Debug/gameserver: ../ServerCommon/dist/../../../lib/libservercommon.a

${CND_DISTDIR}/../../../project/Debug/gameserver: /usr/local/lib/liblua.a

${CND_DISTDIR}/../../../project/Debug/gameserver: /usr/local/lib/libprotobuf.a

${CND_DISTDIR}/../../../project/Debug/gameserver: /usr/local/lib/libboost_thread.a

${CND_DISTDIR}/../../../project/Debug/gameserver: /usr/local/lib/libboost_system.a

${CND_DISTDIR}/../../../project/Debug/gameserver: /lib64/mysql/libmysqlclient.so

${CND_DISTDIR}/../../../project/Debug/gameserver: /usr/local/lib64/libmysqlcppconn.so

${CND_DISTDIR}/../../../project/Debug/gameserver: ../../../3rdParty/pbc-cloudwu/build/libpbc.a

${CND_DISTDIR}/../../../project/Debug/gameserver: ${OBJECTFILES}
	${MKDIR} -p ${CND_DISTDIR}/../../../project/Debug
	${LINK.cc} -o ${CND_DISTDIR}/../../../project/Debug/gameserver ${OBJECTFILES} ${LDLIBSOPTIONS} -lhiredis -ldl

${OBJECTDIR}/GameServer.o: GameServer.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -I/usr/include/mysql -I../BaseGame -I../BaseGame/cfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameServer.o GameServer.cpp

${OBJECTDIR}/stdafx.o: stdafx.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../common/pb -I../ServerCommon -I/usr/include/mysql -I../BaseGame -I../BaseGame/cfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/stdafx.o stdafx.cpp

# Subprojects
.build-subprojects:
	cd ../BaseGame && ${MAKE}  -f Makefile CONF=Debug
	cd ../../../common/pb && ${MAKE}  -f Makefile CONF=Debug
	cd ../ServerCommon && ${MAKE}  -f Makefile CONF=Debug

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r ${CND_BUILDDIR}/${CND_CONF}
	${RM} -r ${CND_DISTDIR}/../../../project/Debug/libmysqlcppconn.so ${CND_DISTDIR}/../../../project/Debug/libmysqlclient.so
	${RM} ${CND_DISTDIR}/../../../project/Debug/gameserver

# Subprojects
.clean-subprojects:
	cd ../BaseGame && ${MAKE}  -f Makefile CONF=Debug clean
	cd ../../../common/pb && ${MAKE}  -f Makefile CONF=Debug clean
	cd ../ServerCommon && ${MAKE}  -f Makefile CONF=Debug clean

# Enable dependency checking
.dep.inc: .depcheck-impl

include .dep.inc
