//
#ifndef __GAME_CONFIG_H__
#define __GAME_CONFIG_H__

#include "TSingleton.h"
#include "Size.h"
#include "MovePoint.h"
#include <string>
#include <map>
#include <vector>
#include <list>
#include "VisualCompent.h"
#include "XMLDecrypt.h"

enum SpecialFishType
{
	ESFT_NORMAL = 0,
	ESFT_KING,
	ESFT_KINGANDQUAN,
	ESFT_SANYUAN,
	ESFT_SIXI,
	ESFT_MAX,
};

struct Effect
{
	int					nTypeID;
	std::vector<int>	nParam;
};

struct Buffer
{
	int					nTypeID;
	float				fParam;
	float				fLife;
};

struct Visual
{
	int							nID;
	int							nTypeID;
	std::list<ImageInfo>		ImageInfoLive;
	std::list<ImageInfo>		ImageInfoDead;
};

struct BB
{
	float			fRadio;
	int				nOffestX;
	int				nOffestY;
};

struct BBX
{
	int				nID;
	std::list<BB>	BBList;
};

struct Fish
{
	int					nTypeID;
	TCHAR				szName[256];
	bool				bBroadCast;
	float				fProbability;
	int					nVisualID;
	int					nSpeed;
	int					nBoundBox;
	std::list<Effect>	EffectSet;	
	std::list<Buffer>	BufferSet;
	bool				bShowBingo;
	std::string			szParticle;
	bool				bShakeScree;
	int					nLockLevel;
};

struct Bullet
{
	int						nMulriple;
	int						nSpeed;
	int						nMaxCatch;
	int						nBulletSize;
	int						nCatchRadio;
	int						nCannonType;
	std::map<int, float>	ProbabilitySet;
};

enum RefershType
{
	ERT_NORMAL = 0,
	ERT_GROUP,					//”„»∫
	ERT_LINE,					//”„∂”
	ERT_SNAK,					//¥Û…ﬂ
};

struct DistrubFishSet
{
	float				ftime;
	int					nMinCount;
	int					nMaxCount;
	int					nRefershType;
	std::vector<int>	FishID;
	std::vector<int>	Weight;
	float				OffestX;
	float				OffestY;
	float				OffestTime;
};

struct TroopSet
{
	float				fBeginTime;
	float				fEndTime;
	int					nTroopID;
};

struct SceneSet
{
	int							nID;
	int							nNextID;
	std::string					szMap;
	float						fSceneTime;
	std::list<TroopSet>			TroopList;
	std::list<DistrubFishSet>	DistrubList;
};

struct SoundSet
{
	std::string	szFoundName;
	int			m_nProbility;
};

struct SpecialSet
{
	int			nTypeID;
	int			nSpecialType;
	float		fProbability;
	int			nMaxScore;
	float		fCatchProbability;
	float		fVisualScale;
	int			nVisualID;
	int			nBoundingBox;
	int			nLockLevel;
};

struct FirstFire
{
	int						nLevel;
	int						nCount;
	int						nPriceCount;
	std::vector<int>		FishTypeVector;
	std::vector<int>		WeightVector;
};

enum ResourceType
{
	ERST_Sprite = 0,
	ERST_Animation,
	ERST_Particle,
};

enum RenderState
{
	ERSS_Normal = 1,
	ERSS_FIRE	= 2,
	ERSS_Mul	= 4,
	ERSS_Score	= 8,
};

enum PartType
{
	EPT_BASE = 0,
	EPT_CANNON,
	EPT_EFFECT,
	EPT_CANNUM,
	EPT_SCORE,
	EPT_TAG,
};

struct CannonPart
{
	std::string		szResourceName;
	int				nResType;
	int				nType;
	MyPoint			Pos;
	int				FireOfffest;
	float			RoateSpeed;
};

struct CannonLock
{
	std::string		szLockIcon;
	std::string		szLockLine;
	std::string		szLockFlag;
	MyPoint			Pos;
};

struct CannonIon
{
	std::string		szIonFlag;
	MyPoint			Pos;
};

typedef struct CannonBullet
{
	std::string		szResourceName;
	int				nResType;
	MyPoint			Pos;
	float			fScale;
} CannonNet;

struct CannonSet
{
	int							nTypeID;
	std::vector<CannonPart>		vCannonParts;
	std::vector<CannonBullet>	BulletSet;
	std::vector<CannonNet>		NetSet;
};	

struct CannonSetS
{
	int							nID;
	int							nNormalID;
	int							nIonID;
	int							nDoubleID;
	bool						bRebound;
	std::map<int, CannonSet>	Sets;
};

class CGameConfig : public Singleton <CGameConfig>
{
public:	
	bool LoadSystemConfig(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadFish(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadVisual(std::string szXmlFile, CXMLDecrypt* pcd = NULL);
	
	bool LoadCannonSet(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadBulletSet(std::string szXmlFile, CXMLDecrypt* pcd = NULL);
	bool LoadBoundBox(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadScenes(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadFishSound(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

	bool LoadSpecialFish(std::string szXmlFile, CXMLDecrypt* pcd = NULL);

protected:

	CGameConfig();

	virtual ~CGameConfig();

	FriendBaseSingleton(CGameConfig);

public:
	int							nDefaultWidth;
	int							nDefaultHeight;
	int							nWidth;
	int							nHeight;
	int							nChangeRatioUserScore;
	int							nChangeRatioFishScore;
	int							nExchangeOnce;
	int							nFireInterval;
	int							nMaxInterval;
	int							nMinInterval;
	int							nMinNotice;
	float						fAndroidProbMul;
	int							nPlayerCount;
	int							nSpecialProb[ESFT_MAX];

	std::map<int, Visual>		VisualMap;
	std::map<int, Fish>			FishMap;
	std::vector<Bullet>			BulletVector;
	std::map<int, BBX>			BBXMap;

	int							nAddMulBegin;
	int							nAddMulCur;

	int							m_MaxCannon;

	bool						bImitationRealPlayer;

	std::vector<FirstFire>		FirstFireList;

	float						fHScale;
	float						fVScale;

	std::map<int, SceneSet>		SceneSets;
	std::map<int, SoundSet>		FishSound;

	std::map<int, SpecialSet>	KingFishMap;
	std::map<int, SpecialSet>	SanYuanFishMap;
	std::map<int, SpecialSet>	SiXiFishMap;

	std::vector<CMovePoint>		CannonPos;

	std::vector<CannonSetS>		CannonSetArray;

	std::string					szCannonEffect;
	MyPoint						EffectPos;
	int							nJettonCount;
	MyPoint						JettonPos;
	CannonLock					LockInfo;

	bool						ShowDebugInfo;
	int							nShowGoldMinMul;
	bool						ShowShadow;

	int							nIonMultiply;
	int							nIonProbability;	
	float						fDoubleTime;

	int							nMaxBullet;
	int							nMaxSpecailCount;

	float						fGiveRealPlayTime;
	float						fGiveTime;
	std::vector<int>			vGiveFish;
	std::vector<int>			vGiveProb;

	int							nSnakeHeadType;
	int							nSnakeTailType;
};

#endif

