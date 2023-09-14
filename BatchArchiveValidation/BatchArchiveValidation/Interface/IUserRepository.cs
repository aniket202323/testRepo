using BatchDataLayer.Models;


namespace BatchArchiveValidation.Interface
{
    public interface IUserRepository
    {
        User AuthorizeUser(string DomainUser,string domainUser);
    }
}