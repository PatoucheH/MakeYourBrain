using System.Data;

namespace MakeYourBrain.Application.Interfaces;

public interface IDbConnectionFactory
{
    IDbConnection CreateConnection();
}
