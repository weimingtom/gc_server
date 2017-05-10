#pragma once
#include <boost/random.hpp>
#include <boost/random/random_device.hpp>
#include <mutex>
#include <random>

class RandomHelper
{
public:
    static int Random(int min, int max)
	{
		static boost::random::mt19937 gen(::GetTickCount());
		static std::recursive_mutex gen_lock;
		boost::uniform_int<> un(min, max);
		std::lock_guard<std::recursive_mutex> l(gen_lock);
		return un(gen);
    }
	static int RandomEx(int min1, int max1, int prob, int min2, int max2)
	{
		if (Random(1, 100) <= prob) {
			return Random(min2, max2);
		}
		return Random(min1, max1);
	}
	// 修改为int64_t类型，而不再是uint64_t类型
	static int64_t Random64(int64_t min, int64_t max)
	{
		typedef boost::random::linear_congruential<long long, 16807, 0, 9223372036854775807> randint64;
		typedef boost::uniform_int<long long> uniform_longlong;
		typedef boost::random::variate_generator<randint64, uniform_longlong> uniform_randint64;

        static randint64 engine(::GetTickCount()); // initialised using default value of 1 as seed
		static std::recursive_mutex gen_lock;
		uniform_longlong distribution(min, max); // initialised with min, max values
		uniform_randint64 prng(engine, distribution);
		std::lock_guard<std::recursive_mutex> l(gen_lock);
		return prng();
	}

	static int randomNumberEx(int min, int max)
	{
		std::default_random_engine randomEngine{ std::random_device()() };
		return std::uniform_int_distribution<int>(min, max)(randomEngine);
	}

	/// \fn	static float random_01()
	///
	/// \brief	产生一个范围0-1之间的float类型的随机值
	///
	/// \author	lik
	/// \date	2016-05-30 18:11
	///
	/// \return	生成的随机值
	static float random_01()
	{
        static boost::random::mt19937 gen(::GetTickCount());
		static std::recursive_mutex gen_lock;
		static boost::uniform_01<boost::mt19937&> u01(gen);
		static boost::normal_distribution<float> nd(0, 1);
		std::lock_guard<std::recursive_mutex> l(gen_lock);
		return nd(u01);
	}
	
	/// \brief	产生指定范围内的float类型随机值
	///
	/// \author	lik
	/// \date	2016-05-30 18:10
	///
	/// \param	min_val	最小值
	/// \param	max_val	最大值
	///
	/// \return	生成的随机值
	static float random_float(float min_val, float max_val)
	{
        static boost::random::mt19937 gen(::GetTickCount());
		static std::recursive_mutex gen_lock;
		boost::uniform_real<float> real(min_val, max_val);
		std::lock_guard<std::recursive_mutex> l(gen_lock);
		return real(gen);
	}
	
	/// \brief	产生一个范围0-1之间的double类型的随机值
	///
	/// \author	lik
	/// \date	2016-05-30 18:07
	///
	/// \return	生成的随机值
	static double random_double_01()
	{
// 		static boost::random::mt19937 gen;
// 		static std::recursive_mutex gen_lock;
// 		static boost::uniform_01<boost::mt19937&> u01(gen);
// 		static boost::normal_distribution<unsigned double> nd(0, 1);
// 		std::lock_guard<std::recursive_mutex> l(gen_lock);
// 		return nd(u01);
		//return random_double(0.00010, 1.00010);

		return static_cast<double>(Random(0, 10000)) / 10000.0;
	}
	
	/// \brief	产生指定范围内的double类型随机值
	///
	/// \author	lik
	/// \date	2016-05-30 18:09
	///
	/// \param	min_val	最小值
	/// \param	max_val	最大值
	///
	/// \return	生成的随机值
	static double random_double(double min_val, double max_val)
	{
        static boost::random::mt19937 gen(::GetTickCount());
		static std::recursive_mutex gen_lock;
		boost::uniform_real<double> real(min_val, max_val);
		std::lock_guard<std::recursive_mutex> l(gen_lock);
		return real(gen);
	}
};
