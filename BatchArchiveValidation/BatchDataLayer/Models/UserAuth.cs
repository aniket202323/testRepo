using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class UserAuth
    {
        #region Variables
      
        private bool authstatus ;
        private string accessLevel = string.Empty;
        private string isActive = string.Empty;
        private string isConfigured = string.Empty;

        #endregion

        #region Properties     
        public bool Authstatus { get => authstatus; set => authstatus = value; }
        public string AccessLevel { get => accessLevel; set => accessLevel = value; }
        public string IsActive { get => isActive; set => isActive = value; }
        public string IsConfigured { get => isConfigured; set => isConfigured = value; }

        #endregion
    }
}