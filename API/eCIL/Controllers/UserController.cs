using eCIL.Helper;
using eCIL.Filters;
using System;
using System.Configuration;
using System.Linq;
using System.Net.Http;
using System.Security.Principal;
using System.Threading;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using System.Web.Http.Description;
using User = eCIL_DataLayer.User;

namespace eCIL.Controllers
{
 
    public class UserController : ApiController
    {
        private UserRepository _UserRepository;
        private User _user;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public UserController()
        {
            _UserRepository = new UserRepository();
            _user = new User();
        }
   

        /// <summary>
        /// Authenticate & Authorize a user
        /// </summary>
        /// <param name="user"></param>
        /// <returns></returns>
        // POST api/user
        [HttpPost]
       // [eCILAuthorization]
        [AllowAnonymous]
        [Route("api/user/authenticate")]
        public HttpResponseMessage Authenticate([FromBody] User user)
        {
            
                User result = new User();
                string Domain = user.UserName.Substring(0, 2) + ".pg.com";
                string UserName = user.UserName.Substring(2);
                string DomainUser = Domain + UserName;
                string Password = this.DecodeBase64(user.Password ?? "");
                var LDAPResult = "";
                try
                {
                     LDAPResult = _UserRepository.AutheticateLDAP(UserName, Password);
                }catch(Exception ex)
                {
                    log.Error("Error Authenticate user in LDAP " + ": " + ex.Message + " -- " + ex.StackTrace);
                    return Request.CreateResponse(System.Net.HttpStatusCode.ExpectationFailed, "Incorrect username or password!");
                }
               
                if (LDAPResult == "Success")
                {
                    try
                    {
                        result = _UserRepository.AuthorizeUser(DomainUser);
                    }catch(Exception ex)
                    {
                        log.Error("Error during authoriation: " + ex.Message.ToString() + " -- " + ex.StackTrace);
                        return Request.CreateResponse(System.Net.HttpStatusCode.Unauthorized, ex.Message.ToString());
                    }
                }
                   
                try
                {
                    
                    return Request.CreateResponse(System.Net.HttpStatusCode.OK, result);
                }
                catch (Exception ex)
                {
                    log.Error("Error returning the user details after authorization: " + ex.Message.ToString() + " -- " + ex.StackTrace);
                return Request.CreateResponse(System.Net.HttpStatusCode.ExpectationFailed, ex.Message);
                }
        }


        [ApiExplorerSettings(IgnoreApi = true)]
        [System.Web.Http.HttpGet]
       // [eCILAuthorization]
        [Route("api/user/autologin")]
        public HttpResponseMessage Autologin()
        {
            var aux = User;
            User result = new User();
           

            try
            {
                var shortDomainUsername = HttpContext.Current.Request.LogonUserIdentity.Name;
                var domain = shortDomainUsername.Substring(0, 2).ToLower() + ".pg.com";
                var DomainUser = domain + "\\" + shortDomainUsername.Substring(3);
                return Request.CreateResponse(System.Net.HttpStatusCode.OK, _UserRepository.AuthorizeUser(DomainUser));
            }
            catch (Exception ex)
            {
                log.Error(String.Format("Error during the autologin. Error Message: {0} --- Stack Trace: {1}", ex.Message, ex.StackTrace));
                return Request.CreateResponse(System.Net.HttpStatusCode.Unauthorized, ex.Message);
            }
        }

        [HttpPost]
        [eCILAuthorization]
        [ApiExplorerSettings(IgnoreApi = true)]
        [Route("api/user/opshubautologin")]
        public HttpResponseMessage OpsHubAutologin([FromBody] OpsHubMessage opsHub)
        {
            string jwtToken = opsHub.JwtToken;
            string userNameFromToken = string.Empty;

            if (string.IsNullOrEmpty(jwtToken))
            {
                return Request.CreateResponse(System.Net.HttpStatusCode.Unauthorized, "Token Not Provided");
            }

            try
            {
                string vToken = string.Empty;
                if (jwtToken.Contains("Bearer"))
                {
                    string[] aux = jwtToken.Split(' ');
                    jwtToken = aux[1];
                }

                var handler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
                var token = handler.ReadJwtToken(jwtToken);

                if (token.ValidTo < DateTime.UtcNow)
                {
                    return Request.CreateResponse(System.Net.HttpStatusCode.NotFound, "Token Expired");
                }

                userNameFromToken = token.Claims.Where(x => x.Type == "user_name").First().Value;
            }
            catch (Exception ex)
            {
                log.Error(String.Format("Error during the OpsHub autologin. Error Message: {0} --- Stack Trace: {1}", ex.Message, ex.StackTrace));
                return Request.CreateResponse(System.Net.HttpStatusCode.ExpectationFailed, ex.Message);
            }

            string ntDomain = _UserRepository.getNtDomain(userNameFromToken).ToLower() + ".pg.com";
            string DomainUser = ntDomain + "\\" + userNameFromToken;

            try
            {
                return Request.CreateResponse(System.Net.HttpStatusCode.OK, _UserRepository.AuthorizeUser(DomainUser));
            }
            catch (Exception ex)
            {
                log.Error(String.Format("Error during the OpsHub autologin. Error Message: {0} --- Stack Trace: {1}", ex.Message, ex.StackTrace));
                return Request.CreateResponse(System.Net.HttpStatusCode.ExpectationFailed, ex.Message);
            }
        }

        #region Utilities
        [ApiExplorerSettings(IgnoreApi = true)]
        public string DecodeBase64(string text = "")
        {
            try
            {
                return System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(text));
            }
            catch (Exception ex)
            {
                log.Error("Error decoding password: " + ex.Message.ToString());
                return "Error decoding password";
            }
        }
        #endregion

    }
}
