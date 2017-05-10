#include "DBConnection.h"
#include "GameLog.h"

DBConnection::DBConnection()
	: con_(nullptr)
	, stmt_(nullptr)
{
}

DBConnection::~DBConnection()
{
	close();
}

void DBConnection::connect(const std::string& host, const std::string& user, const std::string& password, const std::string& database)
{
	sql::Driver* driver = get_driver_instance();

	sql::ConnectOptionsMap opt;
	opt.insert(std::make_pair("hostName", sql::Variant(sql::SQLString(host.c_str()))));
	opt.insert(std::make_pair("userName", sql::Variant(sql::SQLString(user.c_str()))));
	opt.insert(std::make_pair("password", sql::Variant(sql::SQLString(password.c_str()))));
	opt.insert(std::make_pair("schema", sql::Variant(sql::SQLString(database.c_str()))));
	opt.insert(std::make_pair("OPT_RECONNECT", sql::Variant(true)));
	opt.insert(std::make_pair("OPT_CHARSET_NAME", sql::Variant(sql::SQLString("utf8"))));
	
	con_ = driver->connect(opt);

	stmt_ = con_->createStatement();
}

void DBConnection::close()
{
	if (stmt_)
	{
		delete stmt_;
		stmt_ = nullptr;
	}
	if (con_)
	{
		con_->close();
		delete con_;
		con_ = nullptr;
	}
}

void DBConnection::execute(const std::string& sql)
{
	try
	{
		stmt_->execute(sql.c_str());
	}
	catch (const sql::SQLException& e)
	{
		LOG_ERR("%s err[%d]:%s, %s", sql.c_str(), e.getErrorCode(), e.what(), e.getSQLStateCStr());
	}
}

int DBConnection::execute_update(const std::string& sql)
{
	try
	{
		return stmt_->executeUpdate(sql.c_str());
	}
	catch (const sql::SQLException& e)
	{
		LOG_ERR("%s err[%d]:%s, %s", sql.c_str(), e.getErrorCode(), e.what(), e.getSQLStateCStr());
	}

	return 0;
}

int DBConnection::execute_try(const std::string& sql)
{
	try
	{
		stmt_->execute(sql.c_str());
	}
	catch (const sql::SQLException& e)
	{
		return e.getErrorCode();
	}

	return 0;
}

int DBConnection::execute_update_try(const std::string& sql, int& ret)
{
	try
	{
		ret = stmt_->executeUpdate(sql.c_str());
	}
	catch (const sql::SQLException& e)
	{
		return e.getErrorCode();
	}

	return 0;
}

bool DBConnection::execute_query_string(std::vector<std::string>& output, const std::string& sql)
{
	try
	{
		std::unique_ptr<sql::ResultSet> res(stmt_->executeQuery(sql));

		bool ret = false;
		do
		{
			if (res->rowsCount() > 0)
			{
				sql::ResultSetMetaData* res_meta = res->getMetaData();

				int numcols = res_meta->getColumnCount();
				if (numcols <= 0)
					break;

				bool bFirst = true;

				while (res->next())
				{
					if (!bFirst)
						break;
					bFirst = false;

					for (int i = 0; i < numcols; ++i)
					{
						output.push_back(res->getString(i + 1));
					}
				}

				ret = true;
			}
		} while (false);

		while (stmt_->getMoreResults());

		return ret;
	}
	catch (const sql::SQLException& e)
	{
		LOG_ERR("%s err[%d]:%s, %s", sql.c_str(), e.getErrorCode(), e.what(), e.getSQLStateCStr());
	}

	return false;
}

bool DBConnection::execute_query_vstring(std::vector<std::vector<std::string>>& output, const std::string& sql)
{
	try
	{
		std::unique_ptr<sql::ResultSet> res(stmt_->executeQuery(sql));

		bool ret = false;
		do
		{
			if (res->rowsCount() > 0)
			{
				sql::ResultSetMetaData* res_meta = res->getMetaData();

				int numcols = res_meta->getColumnCount();
				if (numcols <= 0)
					break;

				while (res->next())
				{
					std::vector<std::string> item;
					for (int i = 0; i < numcols; ++i)
					{
						item.push_back(res->getString(i + 1));
					}

					output.push_back(item);
				}

				ret = true;
			}
		} while (false);

		while (stmt_->getMoreResults());

		return ret;
	}
	catch (const sql::SQLException& e)
	{
		LOG_ERR("%s err[%d]:%s, %s", sql.c_str(), e.getErrorCode(), e.what(), e.getSQLStateCStr());
	}

	return false;
}

