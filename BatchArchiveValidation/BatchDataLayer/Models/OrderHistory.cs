using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class OrderHistory
    {
        #region Variables
        private DateTime entryOn;
        private string statusDesc = string.Empty;       
        private string userName = string.Empty;
        private string message = string.Empty;
        #endregion

        #region Properties
        public DateTime EntryOn { get => entryOn; set => entryOn = value; }
        public string StatusDesc { get => statusDesc; set => statusDesc = value; }       
        public string UserName { get => userName; set => userName = value; }
        public string Message { get => message; set => message = value; }
        #endregion
    }
}