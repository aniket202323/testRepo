using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace eCIL.Helper
{
    public class OpsHubMessage
    {
            #region Variables
            private string jwtToken;
            #endregion

            #region Properties
            public string JwtToken { get => jwtToken; set => jwtToken = value; }
            #endregion
    }
}