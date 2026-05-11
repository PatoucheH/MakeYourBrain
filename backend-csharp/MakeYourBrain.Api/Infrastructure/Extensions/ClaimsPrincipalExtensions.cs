using System.Security.Claims;

namespace MakeYourBrain.Api.Infrastructure.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        var sub = user.FindFirstValue(ClaimTypes.NameIdentifier)
               ?? user.FindFirstValue("sub")
               ?? throw new UnauthorizedAccessException("User ID claim not found");
        return Guid.Parse(sub);
    }

    public static bool IsServiceRole(this ClaimsPrincipal user)
        => user.FindFirstValue(ClaimTypes.Role) == "service_role"
        || user.FindFirstValue("role") == "service_role";
}
