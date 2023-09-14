using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class ErrorMessages
    {
        #region Variables
        private string uniqueId = string.Empty;
        private string errorMessage = string.Empty;
        #endregion

        #region Properties        
        public string ErrorMessage { get => errorMessage; set => errorMessage = value; }
        public string UniqueId { get => uniqueId; set => uniqueId = value; }
        #endregion
    }
}