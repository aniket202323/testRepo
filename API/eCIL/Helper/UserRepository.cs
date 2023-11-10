using eCIL.Interfaces;
using eCIL_DataLayer;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.DirectoryServices.Protocols;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Net;
using System.Security.Claims;
using System.Text;
using System.Threading;
using System.Web;
using System.Web.Script.Serialization;

namespace eCIL.Helper
{
    public class UserRepository : IUserRepository
    {
        private eCIL_DataLayer.User User;
        public UserRepository()
        {
            User = new User();
        }

        //Authentication with LDAP
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
                    //con.SessionOptions.VerifyServerCertificate = new VerifyServerCertificateCallback(ServerCallback);
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

        public string getNtDomain(string ShortName)
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
                    "extNTDomain");

                    SearchResponse re = (SearchResponse)con.SendRequest(r);

                    if (re.Entries.Count > 0)
                        foreach (SearchResultEntry entry in re.Entries)
                        {
                            TNumber = entry.Attributes["extNTDomain"][0].ToString();

                        }

                }
                catch
                {
                    throw new HttpException("Can not connect to authentication server");
                }
            }
            return TNumber;
        }


        public eCIL_DataLayer.User AuthorizeUser(string domainUser)
        {
            if (!domainUser.Contains("\\"))
                throw new Exception("You need to specify the domain name and username.");
            User user = new User();
            try
            {
                user = User.GetUserInfos(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], domainUser);
            }
            catch
            {
                throw new Exception("You don't have access to eCIL.");
            }

            //return null if user not found
            if (user.UserName == null)
                throw new Exception("You don't have access to eCIL.");

            //authentication successful so generate jwt token
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
            tokenDescriptor.Issuer = "eCIL";

            var token = tokenHandler.CreateToken(tokenDescriptor);
            user.Token = tokenHandler.WriteToken(token);
            user.SessionTimeout = Convert.ToInt32(ConfigurationManager.AppSettings["SessionTimeout"]);
            user.EDHToken = System.Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(ConfigurationManager.AppSettings["LDAPUsername"] + ":" + ConfigurationManager.AppSettings["LDAPPassword"]));

            // Get eDH token (secure)
            user.EDHAccessToken = getEDHAccessToken(user.UserName);

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

        public string getEDHAccessToken(string username)
        {
            using (WebClient webClient = new WebClient())
            {
                string token = "";

                var eDHWebService = ConfigurationManager.ConnectionStrings["eDHWebService"].ConnectionString.Replace("CIL", "User");
                webClient.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";

                var reqParam = new System.Collections.Specialized.NameValueCollection();
                reqParam.Add("Username", username);
                reqParam.Add("ClientKey", "eDefects-PeCIL");

                try
                {
                    var data = webClient.UploadValues(eDHWebService + "Authorize", "POST", reqParam);
                    var response = Encoding.UTF8.GetString(data);

                    var jss = new JavaScriptSerializer();
                    Dictionary<string, string> serializeResponse = jss.Deserialize<Dictionary<string, string>>(response);

                    if (serializeResponse.Count() > 0)
                    {
                        token = serializeResponse["Token"];
                    }
                }
                catch
                {
                    //throw new Exception("You don't have access to eDH");
                    return token;
                }

                return token;
            }
        }

        /// <summary>
        /// Check the token
        /// </summary>
        /// <param name="jwtToken"></param>
        /// <returns>-2 - token is expired;  -1 token is not a jwt token;  > 0 global access user for the user</returns>
        public int CheckJwtToken(string jwtToken)
        {
            try
            {
                var handler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
                var token = handler.ReadJwtToken(jwtToken);
                if (token.ValidTo < DateTime.UtcNow)
                    return -2;
                return Int32.Parse(token.Claims.Where(x => x.Type == "role").First().Value);
            }
            catch
            {
                return -1;

            }
        }

        public int GetUserIdFromToken(string jwtToken)
        {
            try
            {
                var handler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
                var token = handler.ReadJwtToken(jwtToken);
                if (token.ValidTo < DateTime.UtcNow)
                    return -2;
                return Int32.Parse(token.Claims.Where(x => x.Type == "unique_name").First().Value);
            }
            catch
            {
                return -1;

            }
        }

    }
}