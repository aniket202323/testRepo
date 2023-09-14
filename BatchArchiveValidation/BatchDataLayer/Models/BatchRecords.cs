using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class BatchRecords
    {
        #region Variables
        private string gMT = string.Empty;
        private DateTime lclTime;
        private string uniqueID = string.Empty;
        private string batchID = string.Empty;
        private string recipe = string.Empty;              
       
        private string descript = string.Empty;
        private string eventType = string.Empty;
        private string pValue;
        private string descriptAPI;
        private string eventAPI;

        private string pValueAPI = string.Empty;
        private string eU = string.Empty;
        private string area;
        private string procCell;
        private string unit;

        private string phase = string.Empty;
        private string printed = string.Empty;
        private string userID;
        private string phaseDesc;
        private string materialName;

        private string materialID = string.Empty;
        private string lotName = string.Empty;
        private string label;
        private string container;
        private string promiseID;

        private string signature = string.Empty;
        private string eRP_Flag = string.Empty;
        private string recordNo;
        private string reactivationNumber;
        private string instructionHTML;

        private string signatureID = string.Empty;
        private string actionID = string.Empty;
        private string message = string.Empty;

        #endregion

        #region Properties
        public string GMT { get => gMT; set => gMT = value; }
        public DateTime LclTime { get => lclTime; set => lclTime = value; }
        public string UniqueID { get => uniqueID; set => uniqueID = value; }
        public string BatchID { get => batchID; set => batchID = value; }
        public string Recipe { get => recipe; set => recipe = value; }
        public string Descript { get => descript; set => descript = value; }
        public string EventType { get => eventType; set => eventType = value; }
        public string PValue { get => pValue; set => pValue = value; }
        public string DescriptAPI { get => descriptAPI; set => descriptAPI = value; }
        public string EventAPI { get => eventAPI; set => eventAPI = value; }
        public string PValueAPI { get => pValueAPI; set => pValueAPI = value; }
        public string EU { get => eU; set => eU = value; }
        public string Area { get => area; set => area = value; }
        public string ProcCell { get => procCell; set => procCell = value; }
        public string Unit { get => unit; set => unit = value; }
        public string Phase { get => phase; set => phase = value; }
        public string Printed { get => printed; set => printed = value; }
        public string UserID { get => userID; set => userID = value; }
        public string PhaseDesc { get => phaseDesc; set => phaseDesc = value; }
        public string MaterialName { get => materialName; set => materialName = value; }
        public string MaterialID { get => materialID; set => materialID = value; }
        public string LotName { get => lotName; set => lotName = value; }
        public string Label { get => label; set => label = value; }
        public string Container { get => container; set => container = value; }
        public string PromiseID { get => promiseID; set => promiseID = value; }
        public string Signature { get => signature; set => signature = value; }
        public string ERP_Flag { get => eRP_Flag; set => eRP_Flag = value; }
        public string RecordNo { get => recordNo; set => recordNo = value; }
        public string ReactivationNumber { get => reactivationNumber; set => reactivationNumber = value; }
        public string InstructionHTML { get => instructionHTML; set => instructionHTML = value; }
        public string SignatureID { get => signatureID; set => signatureID = value; }
        public string ActionID { get => actionID; set => actionID = value; }
        public string Message { get => message; set => message = value; }

        #endregion
    }
}