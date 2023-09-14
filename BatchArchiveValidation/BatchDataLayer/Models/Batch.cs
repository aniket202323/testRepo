using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class Batch
    {
        #region Variables
        private int rcdIdx;
        private string batchId = string.Empty;
        private string uniqueId = string.Empty;
        private string processOrder = string.Empty;
        private string batchName = string.Empty;
        private int pUId;
        private string uniqueIdPUId = string.Empty;
        private string pUDesc = string.Empty;
        private DateTime startTime;
        private string message = string.Empty;
        #endregion

        #region Properties
        public int RcdIdx { get => rcdIdx; set => rcdIdx = value; }
        public string BatchId { get => batchId; set => batchId = value; }
        public string UniqueId { get => uniqueId; set => uniqueId = value; }
        public string ProcessOrder { get => processOrder; set => processOrder = value; }
        public string BatchName { get => batchName; set => batchName = value; }
        public int PUId { get => pUId; set => pUId = value; }
        public string UniqueIdPUId { get => uniqueIdPUId; set => uniqueIdPUId = value; }
        public string PUDesc { get => pUDesc; set => pUDesc = value; }
        public DateTime StartTime { get => startTime; set => startTime = value; }
        public string Message { get => message; set => message = value; }

        #endregion
    }
}