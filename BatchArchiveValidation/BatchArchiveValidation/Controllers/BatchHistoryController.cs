using BatchArchiveValidation.Helper;
using BatchDataLayer;
using BatchDataLayer.Models;
using eCIL.Filters;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.Http;
using System.Web.Http.Cors;
using static BatchDataLayer.BatchHistoryData;

namespace BatchArchiveValidation.Controllers
{
    public class BatchHistoryController : ApiController
    {
        private BatchHistoryData batchHistoryData;        
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public BatchHistoryController()
        {
            batchHistoryData = new BatchHistoryData();
        }


        [BatchAuthorization]
        [HttpGet]
        [Route("api/routes/getBatchHistoryLines")]
        public List<BatchHistoryLine> Get()
        {

            try
            {
                return batchHistoryData.GetBatchHistoryLines(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
            }
            catch (Exception ex)
            {
                log.Error("Error GetBatchHistoryLines - " + ": " + ex.Message + " -- " + ex.StackTrace);
                throw new HttpException(500, ex.Message);
            }

        }
    }
}
