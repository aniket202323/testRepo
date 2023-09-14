using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class BatchHistoryLine
    {
        #region Variables       
        private string lineName = string.Empty;
        private string pathCode = string.Empty;
        private string joinBatch = string.Empty;
        #endregion

        #region Properties
        public string LineName { get => lineName; set => lineName = value; }
        public string PathCode { get => pathCode; set => pathCode = value; }
        public string JoinBatch { get => joinBatch; set => joinBatch = value; }
        #endregion
    }
}