using BatchDataLayer.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace BatchDataLayer
{
    public class UserData
    {

        UserAuth userAuthResult = new UserAuth();
        public UserAuth AuthorizeUser(string _connectionString, string user)
        {
           
            string result = string.Empty;
            string result1 = string.Empty;
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
               UserAuth userAuth = new UserAuth();
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_BDATUserAuthorization_Phase2", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                SqlParameter IsActiveUser = new SqlParameter("@IsActiveUser", SqlDbType.VarChar, 1);
                SqlParameter AccessLevel = new SqlParameter("@AccessLevel", SqlDbType.VarChar, 1);
                IsActiveUser.Direction = ParameterDirection.Output;
                AccessLevel.Direction = ParameterDirection.Output;

                command.Parameters.Add(new SqlParameter("@UserName", user));
                command.Parameters.Add(IsActiveUser);
                command.Parameters.Add(AccessLevel);
                command.ExecuteNonQuery();
                result = command.Parameters["@IsActiveUser"].Value.ToString();
                if (String.Equals(result, "1"))
                {
                    userAuth.Authstatus = true;
                }                                  
                
                userAuth.AccessLevel = command.Parameters["@AccessLevel"].Value.ToString();
                userAuthResult = userAuth;
                conn.Close();
            }
          
            return userAuthResult;
        }
    }
}