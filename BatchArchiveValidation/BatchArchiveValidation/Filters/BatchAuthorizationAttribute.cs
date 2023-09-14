using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Mvc.Filters;

namespace eCIL.Filters
{
    //[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
    public class BatchAuthorizationAttribute : AuthorizeAttribute, System.Web.Mvc.Filters.IAuthenticationFilter
    {
        public void OnAuthentication(AuthenticationContext filterContext)
        {
            throw new NotImplementedException();
        }

        public void OnAuthenticationChallenge(AuthenticationChallengeContext filterContext)
        {
            throw new NotImplementedException();
        }

        override public void OnAuthorization(HttpActionContext filterContext)
        {
            try
            {
                String tokenString = filterContext.Request.Headers.GetValues("AuthToken").First();
                JwtSecurityToken jwtToken = new JwtSecurityToken(tokenString);
                TokenValidationParameters validationParameters = new TokenValidationParameters();
                
                var key = Encoding.ASCII.GetBytes(ConfigurationManager.AppSettings["Secret"]);
                validationParameters.IssuerSigningKey = new SymmetricSecurityKey(key);
                validationParameters.ValidateAudience = false;
                validationParameters.ValidateIssuer = false;
                SecurityTokenHandler handler = new JwtSecurityTokenHandler();
                SecurityToken token;
                handler.ValidateToken(tokenString, validationParameters, out token);
                
            }
            catch (Exception ex)
            {
                filterContext.Response = new HttpResponseMessage();
                filterContext.Response.StatusCode = HttpStatusCode.Unauthorized;
                filterContext.Response.Content = new StringContent("Authentication failed!");
                return;
            }
        }
    }
}

