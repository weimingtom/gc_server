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
	${OBJECTDIR}/BaseServer.o \
	${OBJECTDIR}/BindDBConnectionPool.o \
	${OBJECTDIR}/BindGameLog.o \
	${OBJECTDIR}/BindGameTimer.o \
	${OBJECTDIR}/BindRedis.o \
	${OBJECTDIR}/DBConnection.o \
	${OBJECTDIR}/DBConnectionPool.o \
	${OBJECTDIR}/FileMD5.o \
	${OBJECTDIR}/GameLog.o \
	${OBJECTDIR}/GameTimeManager.o \
	${OBJECTDIR}/GmManager.o \
	${OBJECTDIR}/LuaDBConnectionPool.o \
	${OBJECTDIR}/LuaScriptManager.o \
	${OBJECTDIR}/NetworkConnectSession.o \
	${OBJECTDIR}/NetworkDispatcher.o \
	${OBJECTDIR}/NetworkIoServicePool.o \
	${OBJECTDIR}/NetworkServer.o \
	${OBJECTDIR}/NetworkSession.o \
	${OBJECTDIR}/OpenSSLCryptoManager.o \
	${OBJECTDIR}/RSAEuro/md5c.o \
	${OBJECTDIR}/RSAEuro/nn.o \
	${OBJECTDIR}/RSAEuro/prime.o \
	${OBJECTDIR}/RSAEuro/r_keygen.o \
	${OBJECTDIR}/RSAEuro/r_random.o \
	${OBJECTDIR}/RSAEuro/r_stdlib.o \
	${OBJECTDIR}/RSAEuro/rsa.o \
	${OBJECTDIR}/RedisConnection.o \
	${OBJECTDIR}/RedisConnectionThread.o \
	${OBJECTDIR}/UtilsHelper.o \
	${OBJECTDIR}/WindowsConsole.o \
	${OBJECTDIR}/base64.o \
	${OBJECTDIR}/cjson/fpconv.o \
	${OBJECTDIR}/cjson/lua_cjson.o \
	${OBJECTDIR}/cjson/lua_extensions.o \
	${OBJECTDIR}/cjson/strbuf.o \
	${OBJECTDIR}/lua_tinker.o \
	${OBJECTDIR}/lua_tinker_ex.o \
	${OBJECTDIR}/pbc-lua53.o \
	${OBJECTDIR}/platform_windows.o


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
LDLIBSOPTIONS=

# Build Targets
.build-conf: ${BUILD_SUBPROJECTS}
	"${MAKE}"  -f nbproject/Makefile-${CND_CONF}.mk ${CND_DISTDIR}/../../../lib/libservercommon.a

${CND_DISTDIR}/../../../lib/libservercommon.a: ${OBJECTFILES}
	${MKDIR} -p ${CND_DISTDIR}/../../../lib
	${RM} ${CND_DISTDIR}/../../../lib/libservercommon.a
	${AR} -rv ${CND_DISTDIR}/../../../lib/libservercommon.a ${OBJECTFILES} 
	$(RANLIB) ${CND_DISTDIR}/../../../lib/libservercommon.a

${OBJECTDIR}/BaseServer.o: BaseServer.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BaseServer.o BaseServer.cpp

${OBJECTDIR}/BindDBConnectionPool.o: BindDBConnectionPool.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BindDBConnectionPool.o BindDBConnectionPool.cpp

${OBJECTDIR}/BindGameLog.o: BindGameLog.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BindGameLog.o BindGameLog.cpp

${OBJECTDIR}/BindGameTimer.o: BindGameTimer.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BindGameTimer.o BindGameTimer.cpp

${OBJECTDIR}/BindRedis.o: BindRedis.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/BindRedis.o BindRedis.cpp

${OBJECTDIR}/DBConnection.o: DBConnection.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/DBConnection.o DBConnection.cpp

${OBJECTDIR}/DBConnectionPool.o: DBConnectionPool.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/DBConnectionPool.o DBConnectionPool.cpp

${OBJECTDIR}/FileMD5.o: FileMD5.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/FileMD5.o FileMD5.cpp

${OBJECTDIR}/GameLog.o: GameLog.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameLog.o GameLog.cpp

${OBJECTDIR}/GameTimeManager.o: GameTimeManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GameTimeManager.o GameTimeManager.cpp

${OBJECTDIR}/GmManager.o: GmManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/GmManager.o GmManager.cpp

${OBJECTDIR}/LuaDBConnectionPool.o: LuaDBConnectionPool.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/LuaDBConnectionPool.o LuaDBConnectionPool.cpp

${OBJECTDIR}/LuaScriptManager.o: LuaScriptManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/LuaScriptManager.o LuaScriptManager.cpp

${OBJECTDIR}/NetworkConnectSession.o: NetworkConnectSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/NetworkConnectSession.o NetworkConnectSession.cpp

${OBJECTDIR}/NetworkDispatcher.o: NetworkDispatcher.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/NetworkDispatcher.o NetworkDispatcher.cpp

${OBJECTDIR}/NetworkIoServicePool.o: NetworkIoServicePool.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/NetworkIoServicePool.o NetworkIoServicePool.cpp

