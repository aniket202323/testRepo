using BatchArchiveValidation.Helper;
using BatchDataLayer.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Web;
using System.Web.Http;
using System.Web.Http.Description;

namespace BatchArchiveValidation.Controllers
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

        [HttpPost]
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
            }
            catch (Exception ex)
            {
                log.Error("Error Authenticate user in LDAP " + ": " + ex.Message + " -- " + ex.StackTrace);
                return Request.CreateResponse(System.Net.HttpStatusCode.ExpectationFailed, "Incorrect username or password!");
            }

            if (LDAPResult == "Success")
            {
                try
                {
                    result = _UserRepository.AuthorizeUser(DomainUser, UserName);
                }
                catch (Exception ex)
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

    }
}