using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class OrderDetails
    {
        #region Variables
        private string uniqueId = string.Empty;
        private string mainData = string.Empty;
        private string xMLData = string.Empty;
        private string status = string.Empty;
        private DateTime processDate ;
        private string pp_status = string.Empty;
        private string message = string.Empty;
        #endregion

        #region Properties
        public string UniqueId { get => uniqueId; set => uniqueId = value; }
        public string MainData { get => mainData; set => mainData = value; }
        public string XMLData { get => xMLData; set => xMLData = value; }    
        public string Status { get => status; set => status = value; }
        public DateTime ProcessDate { get => processDate; set => processDate = value; }
        public string Pp_status { get => pp_status; set => pp_status = value; }
        public string Message { get => message; set => message = value; }
        #endregion
    }
}