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
	${OBJECTDIR}/LoginDBSession.o \
	${OBJECTDIR}/LoginServer.o \
	${OBJECTDIR}/LoginServerConfigManager.o \
	${OBJECTDIR}/LoginSession.o \
	${OBJECTDIR}/LoginSessionManager.o \
	${OBJECTDIR}/LoginSmsSession.o \
	${OBJECTDIR}/WebGmManager.o \
	${OBJECTDIR}/cfg/LoginServerConfig.pb.o \
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
LDLIBSOPTIONS=-L/root/redis/deps/hiredis/ ../../../common/pb/dist/../../../server/lib/libpb.a ../ServerCommon/dist/../../../lib/libservercommon.a /usr/local/lib/libboost_system.a /usr/local/lib/libboost_thread.a /usr/local/lib/libprotobuf.a /usr/local/lib/liblua.a

# Build Targets
.build-conf: ${BUILD_SUBPROJECTS}
	"${MAKE}"  -f nbproject/Makefile-${CND_CONF}.mk ${CND_DISTDIR}/../../../project/Debug/loginserver

${CND_DISTDIR}/../../../project/Debug/loginserver: ../../../common/pb/dist/../../../server/lib/libpb.a

${CND_DISTDIR}/../../../project/Debug/loginserver: ../ServerCommon/dist/../../../lib/libservercommon.a

${CND_DISTDIR}/../../../project/Debug/loginserver: /usr/local/lib/libboost_system.a

${CND_DISTDIR}/../../../project/Debug/loginserver: /usr/local/lib/libboost_thread.a

${CND_DISTDIR}/../../../project/Debug/loginserver: /usr/local/lib/libprotobuf.a

${CND_DISTDIR}/../../../project/Debug/loginserver: /usr/local/lib/liblua.a

${CND_DISTDIR}/../../../project/Debug/loginserver: ${OBJECTFILES}
	${MKDIR} -p ${CND_DISTDIR}/../../../project/Debug
	${LINK.cc} -o ${CND_DISTDIR}/../../../project/Debug/loginserver ${OBJECTFILES} ${LDLIBSOPTIONS} -lhiredis

${OBJECTDIR}/LoginDBSession.o: LoginDBSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis/ -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/LoginDBSession.o LoginDBSession.cpp

${OBJECTDIR}/LoginServer.o: LoginServer.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis/ -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/LoginServer.o LoginServer.cpp

${OBJECTDIR}/LoginServerConfigManager.o: LoginServerConfigManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis/ -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/LoginServerConfigManager.o LoginServerConfigManager.cpp

${OBJECTDIR}/LoginSession.o: LoginSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis/ -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/LoginSession.o LoginSession.cpp

${OBJECTDIR}/LoginSessionManager.o: LoginSessionManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis/ -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/LoginSessionManager.o LoginSessionManager.cpp

${OBJECTDIR}/LoginSmsSession.o: LoginSmsSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis/ -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/LoginSmsSession.o LoginSmsSession.cpp

${OBJECTDIR}/WebGmManager.o: WebGmManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis/ -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/WebGmManager.o WebGmManager.cpp

${OBJECTDIR}/cfg/LoginServerConfig.pb.o: cfg/LoginServerConfig.pb.cc
	${MKDIR} -p ${OBJECTDIR}/cfg
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis/ -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/cfg/LoginServerConfig.pb.o cfg/LoginServerConfig.pb.cc

${OBJECTDIR}/stdafx.o: stdafx.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis/ -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/stdafx.o stdafx.cpp

# Subprojects
.build-subprojects:
	cd ../../../common/pb && ${MAKE}  -f Makefile CONF=Debug
	cd ../ServerCommon && ${MAKE}  -f Makefile CONF=Debug

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r ${CND_BUILDDIR}/${CND_CONF}

# Subprojects
.clean-subprojects:
	cd ../../../common/pb && ${MAKE}  -f Makefile CONF=Debug clean
	cd ../ServerCommon && ${MAKE}  -f Makefile CONF=Debug clean

# Enable dependency checking
.dep.inc: .depcheck-impl

include .dep.inc
