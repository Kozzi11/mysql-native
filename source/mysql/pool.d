﻿/++
A lightweight interface to a MySQL/MariaDB  database using vibe.d's
$(LINK2 http://vibed.org/api/vibe.core.connectionpool/ConnectionPool, ConnectionPool).

You have to include vibe.d in your project to be able to use this class.
If you don't want to, refer to `mysql.connection.Connection`.

This provides various benefits over creating a new Connection manually,
such as automatically reusing old connections, and automatic cleanup (no need to close
the connection when done).
+/
module mysql.pool;

import std.conv;
import mysql.connection;
import mysql.protocol.constants;

version(Have_vibe_d_core) version = IncludeMySqlPool;
version(MySQLDocs)        version = IncludeMySqlPool;

version(IncludeMySqlPool)
{
	version(Have_vibe_d_core)
		import vibe.core.connectionpool;
	else
	{
		/++
		Vibe.d's
		$(LINK2 http://vibed.org/api/vibe.core.connectionpool/ConnectionPool, ConnectionPool)
		class.

		Not actually included in module mysql.pool. Only listed here for
		documentation purposes. For ConnectionPool and it's documentation, see:
		$(LINK http://vibed.org/api/vibe.core.connectionpool/ConnectionPool)
		+/
		class ConnectionPool(T)
		{
			/// See: http://vibed.org/api/vibe.core.connectionpool/ConnectionPool.this
			this(Connection delegate() connection_factory, uint max_concurrent = (uint).max)
			{}

			/// See: http://vibed.org/api/vibe.core.connectionpool/ConnectionPool.lockConnection
			LockedConnection!T lockConnection() { return LockedConnection!T(); }
		}

		/++
		Vibe.d's
		$(LINK2 http://vibed.org/api/vibe.core.connectionpool/LockedConnection, LockedConnection)
		struct.

		Not actually included in module mysql.pool. Only listed here for
		documentation purposes. For LockedConnection and it's documentation, see:
		$(LINK http://vibed.org/api/vibe.core.connectionpool/LockedConnection)
		+/
		struct LockedConnection(Connection) {}
	}

	/++
	A lightweight interface to a MySQL/MariaDB  database using vibe.d's
	$(LINK2 http://vibed.org/api/vibe.core.connectionpool/ConnectionPool, ConnectionPool).

	You have to include vibe.d in your project to be able to use this class.
	If you don't want to, refer to `mysql.connection.Connection`.
	+/
	class MySqlPool {
		private {
			string m_host;
			string m_user;
			string m_password;
			string m_database;
			ushort m_port;
			SvrCapFlags m_capFlags;
			ConnectionPool!Connection m_pool;
		}

		/// Sets up a connection pool with the provided connection settings.
		this(string host, string user, string password, string database, ushort port = 3306, SvrCapFlags capFlags = defaultClientFlags)
		{
			m_host = host;
			m_user = user;
			m_password = password;
			m_database = database;
			m_port = port;
			m_capFlags = capFlags;
			m_pool = new ConnectionPool!Connection(&createConnection);
		}

		///ditto
		this(string connStr, SvrCapFlags capFlags = defaultClientFlags)
		{
			auto parts = Connection.parseConnectionString(connStr);
			this(parts[0], parts[1], parts[2], parts[3], to!ushort(parts[4]), capFlags);
		}

		/++
		Obtain a connection. If one isn't available, a new one will be created.

		The connection returned is actually a `LockedConnection!Connection`,
		but it uses `alias this`, and so can be used just like a Connection.
		(See vibe.d's
		$(LINK2 http://vibed.org/api/vibe.core.connectionpool/LockedConnection, LockedConnection documentation).)

		No other fiber will be given this Connection as long as your fiber still holds it.

		There is no need to close, release or "unlock" this connection. It is
		reference-counted and will automatically be returned to the pool once
		your fiber is done with it.
		+/
		auto lockConnection() { return m_pool.lockConnection(); }

		private Connection createConnection()
		{
			return new Connection(m_host, m_user, m_password, m_database, m_port, m_capFlags);
		}
	}
}
