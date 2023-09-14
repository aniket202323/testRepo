using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class BatchSummary
    {
        #region Variables
        private string unit = string.Empty;
        private string batch = string.Empty;
        private string recordCount = string.Empty;
        private string recipeLayers = string.Empty;
        private DateTime batchStartTime;
        private DateTime batchEndTime;

        private bool processed;
        private bool endOfBatch;
        private string headerErrorSeverity = string.Empty;
        private string s88ErrorSeverity = string.Empty;
        private int eventCompErrorSeverity ;
        private int testConfErrorSeverity;
        private string uniqueId;
        #endregion

        #region Properties
        public string Unit { get => unit; set => unit = value; }
        public string Batch { get => batch; set => batch = value; }
        public string RecordCount { get => recordCount; set => recordCount = value; }
        public string RecipeLayers { get => recipeLayers; set => recipeLayers = value; }
        public DateTime BatchStartTime { get => batchStartTime; set => batchStartTime = value; }
        public DateTime BatchEndTime { get => batchEndTime; set => batchEndTime = value; }
        public bool Processed { get => processed; set => processed = value; }
        public bool EndOfBatch { get => endOfBatch; set => endOfBatch = value; }
        public string HeaderErrorSeverity { get => headerErrorSeverity; set => headerErrorSeverity = value; }
        public string S88ErrorSeverity { get => s88ErrorSeverity; set => s88ErrorSeverity = value; }
        public int EventCompErrorSeverity { get => eventCompErrorSeverity; set => eventCompErrorSeverity = value; }
        public int TestConfErrorSeverity { get => testConfErrorSeverity; set => testConfErrorSeverity = value; }
        public string UniqueId { get => uniqueId; set => uniqueId = value; }

        #endregion
    }
}