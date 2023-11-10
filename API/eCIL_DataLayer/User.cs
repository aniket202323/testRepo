using eCIL_DataLayer;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Text;
using static eCIL_DataLayer.Utilities;

namespace eCIL_DataLayer
{
    public class User
    {
        #region Variables
        private string userName;
        private string password;
        private int user_Id;
        private int languageId;
        private int globalAccessLevel;
        private Dictionary<int, int> lineAccessLevel;
        private string sapUserName;
        private string sapPassword;
        private string token;
        private int sessionTimeout;
        private string eDHToken;
        private string eDHAccessToken;
        //User Access Level
        public enum AccessLevel
        {
            None = 0,
            Read = 1,
            ReadWrite = 2,
            Manager = 3,
            Admin = 4
        }

        //Languages
        public enum Languages
        {
            English = 0,
            French = 1,
            German = 2,
            Danish = 3,
            Spanish = 5,
            Swedish = 6,
            Italian = 7,
            Polish = 8,
            Russian = 9,
            Dutch = 10,
            Portuguese = 12,
            Chinese = 13,
            Japanese = 14,
            Turkish = 16,
            Arabic = 18
        }
        #endregion

        #region Properties
        public string UserName { get => userName; set => userName = value; }
        public string Password { get => password; set => password = value; }
        public int User_Id { get => user_Id; set => user_Id = value; }
        public int LanguageId { get => languageId; set => languageId = value; }
        public int GlobalAccessLevel { get => globalAccessLevel; set => globalAccessLevel = value; }
        public Dictionary<int, int> LineAccessLevel { get => lineAccessLevel; set => lineAccessLevel = value; }
        public string SapUserName { get => sapUserName; set => sapUserName = value; }
        public string SapPassword { get => sapPassword; set => sapPassword = value; }
        public string Token { get => token; set => token = value; }
        public int SessionTimeout { get => sessionTimeout; set => sessionTimeout = value; }
        public string EDHToken { get => eDHToken; set => eDHToken = value; }
        public string EDHAccessToken { get => eDHAccessToken; set => eDHAccessToken = value; }
        #endregion


        #region Methods
        public  User GetUserInfos(string _connectionString, string DomainUsername)
        {
            User eCILUser = new User();

            SqlParameter ErrorMessageParam = new SqlParameter();
            ErrorMessageParam.Value = string.Empty;
            ErrorMessageParam.DbType = System.Data.DbType.String;
            ErrorMessageParam.Direction = System.Data.ParameterDirection.Output;
            ErrorMessageParam.ParameterName = "@ErrorMessage";

            SqlParameter WindowsUserInfoParam = new SqlParameter();
            WindowsUserInfoParam.Value = DomainUsername;
            WindowsUserInfoParam.DbType = System.Data.DbType.String;
            WindowsUserInfoParam.Direction = System.Data.ParameterDirection.Input;
            WindowsUserInfoParam.ParameterName = "@WindowsUserInfo";


            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetUserInfos", conn);
                command.CommandText = "spLocal_eCIL_GetUserInfos";
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(WindowsUserInfoParam);
                command.Parameters.Add(ErrorMessageParam);

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        eCILUser.User_Id = reader.GetInt32(reader.GetOrdinal("User_Id"));
                        eCILUser.UserName = reader.GetString(reader.GetOrdinal("Username"));
                        eCILUser.LanguageId = reader.GetInt32(reader.GetOrdinal("Language_Id"));
                        eCILUser.GlobalAccessLevel = reader.GetInt32(reader.GetOrdinal("GlobalAccessLevel"));
                    }
                    reader.NextResult();

                    //check if reader has more informations from database
                    //if yes, we will add all informations about accesslevel for each line in a dictionary
                    if (reader.Read())
                    {
                        eCILUser.LineAccessLevel = new Dictionary<int, int>();
                        while (reader.Read())
                        {
                            var pl_id = reader.GetInt32(reader.GetOrdinal("PL_Id"));
                            var access = reader.GetInt32(reader.GetOrdinal("LineAccessLevel"));
                            eCILUser.LineAccessLevel.Add(pl_id, access);
                        }
                    }

                }
                conn.Close();
            }

            return eCILUser;

        }
        #endregion
    }

}
