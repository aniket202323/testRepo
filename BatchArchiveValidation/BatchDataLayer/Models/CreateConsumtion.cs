using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class CreateConsumtion
    {
        #region Variables
        private string parmType = string.Empty;
        private DateTime parmTime;
        private string phase = string.Empty;

        private string productCode = string.Empty;
        private string netWeight = string.Empty;
        private string sourceLocation = string.Empty;
        private string sourceLotId = string.Empty;
        private string batchUoM = string.Empty;
        private string sAPReport = string.Empty;
        private string filterValue = string.Empty;
        private string startHeelPhase = string.Empty;
        private string uniqueId = string.Empty;
        #endregion

        #region Properties
        public string ParmType { get => parmType; set => parmType = value; }
        public DateTime ParmTime { get => parmTime; set => parmTime = value; }
        public string Phase { get => phase; set => phase = value; }
        public string ProductCode { get => productCode; set => productCode = value; }
        public string NetWeight { get => netWeight; set => netWeight = value; }
        public string SourceLocation { get => sourceLocation; set => sourceLocation = value; }
        public string SourceLotId { get => sourceLotId; set => sourceLotId = value; }
        public string BatchUoM { get => batchUoM; set => batchUoM = value; }
        public string SAPReport { get => sAPReport; set => sAPReport = value; }
        public string FilterValue { get => filterValue; set => filterValue = value; }
        public string StartHeelPhase { get => startHeelPhase; set => startHeelPhase = value; }
        public string UniqueId { get => uniqueId; set => uniqueId = value; }
        #endregion
    }
}