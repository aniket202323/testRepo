using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class TestConformance
    {
        #region Variables
        private string parmType = string.Empty;
        private DateTime parmTime;

        private string phase = string.Empty;
        private string parmName = string.Empty;
        private string parmValue = string.Empty;
        private string uniqueId = string.Empty;

        #endregion

        #region Properties
        public string ParmType { get => parmType; set => parmType = value; }
        public DateTime ParmTime { get => parmTime; set => parmTime = value; }
        public string Phase { get => phase; set => phase = value; }
        public string ParmName { get => parmName; set => parmName = value; }
        public string ParmValue { get => parmValue; set => parmValue = value; }
        public string UniqueId { get => uniqueId; set => uniqueId = value; }

        #endregion
    }
}