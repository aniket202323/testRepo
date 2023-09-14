using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class BatchUnits
    {
        #region Variables
        private int rcdIdx;
        private string archiveDatabase = string.Empty;
        private string archiveTable = string.Empty;
        private string department = string.Empty; 
        private string line = string.Empty;
        private string unit = string.Empty;
        private int pUId;
        private string message = string.Empty;
        #endregion

        #region Properties
        public int RcdIdx { get => rcdIdx; set => rcdIdx = value; }
        public string ArchiveDatabase { get => archiveDatabase; set => archiveDatabase = value; }
        public string ArchiveTable { get => archiveTable; set => archiveTable = value; }
        public string Department { get => department; set => department = value; }
        public string Line { get => line; set => line = value; }
        public string Unit { get => unit; set => unit = value; }
        public int PUId { get => pUId; set => pUId = value; }
        public string Message { get => message; set => message = value; }
        #endregion
    }
}