using System.Data;
using Npgsql;

namespace MakeYourBrain.Infrastructure.Data;

public class DapperConnectionFactory(IConfiguration configuration) : MakeYourBrain.Application.Interfaces.IDbConnectionFactory
{
    private readonly string _connectionString = configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("DefaultConnection is not configured");

    public IDbConnection CreateConnection()
    {
        var conn = new NpgsqlConnection(_connectionString);
        conn.Open();
        return conn;
    }
}

