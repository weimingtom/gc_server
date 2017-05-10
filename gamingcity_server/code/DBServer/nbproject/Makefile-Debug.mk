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
	${OBJECTDIR}/BindDBManager.o \
	${OBJECTDIR}/BindDBNetManager.o \
	${OBJECTDIR}/DBLuaScriptManager.o \
	${OBJECTDIR}/DBManager.o \
	${OBJECTDIR}/DBServer.o \
	${OBJECTDIR}/DBServerConfigManager.o \
	${OBJECTDIR}/DBSession.o \
	${OBJECTDIR}/DBSessionManager.o \
	${OBJECTDIR}/cfg/DBServerConfig.pb.o \
	${OBJECTDIR}/stdafx.o


# C Compiler Flags
CFLAGS=

# CC Compiler Flags
CCFLAGS=-I/usr/local/protobuf/include/
CXXFLAGS=-I/usr/local/protobuf/include/

# Fortran Compiler Flags
FFLAGS=

# Assembler Flags
ASFLAGS=

# Link Libraries and Options
LDLIBSOPTIONS=-L/root/redis/deps/hiredis/ -L/usr/lib64 ../../../common/pb/dist/../../../server/lib/libpb.a ../ServerCommon/dist/../../../lib/libservercommon.a /usr/local/lib/libboost_system.a /usr/local/lib/libboost_thread.a /usr/local/lib/liblua.a /usr/local/lib/libprotobuf.a /lib64/mysql/libmysqlclient.so /usr/local/lib64/libmysqlcppconn.so ../../../3rdParty/pbc-cloudwu/build/libpbc.a

# Build Targets
.build-conf: ${BUILD_SUBPROJECTS}
	"${MAKE}"  -f nbproject/Makefile-${CND_CONF}.mk ${CND_DISTDIR}/../../../project/Debug/dbserver

${CND_DISTDIR}/../../../project/Debug/dbserver: ../../../common/pb/dist/../../../server/lib/libpb.a

${CND_DISTDIR}/../../../project/Debug/dbserver: ../ServerCommon/dist/../../../lib/libservercommon.a

${CND_DISTDIR}/../../../project/Debug/dbserver: /usr/local/lib/libboost_system.a

${CND_DISTDIR}/../../../project/Debug/dbserver: /usr/local/lib/libboost_thread.a

${CND_DISTDIR}/../../../project/Debug/dbserver: /usr/local/lib/liblua.a

${CND_DISTDIR}/../../../project/Debug/dbserver: /usr/local/lib/libprotobuf.a

${CND_DISTDIR}/../../../project/Debug/dbserver: /lib64/mysql/libmysqlclient.so

${CND_DISTDIR}/../../../project/Debug/dbserver: /usr/local/lib64/libmysqlcppconn.so

${CND_DISTDIR}/../../../project/Debug/dbserver: ../../../3rdParty/pbc-cloudwu/build/libpbc.a

${CND_DISTDIR}/../../../project/Debug/dbserver: ${OBJECTFILES}
	${MKDIR} -p ${CND_DISTDIR}/../../../project/Debug
	${LINK.cc} -o ${CND_DISTDIR}/../../../project/Debug/dbserver ${OBJECTFILES} ${LDLIBSOPTIONS} -lhiredis -ldl

${OBJECTDIR}/BindDBManager.o: BindDBManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BindDBManager.o BindDBManager.cpp

${OBJECTDIR}/BindDBNetManager.o: BindDBNetManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BindDBNetManager.o BindDBNetManager.cpp

${OBJECTDIR}/DBLuaScriptManager.o: DBLuaScriptManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/DBLuaScriptManager.o DBLuaScriptManager.cpp

${OBJECTDIR}/DBManager.o: DBManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/DBManager.o DBManager.cpp

${OBJECTDIR}/DBServer.o: DBServer.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/DBServer.o DBServer.cpp

${OBJECTDIR}/DBServerConfigManager.o: DBServerConfigManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/DBServerConfigManager.o DBServerConfigManager.cpp

${OBJECTDIR}/DBSession.o: DBSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/DBSession.o DBSession.cpp

${OBJECTDIR}/DBSessionManager.o: DBSessionManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/DBSessionManager.o DBSessionManager.cpp

${OBJECTDIR}/cfg/DBServerConfig.pb.o: cfg/DBServerConfig.pb.cc
	${MKDIR} -p ${OBJECTDIR}/cfg
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/cfg/DBServerConfig.pb.o cfg/DBServerConfig.pb.cc

${OBJECTDIR}/stdafx.o: stdafx.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -DPLATFORM_LINUX -I/root/redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -I../../../3rdParty/pbc-cloudwu/src -I../../../3rdParty/rapidjson-1.1.0/include -I../../../common/pb -I../ServerCommon -Icfg -I/usr/include/mysql -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/stdafx.o stdafx.cpp

# Subprojects
.build-subprojects:
	cd ../../../common/pb && ${MAKE}  -f Makefile CONF=Debug
	cd ../ServerCommon && ${MAKE}  -f Makefile CONF=Debug

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r ${CND_BUILDDIR}/${CND_CONF}
	${RM} -r ${CND_DISTDIR}/../../../project/Debug/libmysqlcppconn.so ${CND_DISTDIR}/../../../project/Debug/libmysqlclient.so
	${RM} ${CND_DISTDIR}/../../../project/Debug/dbserver

# Subprojects
.clean-subprojects:
	cd ../../../common/pb && ${MAKE}  -f Makefile CONF=Debug clean
	cd ../ServerCommon && ${MAKE}  -f Makefile CONF=Debug clean

# Enable dependency checking
.dep.inc: .depcheck-impl

include .dep.inc
