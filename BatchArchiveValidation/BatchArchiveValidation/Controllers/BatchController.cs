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
using static BatchDataLayer.BatchData;


namespace BatchArchiveValidation.Controllers
{
    public class BatchController : ApiController
    {
        private BatchData batchData;
        string pDelimiter = ",";
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public BatchController()
        {
            batchData = new BatchData();

        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>

        [BatchAuthorization]       
        [HttpGet]
        [Route("api/routes/getBatchUnits")]
        public List<BatchUnits> Get()
        {

            try
            {               
                return batchData.GetBatchUnits(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
            }
            catch (Exception ex)
            {
                log.Error("Error GetBatchUnits - " + ": " + ex.Message + " -- " + ex.StackTrace);
                throw new HttpException(500, ex.Message);
            }

        }

        [BatchAuthorization]
        [HttpGet]
        [Route("api/routes/getBatch")]
        public List<Batch> GetBatch(string pUIdList)
        {

            try
            {               
                return batchData.GetBatch(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], pUIdList, pDelimiter);
            }
            catch (Exception ex)
            {
                log.Error("Error GetBatchUnits - " + ": " + ex.Message + " -- " + ex.StackTrace);
                throw new HttpException(500, ex.Message);
            }

        }

        [BatchAuthorization]
        [HttpGet]
        [Route("api/routes/getArchiveData")]
        public GetArchiveData GetData(string pDelimitedBatchList)
        {

            try
            {               
                return batchData.GetArchiveData(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], pDelimitedBatchList, pDelimiter);
            }
            catch (Exception ex)
            {
                log.Error("Error GetBatchUnits - " + ": " + ex.Message + " -- " + ex.StackTrace);
                throw new HttpException(500, ex.Message);
            }

        }

        [BatchAuthorization]
        [HttpGet]
        [Route("api/routes/getOrderDetailData")]
        public GetOrderDetailStatus GetOrderDetailsData(string processOrder)
        {

            try
            {
                return batchData.GetOrderDetails(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], processOrder);
            }
            catch (Exception ex)
            {
                log.Error("Error GetOrderDetails - " + ": " + ex.Message + " -- " + ex.StackTrace);
                throw new HttpException(500, ex.Message);
            }

        }

        [BatchAuthorization]
        [HttpGet]
        [Route("api/routes/getOrderHistoryDetailsData")]
        public List<OrderHistory> GetOrderHistoryDetailsData(string processOrder)
        {

            try
            {
                return batchData.GetOrderHistoryDetails(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], processOrder);
            }
            catch (Exception ex)
            {
                log.Error("Error GetOrderHistoryDetailsData - " + ": " + ex.Message + " -- " + ex.StackTrace);
                throw new HttpException(500, ex.Message);
            }

        }

        [BatchAuthorization]
        [HttpGet]
        [Route("api/routes/getBatchRecordsData")]
        public List<BatchRecords> GetBatchRecordsData(string batchNumber)
        {

            try
            {
                return batchData.GetBatchRecords(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], batchNumber);
            }
            catch (Exception ex)
            {
                log.Error("Error GetOrderHistoryDetailsData - " + ": " + ex.Message + " -- " + ex.StackTrace);
                throw new HttpException(500, ex.Message);
            }

        }

        [BatchAuthorization]
        [HttpGet]
        [Route("api/routes/getBatchPODetailsData")]
        public List<BatchPO> GetBatchPODetailsData(string searchData)
        {

            try
            {
                return batchData.GetBatchPODetails(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], searchData);
            }
            catch (Exception ex)
            {
                log.Error("Error GetBatchPODetailsData - " + ": " + ex.Message + " -- " + ex.StackTrace);
                throw new HttpException(500, ex.Message);
            }

        }

        [BatchAuthorization]
        [HttpGet]
        [Route("api/routes/getModelStatusData")]
        public UserAuth GetModelStatusData()
        {

            try
            {
                return batchData.GetModelStatus(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
            }
            catch (Exception ex)
            {
                log.Error("Error GetBatchPODetailsData - " + ": " + ex.Message + " -- " + ex.StackTrace);
                throw new HttpException(500, ex.Message);
            }

        }
    }
}