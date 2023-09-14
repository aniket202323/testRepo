using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class OrganizeCalculation
    {
        #region Variables
        private string parmType = string.Empty;
        private DateTime parmTime;    
        private string phase = string.Empty;

        private string processOrder = string.Empty;
        private string productCode = string.Empty;
        private string batchSize = string.Empty;
        private string batchEnd = string.Empty;
        private string batchReport = string.Empty;
        private string uniqueId = string.Empty;

        #endregion

        #region Properties
        public string ParmType { get => parmType; set => parmType = value; }
        public DateTime ParmTime { get => parmTime; set => parmTime = value; }
        public string Phase { get => phase; set => phase = value; }
        public string ProcessOrder { get => processOrder; set => processOrder = value; }
        public string ProductCode { get => productCode; set => productCode = value; }      
        public string BatchSize { get => batchSize; set => batchSize = value; }
        public string BatchEnd { get => batchEnd; set => batchEnd = value; }      
        public string BatchReport { get => batchReport; set => batchReport = value; }
        public string UniqueId { get => uniqueId; set => uniqueId = value; }

        #endregion
    }
}