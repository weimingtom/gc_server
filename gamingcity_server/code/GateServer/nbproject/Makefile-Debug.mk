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
	${OBJECTDIR}/GateClientSession.o \
	${OBJECTDIR}/GateDBManager.o \
	${OBJECTDIR}/GateGameSession.o \
	${OBJECTDIR}/GateLoginSession.o \
	${OBJECTDIR}/GateServer.o \
	${OBJECTDIR}/GateServerConfigManager.o \
	${OBJECTDIR}/GateSessionManager.o \
	${OBJECTDIR}/cfg/GateServerConfig.pb.o \
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
LDLIBSOPTIONS=-L/root/redis/deps/hiredis/ ../../../common/pb/dist/../../../server/lib/libpb.a ../ServerCommon/dist/../../../lib/libservercommon.a /lib64/mysql/libmysqlclient.so /usr/local/lib64/libmysqlcppconn.so /usr/local/lib/libprotobuf.a /usr/local/lib/liblua.a /usr/local/lib/libboost_system.a /usr/local/lib/libboost_thread.a

# Build Targets
.build-conf: ${BUILD_SUBPROJECTS}
	"${MAKE}"  -f nbproject/Makefile-${CND_CONF}.mk ${CND_DISTDIR}/../../../project/Debug/gateserver

${CND_DISTDIR}/../../../project/Debug/gateserver: ../../../common/pb/dist/../../../server/lib/libpb.a

${CND_DISTDIR}/../../../project/Debug/gateserver: ../ServerCommon/dist/../../../lib/libservercommon.a

${CND_DISTDIR}/../../../project/Debug/gateserver: /lib64/mysql/libmysqlclient.so

${CND_DISTDIR}/../../../project/Debug/gateserver: /usr/local/lib64/libmysqlcppconn.so

${CND_DISTDIR}/../../../project/Debug/gateserver: /usr/local/lib/libprotobuf.a

${CND_DISTDIR}/../../../project/Debug/gateserver: /usr/local/lib/liblua.a

${CND_DISTDIR}/../../../project/Debug/gateserver: /usr/local/lib/libboost_system.a

${CND_DISTDIR}/../../../project/Debug/gateserver: /usr/local/lib/libboost_thread.a

${CND_DISTDIR}/../../../project/Debug/gateserver: ${OBJECTFILES}
	${MKDIR} -p ${CND_DISTDIR}/../../../project/Debug
	${LINK.cc} -o ${CND_DISTDIR}/../../../project/Debug/gateserver ${OBJECTFILES} ${LDLIBSOPTIONS} -lhiredis

${OBJECTDIR}/GateClientSession.o: GateClientSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7/build/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GateClientSession.o GateClientSession.cpp

${OBJECTDIR}/GateDBManager.o: GateDBManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7/build/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GateDBManager.o GateDBManager.cpp

${OBJECTDIR}/GateGameSession.o: GateGameSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7/build/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GateGameSession.o GateGameSession.cpp

${OBJECTDIR}/GateLoginSession.o: GateLoginSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7/build/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GateLoginSession.o GateLoginSession.cpp

${OBJECTDIR}/GateServer.o: GateServer.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7/build/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GateServer.o GateServer.cpp

${OBJECTDIR}/GateServerConfigManager.o: GateServerConfigManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7/build/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GateServerConfigManager.o GateServerConfigManager.cpp

${OBJECTDIR}/GateSessionManager.o: GateSessionManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7/build/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GateSessionManager.o GateSessionManager.cpp

${OBJECTDIR}/cfg/GateServerConfig.pb.o: cfg/GateServerConfig.pb.cc
	${MKDIR} -p ${OBJECTDIR}/cfg
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7/build/ -std=c++11 -I/usr/local/protobuf/include/ -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/cfg/GateServerConfig.pb.o cfg/GateServerConfig.pb.cc

${OBJECTDIR}/stdafx.o: stdafx.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7/build/ -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/stdafx.o stdafx.cpp

# Subprojects
.build-subprojects:
	cd ../../../common/pb && ${MAKE}  -f Makefile CONF=Debug
	cd ../ServerCommon && ${MAKE}  -f Makefile CONF=Debug

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r ${CND_BUILDDIR}/${CND_CONF}
	${RM} -r ${CND_DISTDIR}/../../../project/Debug/libmysqlcppconn.so ${CND_DISTDIR}/../../../project/Debug/libmysqlclient.so
	${RM} ${CND_DISTDIR}/../../../project/Debug/gateserver

# Subprojects
.clean-subprojects:
	cd ../../../common/pb && ${MAKE}  -f Makefile CONF=Debug clean
	cd ../ServerCommon && ${MAKE}  -f Makefile CONF=Debug clean

# Enable dependency checking
.dep.inc: .depcheck-impl

include .dep.inc
