using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class BatchPO
    {
        #region Variables
       
        private string process_Order = string.Empty;
        private string line = string.Empty;
        private string path_ID = string.Empty;
        private string orderStatus = string.Empty;
        private DateTime timeSTAMP ;
        private string archivetable = string.Empty;
        private string batchnumber = string.Empty;
        private string pu_ID = string.Empty;
        private string uniqueId = string.Empty;
        private string message = string.Empty;
        #endregion

        #region Properties      
        public string Process_Order { get => process_Order; set => process_Order = value; }
        public string Line { get => line; set => line = value; }
        public string Path_ID { get => path_ID; set => path_ID = value; }    
        public DateTime TIMESTAMP { get => timeSTAMP; set => timeSTAMP = value; }
        public string Archivetable { get => archivetable; set => archivetable = value; }
        public string OrderStatus { get => orderStatus; set => orderStatus = value; }
        public string Batchnumber { get => batchnumber; set => batchnumber = value; }
        public string PU_ID { get => pu_ID; set => pu_ID = value; }     
        public string UniqueId { get => uniqueId; set => uniqueId = value; }
        public string Message { get => message; set => message = value; }

        #endregion
    }
}