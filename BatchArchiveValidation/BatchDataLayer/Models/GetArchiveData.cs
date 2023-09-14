using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class GetArchiveData
    {
        private string message = string.Empty;
        public List<BatchSummary> batchSummary { get; set; }
        public List<OrganizeCalculation> organizeCalculation { get; set; }
        public List<CreateConsumtion> createConsumtion { get; set; }
        public List<TestConformance> testConformance { get; set; }       
        public List<ErrorMessages> errorMessages { get; set; }
        public string Message { get => message; set => message = value; }
    }
}