using BatchArchiveValidation.Interface;
using BatchDataLayer.Models;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading;
using System.Web;
using System.DirectoryServices.Protocols;
using System.Net;
using BatchDataLayer;

namespace BatchArchiveValidation.Helper
{
    public class UserRepository : IUserRepository
    {
        public User AuthorizeUser(string DomainUser,string userName)
        {
            if (!DomainUser.Contains("\\"))
                throw new Exception("You need to specify the domain name and username.");
            UserData userData = new UserData();
            User user = new User();
            UserAuth userAuth = new UserAuth();
           // bool validUser ;
            string userId = userName.Replace("\\", "");
            try
            {
                userAuth = userData.AuthorizeUser(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], DomainUser);
            }
            catch(Exception ex)
            {
                throw new Exception("You don't have access to batch archive.");
            }

            //return null if user not found
            if (!userAuth.Authstatus)
                throw new Exception("You don't have access to batch archive.");

            //authentication successful so generate jwt token
            user.UserName = userId;           
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(ConfigurationManager.AppSettings["Secret"]);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new Claim[]
                {
                    new Claim(ClaimTypes.Name, user.User_Id.ToString()),
                    new Claim(ClaimTypes.Role, user.GlobalAccessLevel.ToString())
                }),
                Expires = DateTime.UtcNow.AddDays(Double.Parse(ConfigurationManager.AppSettings["ApiExpirePeriodinDays"])),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };
            var token = tokenHandler.CreateToken(tokenDescriptor);
            user.Token = tokenHandler.WriteToken(token);
            user.SessionTimeout = Convert.ToInt32(ConfigurationManager.AppSettings["SessionTimeout"]);
            user.GlobalAccessLevel = Convert.ToInt32(userAuth.AccessLevel);

            //Add user details in identity
            var identity = new ClaimsIdentity(HttpContext.Current.User.Identity);
            identity.Actor = new ClaimsIdentity();
            identity.Actor.AddClaim(new Claim(ClaimTypes.Name, user.UserName.ToString()));
            identity.Actor.AddClaim(new Claim(ClaimTypes.Role, user.GlobalAccessLevel.ToString()));

            var principal = new ClaimsPrincipal(identity);
            Thread.CurrentPrincipal = principal;
            HttpContext.Current.User = Thread.CurrentPrincipal;
            return user;
        }

        public string AutheticateLDAP(string username, string password)
        {
            // check the user has provided both username AND password 
            if (username != "" && password != "")   
            {

                string shortName = username.Replace("\\", "");
                string Tnum = getTnumberLDAP(shortName);
                bool loginSuccess = true;
                using (LdapConnection con = new LdapConnection(new LdapDirectoryIdentifier(ConfigurationManager.AppSettings["LDAPDomain"], Int32.Parse(ConfigurationManager.AppSettings["LDAPPort"]))))
                {
                    con.SessionOptions.SecureSocketLayer = false;                    
                    string DN = String.Format("uid = {0}, ou = people, ou = pg, o = world", Tnum);
                    con.Credential = new NetworkCredential(DN, password);
                    con.AuthType = AuthType.Basic;
                    try
                    {
                        con.Bind();
                        loginSuccess = true;
                    }
                    catch (Exception ex)
                    {
                        //49 - invalid credentials
                        //81 LDap Server is unavalilable || port incorrect
                        if (ex.HResult == 49)
                            return "Invalid credentials";
                        else if (ex.HResult == 81)
                            return "LDAP Server is unavailable. Please check the port.";

                        throw new HttpException("Invalid Username and Password");
                    }
                }
                if (loginSuccess)
                {
                    return "Success";
                }
                else
                {
                    throw new HttpException("Your connection can not be established");
                }
            }
            else
            {
                throw new HttpException("You need to enter username and password");
            }
        }

        private string getTnumberLDAP(string ShortName)
        {
            string TNumber = null;
            using (LdapConnection con = new LdapConnection(new LdapDirectoryIdentifier(ConfigurationManager.AppSettings["LDAPDomain"], Int32.Parse(ConfigurationManager.AppSettings["LDAPPort"]))))
            {
                con.SessionOptions.SecureSocketLayer = false;
                con.SessionOptions.ProtocolVersion = 3;
                //con.SessionOptions.VerifyServerCertificate = new VerifyServerCertificateCallback(ServerCallback);
                con.Credential = new NetworkCredential(ConfigurationManager.AppSettings["LDAPUsername"], ConfigurationManager.AppSettings["LDAPPassword"]);
                con.AuthType = AuthType.Basic;
                try
                {
                    con.Bind();
                    SearchRequest r = new SearchRequest(

                    //Base DN
                    "ou = people, ou = pg, o = world",

                    //Filter
                    "(extshortname=" + ShortName + ")",

                    //Search scope
                    SearchScope.Subtree,

                    //params string [] of attributes... in this case all
                    "uid");

                    SearchResponse re = (SearchResponse)con.SendRequest(r);

                    if (re.Entries.Count > 0)
                        foreach (SearchResultEntry entry in re.Entries)
                        {
                            TNumber = entry.Attributes["uid"][0].ToString();

                        }

                }
                catch
                {
                    throw new HttpException("Can not connect to authentication server");
                }
            }
            return TNumber;
        }

    }
}