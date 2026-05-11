using Microsoft.AspNetCore.Identity;

namespace MakeYourBrain.Api.Models.Entities;

public class ApplicationUser : IdentityUser<Guid>
{
    public string PreferredLanguage { get; set; } = "en";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