${OBJECTDIR}/NetworkServer.o: NetworkServer.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/NetworkServer.o NetworkServer.cpp

${OBJECTDIR}/NetworkSession.o: NetworkSession.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/NetworkSession.o NetworkSession.cpp

${OBJECTDIR}/OpenSSLCryptoManager.o: OpenSSLCryptoManager.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/OpenSSLCryptoManager.o OpenSSLCryptoManager.cpp

${OBJECTDIR}/RSAEuro/md5c.o: RSAEuro/md5c.cpp
	${MKDIR} -p ${OBJECTDIR}/RSAEuro
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/RSAEuro/md5c.o RSAEuro/md5c.cpp

${OBJECTDIR}/RSAEuro/nn.o: RSAEuro/nn.cpp
	${MKDIR} -p ${OBJECTDIR}/RSAEuro
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/RSAEuro/nn.o RSAEuro/nn.cpp

${OBJECTDIR}/RSAEuro/prime.o: RSAEuro/prime.cpp
	${MKDIR} -p ${OBJECTDIR}/RSAEuro
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/RSAEuro/prime.o RSAEuro/prime.cpp

${OBJECTDIR}/RSAEuro/r_keygen.o: RSAEuro/r_keygen.cpp
	${MKDIR} -p ${OBJECTDIR}/RSAEuro
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/RSAEuro/r_keygen.o RSAEuro/r_keygen.cpp

${OBJECTDIR}/RSAEuro/r_random.o: RSAEuro/r_random.cpp
	${MKDIR} -p ${OBJECTDIR}/RSAEuro
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/RSAEuro/r_random.o RSAEuro/r_random.cpp

${OBJECTDIR}/RSAEuro/r_stdlib.o: RSAEuro/r_stdlib.cpp
	${MKDIR} -p ${OBJECTDIR}/RSAEuro
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/RSAEuro/r_stdlib.o RSAEuro/r_stdlib.cpp

${OBJECTDIR}/RSAEuro/rsa.o: RSAEuro/rsa.cpp
	${MKDIR} -p ${OBJECTDIR}/RSAEuro
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/RSAEuro/rsa.o RSAEuro/rsa.cpp

${OBJECTDIR}/RedisConnection.o: RedisConnection.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/RedisConnection.o RedisConnection.cpp

${OBJECTDIR}/RedisConnectionThread.o: RedisConnectionThread.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/RedisConnectionThread.o RedisConnectionThread.cpp

${OBJECTDIR}/UtilsHelper.o: UtilsHelper.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/UtilsHelper.o UtilsHelper.cpp

${OBJECTDIR}/WindowsConsole.o: WindowsConsole.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/WindowsConsole.o WindowsConsole.cpp

${OBJECTDIR}/base64.o: base64.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/base64.o base64.cpp

${OBJECTDIR}/cjson/fpconv.o: cjson/fpconv.c
	${MKDIR} -p ${OBJECTDIR}/cjson
	${RM} "$@.d"
	$(COMPILE.c) -g -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/cjson/fpconv.o cjson/fpconv.c

${OBJECTDIR}/cjson/lua_cjson.o: cjson/lua_cjson.c
	${MKDIR} -p ${OBJECTDIR}/cjson
	${RM} "$@.d"
	$(COMPILE.c) -g -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/cjson/lua_cjson.o cjson/lua_cjson.c

${OBJECTDIR}/cjson/lua_extensions.o: cjson/lua_extensions.c
	${MKDIR} -p ${OBJECTDIR}/cjson
	${RM} "$@.d"
	$(COMPILE.c) -g -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/cjson/lua_extensions.o cjson/lua_extensions.c

${OBJECTDIR}/cjson/strbuf.o: cjson/strbuf.c
	${MKDIR} -p ${OBJECTDIR}/cjson
	${RM} "$@.d"
	$(COMPILE.c) -g -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/cjson/strbuf.o cjson/strbuf.c

${OBJECTDIR}/lua_tinker.o: lua_tinker.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/lua_tinker.o lua_tinker.cpp

${OBJECTDIR}/lua_tinker_ex.o: lua_tinker_ex.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/lua_tinker_ex.o lua_tinker_ex.cpp

${OBJECTDIR}/pbc-lua53.o: pbc-lua53.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/pbc-lua53.o pbc-lua53.cpp

${OBJECTDIR}/platform_windows.o: platform_windows.cpp
	${MKDIR} -p ${OBJECTDIR}
	${RM} "$@.d"
	$(COMPILE.cc) -g -s -DPLATFORM_LINUX -I/usr/include/mysql -I../../../3rdParty/redis-3.2.8/deps/hiredis -I../../../common/pb -Icjson -I../../../3rdParty/mysql-connector-c++-1.1.7/driver/ -I../../../3rdParty/mysql-connector-c++-1.1.7 -I../../../3rdParty/mysql-connector-c++-1.1.7/build -I../../../../../redis/deps/hiredis -I../../../3rdParty/pbc-cloudwu -std=c++11 -MMD -MP -MF "$@.d" -o ${OBJECTDIR}/platform_windows.o platform_windows.cpp

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
