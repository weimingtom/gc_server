////
#ifndef __PATH_MANAGER_H__
#define __PATH_MANAGER_H__

#include "TSingleton.h"
#include "pugixml.hpp"
#include "MovePoint.h"
#include "XMLDecrypt.h"
#include <vector>
#include <list>
#include <map>

#define  PTCOUNT   4

#define SMALL_PATH		1
#define BIG_PATH		2
#define HUGE_PATH		4

enum NormalPathType
{
	NPT_LINE = 0,
	NPT_BEZIER,
	NPT_CIRCLE,
};

struct SPATH
{
	int				type;
	float			xPos[4];
	float			yPos[4];
	int				nNext;
	int				nDelay;
	int				PointCount;
	int				nPathType;
};

struct ShapeLine
{
	float				x[2];
	float				y[2];
	int					m_nCount;
	bool				m_bSame;
	int					m_PriceCount;
	std::vector<int>	m_lTypeList;
	std::vector<int>	m_lWeight;
	int					m_nPathID;
	float				m_fSpeed;
	float				m_fInterval;
};

struct ShapeCircle
{
	float				x;
	float				y;
	float				r;
	int					m_nCount;
	bool				m_bSame;
	int					m_PriceCount;
	std::vector<int>	m_lTypeList;
	std::vector<int>	m_lWeight;
	int					m_nPathID;
	float				m_fSpeed;
	float				m_fInterval;
};

struct ShapePoint
{
	float				x;
	float				y;
	int					m_nCount;
	bool				m_bSame;
	std::vector<int>	m_lTypeList;
	std::vector<int>	m_lWeight;
	int					m_nPathID;
	float				m_fSpeed;
	float				m_fInterval;
};

struct TroopData
{
	int							nTroopID;
	std::vector<std::string>	szDescrib;
	std::vector<ShapeLine>		LineData;
	std::vector<ShapeCircle>	CircleData;
	std::vector<ShapePoint>		PointData;
};

struct Troop
{
	int							nTroopID;
	std::vector<std::string>	Describe;
	std::vector<int>			nStep;
	std::vector<ShapePoint>		Shape;
};


class PathManager:public Singleton<PathManager>
{
protected:
	PathManager();
	virtual ~PathManager();

	friend class Singleton<PathManager>;
	friend class std::auto_ptr<PathManager>;

public:
	bool LoadNormalPath(std::string szPathFile, CXMLDecrypt* pcd = NULL);

	SPATH* GetNormalPath(int id);

	SPATH* GetTroopPath(int id);

	bool HasLoaded(){return m_bLoaded;}

	int GetRandNormalPathID();

	MovePoints* GetPathData(int id, bool bTroop);

	bool LoadTroop(std::string szFileName, CXMLDecrypt* pcd = NULL);

	void CreatTroopByData(TroopData& td, Troop& tp);

	Troop* GetTroop(int id);

	void SaveNormalPath(std::string szFileName);
	void SaveTroop(std::string szFileName);

	void CreatePathByData(SPATH* sp, bool xMirror, bool yMirror, bool xyMirror, bool Not, bool troop, MovePoints& out);

	std::vector<SPATH>		m_NormalPaths;
	std::map<int, SPATH>	m_TroopPath;
	std::map<int, Troop>	m_TroopMap;
	bool					m_bLoaded;

	std::map<int, TroopData>	m_TroopData;

	std::vector<MovePoints>		m_NormalPathVector;
	std::map<int, MovePoints>	m_TroopPathMap;
};

#endif