bool DBConnection::execute_query(std::string& output, const std::string& sql, const std::string& name)
{
	try
	{
		std::unique_ptr<sql::ResultSet> res(stmt_->executeQuery(sql));

		bool ret = false;
		do 
		{
			if (res->rowsCount() > 0)
			{
				sql::ResultSetMetaData* res_meta = res->getMetaData();

				int numcols = res_meta->getColumnCount();
				if (numcols <= 0)
					break;

				bool bFirst = true;
				std::stringstream ss;

				while (res->next())
				{
					if (name.empty() && !bFirst)
						break;
					bFirst = false;

					if (!name.empty())
					{
						ss << name << " {\n";
					}

					for (int i = 0; i < numcols; ++i)
					{
						ss << res_meta->getColumnLabel(i + 1) << ":";
						if (res_meta->isNumeric(i + 1))
						{
							ss << res->getString(i + 1);
						}
						else
						{
							ss << "\"" << res->getString(i + 1) << "\"";
						}
						ss << std::endl;

					}

					if (!name.empty())
					{
						ss << "}\n";
					}

				}

				output = ss.str();
				ret = true;
			}
		} while (false);
	
		while (stmt_->getMoreResults());

		return ret;
	}
	catch (const sql::SQLException& e)
	{
		LOG_ERR("%s err[%d]:%s, %s", sql.c_str(), e.getErrorCode(), e.what(), e.getSQLStateCStr());
	}

	return false;
}

bool DBConnection::execute_query_filter(std::string& output, const std::string& sql, const std::string& name,
	const std::function<bool(const std::string&)>& filter_func)
{
	try
	{
		std::unique_ptr<sql::ResultSet> res(stmt_->executeQuery(sql));

		bool ret = false;
		do
		{
			if (res->rowsCount() > 0)
			{
				sql::ResultSetMetaData* res_meta = res->getMetaData();

				int numcols = res_meta->getColumnCount();
				if (numcols <= 0)
					break;

				bool bFirst = true;
				std::stringstream ss;

				while (res->next())
				{
					if (name.empty() && !bFirst)
						break;
					bFirst = false;

					if (!name.empty())
					{
						ss << name << " {\n";
					}

					for (int i = 0; i < numcols; ++i)
					{
						std::string label = res_meta->getColumnLabel(i + 1);

						if (filter_func(label))
						{
							std::string str = res->getString(i + 1);
							if (!str.empty())
							{
								ss << label << " {\n" << str << "\n}\n";
							}
						}
						else
						{
							ss << label << ":";
							if (res_meta->isNumeric(i + 1))
							{
								ss << res->getString(i + 1);
							}
							else
							{
								ss << "\"" << res->getString(i + 1) << "\"";
							}
						}
						ss << std::endl;

					}

					if (!name.empty())
					{
						ss << "}\n";
					}

				}

				output = ss.str();
				ret = true;
			}
		} while (false);

		while (stmt_->getMoreResults());

		return ret;
	}
	catch (const sql::SQLException& e)
	{
		LOG_ERR("%s err[%d]:%s, %s", sql.c_str(), e.getErrorCode(), e.what(), e.getSQLStateCStr());
	}

	return false;
}

bool DBConnection::execute_query_lua(std::string& output, bool b_more, const std::string& sql)
{
	try
	{
		std::unique_ptr<sql::ResultSet> res(stmt_->executeQuery(sql));

		bool ret = false;
		do
		{
			if (res->rowsCount() > 0)
			{
				sql::ResultSetMetaData* res_meta = res->getMetaData();

				int numcols = res_meta->getColumnCount();
				if (numcols <= 0)
					break;

				bool bFirst = true;
				std::stringstream ss;

				if (b_more)
				{
					ss << "{";
				}

				while (res->next())
				{
					if (!b_more && !bFirst)
						break;
					if (bFirst)
						ss << "{";
					else
						ss << ",{";
					bFirst = false;

					for (int i = 0; i < numcols; ++i)
					{
						std::string label = res_meta->getColumnLabel(i + 1);

						ss << label << "=";
						if (res_meta->isNumeric(i + 1))
						{
							if (res_meta->getColumnType(i + 1) == sql::DataType::INTEGER)
								ss << "'" << res->getString(i + 1) << "'";
							else
								ss << res->getString(i + 1);
						}
						else
						{
							ss << "[[" << res->getString(i + 1) << "]]";
						}
						ss << ",";
					}

					ss << "}";
				}

				if (b_more)
				{
					ss << "}";
				}
				output = ss.str();
				ret = true;
			}
		} while (false);

		while (stmt_->getMoreResults());

		return ret;
	}
	catch (const sql::SQLException& e)
	{
		LOG_ERR("%s err[%d]:%s, %s", sql.c_str(), e.getErrorCode(), e.what(), e.getSQLStateCStr());
	}

	return false;
}
