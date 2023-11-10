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
    public class eCILAuthorizationAttribute : AuthorizeAttribute, System.Web.Mvc.Filters.IAuthenticationFilter
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

                if (jwtToken.Issuer.Equals("eCIL"))
                {
                    var key = Encoding.ASCII.GetBytes(ConfigurationManager.AppSettings["Secret"]);
                    validationParameters.IssuerSigningKey = new SymmetricSecurityKey(key);
                    validationParameters.ValidateAudience = false;
                    validationParameters.ValidateIssuer = false;
                    SecurityTokenHandler handler = new JwtSecurityTokenHandler();
                    SecurityToken token;
                    handler.ValidateToken(tokenString, validationParameters, out token);
                }
                else
                {
                    throw new Exception("Invalid token. Authentication failed!");
                }
            }
            catch(Exception ex)
            {
                filterContext.Response = new HttpResponseMessage();
                filterContext.Response.StatusCode = HttpStatusCode.Unauthorized;
                filterContext.Response.Content = new StringContent("Authentication failed!");
                throw new Exception("Invalid token. Authentication failed!");
                //return;
            }
        }
    }
}

/*
 * 

For anyone that is looking for a quick method to validate RS256 with a public key that has "-----BEGIN PUBLIC KEY-----"/"-----END PUBLIC KEY------"

Here are two methods with the help of BouncyCastle.

    public bool ValidateJasonWebToken(string fullKey, string jwtToken)
    {
        try
        {
            var rs256Token = fullKey.Replace("-----BEGIN PUBLIC KEY-----", "");
            rs256Token = rs256Token.Replace("-----END PUBLIC KEY-----", "");
            rs256Token = rs256Token.Replace("\n", "");

            Validate(jwtToken, rs256Token);
            return true;
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            return false;
        }
    }

    private void Validate(string token, string key)
    {
        var keyBytes = Convert.FromBase64String(key); // your key here

        AsymmetricKeyParameter asymmetricKeyParameter = PublicKeyFactory.CreateKey(keyBytes);
        RsaKeyParameters rsaKeyParameters = (RsaKeyParameters)asymmetricKeyParameter;
        RSAParameters rsaParameters = new RSAParameters
        {
            Modulus = rsaKeyParameters.Modulus.ToByteArrayUnsigned(),
            Exponent = rsaKeyParameters.Exponent.ToByteArrayUnsigned()
        };
        using (RSACryptoServiceProvider rsa = new RSACryptoServiceProvider())
        {
            rsa.ImportParameters(rsaParameters);
            var validationParameters = new TokenValidationParameters()
            {
                RequireExpirationTime = false,
                RequireSignedTokens = true,
                ValidateAudience = false,
                ValidateIssuer = false,
                IssuerSigningKey = new RsaSecurityKey(rsa)
            };
            var handler = new JwtSecurityTokenHandler();
            var result = handler.ValidateToken(token, validationParameters, out var validatedToken);
        }
    }*/