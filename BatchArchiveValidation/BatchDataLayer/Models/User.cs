using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class User
    {
        #region Variables
        private string userName;
        private string password;
        private int user_Id;
        private int languageId;
        private int globalAccessLevel;
   
        private string token;
        private int sessionTimeout;
        private string eDHToken;
       
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
       
        public string Token { get => token; set => token = value; }
        public int SessionTimeout { get => sessionTimeout; set => sessionTimeout = value; }
       
        #endregion


    }
}