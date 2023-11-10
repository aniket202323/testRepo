namespace eCIL.Interfaces
{
    public interface IUserRepository
    {
        //eCIL_DataLayer.User AutheticateLDAP(string username, string password);
        string AutheticateLDAP(string username, string password);
        eCIL_DataLayer.User AuthorizeUser(string domainUser);
    }
}
