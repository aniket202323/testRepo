using BatchDataLayer.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace BatchDataLayer
{
    public class BatchData
    {
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public List<BatchUnits> GetBatchUnits(string _connectionString)
        {
            List<BatchUnits> result = new List<BatchUnits>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_PG_Batch_GetAvailableBatchUnits", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                SqlParameter Param_ErrorMessage = new SqlParameter("@op_vchErrorMessage", SqlDbType.VarChar, 1000);
                Param_ErrorMessage.Direction = ParameterDirection.Output;
                Param_ErrorMessage.Value = String.Empty;

                command.Parameters.Add(Param_ErrorMessage);
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        BatchUnits batchUnit = new BatchUnits();
                        if (reader["RcdIdx"] != DBNull.Value)
                        {
                            batchUnit.RcdIdx = Convert.ToInt32(reader["RcdIdx"]);
                        }
                        if (reader["ArchiveDatabase"] != DBNull.Value)
                        {
                            batchUnit.ArchiveDatabase = reader["ArchiveDatabase"].ToString();
                        }
                        if (reader["ArchiveTable"] != DBNull.Value)
                        {
                            batchUnit.ArchiveTable = reader["ArchiveTable"].ToString();
                        }
                        if (reader["Department"] != DBNull.Value)
                        {
                            batchUnit.Department = reader["Department"].ToString();
                        }
                        if (reader["Line"] != DBNull.Value)
                        {
                            batchUnit.Line = reader["Line"].ToString();
                        }
                        if (reader["Unit"] != DBNull.Value)
                        {
                            batchUnit.Unit = reader["Unit"].ToString();
                        }
                        if (reader["PUId"] != DBNull.Value)
                        {
                            batchUnit.PUId = Convert.ToInt32(reader["PUId"]);
                        }
                        result.Add(batchUnit);
                    }

                    reader.Close();
                    conn.Close();
                }

                string message = command.Parameters["@op_vchErrorMessage"].Value.ToString();
                if (message != "Success")
                {
                    BatchUnits batchUnit = new BatchUnits();
                    batchUnit.Message = message;
                    result.Add(batchUnit);
                }
            }

            return result;
        }


        public List<Batch> GetBatch(string _connectionString, string pUIdList, string pDelimiter)
        {
            List<Batch> result = new List<Batch>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_PG_Batch_GetAvailableBatches_Phase2", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                SqlParameter Param_ErrorMessage = new SqlParameter("@op_vchErrorMessage", SqlDbType.VarChar, 1000);
                Param_ErrorMessage.Direction = ParameterDirection.Output;
                Param_ErrorMessage.Value = String.Empty;

                command.Parameters.Add(new SqlParameter("@p_vchDelimitedPUIdList", pUIdList));
                command.Parameters.Add(new SqlParameter("@p_vchDelimiter", pDelimiter));
                command.Parameters.Add(Param_ErrorMessage);


                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        Batch batch = new Batch();

                        if (reader["RcdIdx"] != DBNull.Value)
                        {
                            batch.RcdIdx = Convert.ToInt32(reader["RcdIdx"]);
                        }
                        if (reader["BatchId"] != DBNull.Value)
                        {
                            batch.BatchId = reader["BatchId"].ToString();
                        }
                        if (reader["UniqueId"] != DBNull.Value)
                        {
                            batch.UniqueId = reader["UniqueId"].ToString();
                        }
                        if (reader["ProcessOrder"] != DBNull.Value)
                        {
                            batch.ProcessOrder = reader["ProcessOrder"].ToString();
                        }
                        if (reader["BatchName"] != DBNull.Value)
                        {
                            batch.BatchName = reader["BatchName"].ToString();
                        }
                        if (reader["PUId"] != DBNull.Value)
                        {
                            batch.PUId = Convert.ToInt32(reader["PUId"].ToString());
                        }
                        if (reader["UniqueIdPUId"] != DBNull.Value)
                        {
                            batch.UniqueIdPUId = reader["UniqueIdPUId"].ToString();
                        }
                        if (reader["PUDesc"] != DBNull.Value)
                        {
                            batch.PUDesc = reader["PUDesc"].ToString();
                        }
                        if (reader["StartTime"] != DBNull.Value)
                        {
                            batch.StartTime = Convert.ToDateTime(reader["StartTime"]);
                        }

                        result.Add(batch);
                    }

                    reader.Close();
                    conn.Close();
                }
                var message = command.Parameters["@op_vchErrorMessage"].Value.ToString();

                if (message != "Success")
                {
                    Batch batch = new Batch();
                    batch.Message = message;
                    result.Add(batch);
                }
            }
            return result;
        }

        public GetArchiveData GetArchiveData(string _connectionString, string pDelimitedBatchList, string pDelimiter)
        {
            GetArchiveData getArchiveDataResult = new GetArchiveData();

            List<BatchSummary> batchSummaryResult = new List<BatchSummary>();
            List<ErrorMessages> errorMessagesResult = new List<ErrorMessages>();
            List<OrganizeCalculation> organizeCalculationResult = new List<OrganizeCalculation>();
            List<CreateConsumtion> createConsumtionResult = new List<CreateConsumtion>();
            List<TestConformance> testConformanceResult = new List<TestConformance>();
            List<OrderDetails> orderDetailsData = new List<OrderDetails>();
            List<OrderHistory> orderHistoryData = new List<OrderHistory>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_PG_Batch_GetBatchArchiveData", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                SqlParameter Param_ErrorMessage = new SqlParameter("@op_vchErrorMessage", SqlDbType.VarChar, 1000);
                Param_ErrorMessage.Direction = ParameterDirection.Output;
                Param_ErrorMessage.Value = String.Empty;


                command.Parameters.Add(new SqlParameter("@p_vchDelimitedBatchList", pDelimitedBatchList));
                command.Parameters.Add(new SqlParameter("@p_vchDelimiter", pDelimiter));
                command.Parameters.Add(Param_ErrorMessage);

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {

                        BatchSummary batchSummary = new BatchSummary();
                        if (reader["Unit"] != DBNull.Value)
                        {
                            batchSummary.Unit = reader["Unit"].ToString();
                        }
                        if (reader["Batch"] != DBNull.Value)
                        {
                            batchSummary.Batch = reader["Batch"].ToString();
                        }
                        if (reader["RecordCount"] != DBNull.Value)
                        {
                            batchSummary.RecordCount = reader["RecordCount"].ToString();
                        }
                        if (reader["RecipeLayers"] != DBNull.Value)
                        {
                            batchSummary.RecipeLayers = reader["RecipeLayers"].ToString();
                        }
                        if (reader["BatchStartTime"] != DBNull.Value)
                        {
                            batchSummary.BatchStartTime = Convert.ToDateTime(reader["BatchStartTime"].ToString());
                        }
                        if (reader["BatchEndTime"] != DBNull.Value)
                        {
                            batchSummary.BatchEndTime = Convert.ToDateTime(reader["BatchEndTime"]);
                        }
                        if (reader["EndOfBatch"] != DBNull.Value)
                        {
                            batchSummary.EndOfBatch = Convert.ToBoolean(reader["EndOfBatch"]);
                        }
                        if (reader["Processed"] != DBNull.Value)
                        {
                            batchSummary.Processed = Convert.ToBoolean(reader["Processed"]);
                        }
                        if (reader["HeaderErrorSeverity"] != DBNull.Value)
                        {
                            batchSummary.HeaderErrorSeverity = reader["HeaderErrorSeverity"].ToString();
                        }
                        if (reader["S88ErrorSeverity"] != DBNull.Value)
                        {
                            batchSummary.S88ErrorSeverity = reader["S88ErrorSeverity"].ToString();
                        }
                        if (reader["EventCompErrorSeverity"] != DBNull.Value)
                        {
                            batchSummary.EventCompErrorSeverity = Convert.ToInt32(reader["EventCompErrorSeverity"]);
                        }
                        if (reader["TestConfErrorSeverity"] != DBNull.Value)
                        {
                            batchSummary.TestConfErrorSeverity = Convert.ToInt32(reader["TestConfErrorSeverity"]);
                        }
                        if (reader["UniqueId"] != DBNull.Value)
                        {
                            batchSummary.UniqueId = reader["UniqueId"].ToString();
                        }
                        batchSummaryResult.Add(batchSummary);
                    }

                    getArchiveDataResult.batchSummary = batchSummaryResult;

                    reader.NextResult();

                    if (reader.HasRows)
                    {
                        while (reader.Read())
                        {
                            OrganizeCalculation organizeCalculation = new OrganizeCalculation();
                            if (reader["ParmType"] != DBNull.Value)
                            {
                                organizeCalculation.ParmType = reader["ParmType"].ToString();
                            }
                            if (reader["ProductCode"] != DBNull.Value)
                            {
                                organizeCalculation.ProductCode = reader["ProductCode"].ToString();
                            }
                            if (reader["BatchSize"] != DBNull.Value)
                            {
                                organizeCalculation.BatchSize = reader["BatchSize"].ToString();
                            }
                            if (reader["BatchEnd"] != DBNull.Value)
                            {
                                organizeCalculation.BatchEnd = reader["BatchEnd"].ToString();
                            }
                            if (reader["BatchReport"] != DBNull.Value)
                            {
                                organizeCalculation.BatchReport = reader["BatchReport"].ToString();
                            }
                            if (reader["ParmTime"] != DBNull.Value)
                            {
                                organizeCalculation.ParmTime = Convert.ToDateTime(reader["ParmTime"]);
                            }
                            if (reader["ProcessOrder"] != DBNull.Value)
                            {
                                organizeCalculation.ProcessOrder = reader["ProcessOrder"].ToString();
                            }
                            if (reader["Phase"] != DBNull.Value)
                            {
                                organizeCalculation.Phase = reader["Phase"].ToString();
                            }
                            if (reader["UniqueId"] != DBNull.Value)
                            {
                                organizeCalculation.UniqueId = reader["UniqueId"].ToString();
                            }

                            organizeCalculationResult.Add(organizeCalculation);
                        }

                    }


                    getArchiveDataResult.organizeCalculation = organizeCalculationResult;

                    reader.NextResult();

                    if (reader.HasRows)
                    {
                        while (reader.Read())
                        {
                            CreateConsumtion createConsumtion = new CreateConsumtion();
                            if (reader["ParmType"] != DBNull.Value)
                            {
                                createConsumtion.ParmType = reader["ParmType"].ToString();
                            }
                            if (reader["ProductCode"] != DBNull.Value)
                            {
                                createConsumtion.ProductCode = reader["ProductCode"].ToString();
                            }
                            if (reader["Phase"] != DBNull.Value)
                            {
                                createConsumtion.Phase = reader["Phase"].ToString();
                            }
                            if (reader["ParmTime"] != DBNull.Value)
                            {
                                createConsumtion.ParmTime = Convert.ToDateTime(reader["ParmTime"]);
                            }
                            if (reader["NetWeight"] != DBNull.Value)
                            {
                                createConsumtion.NetWeight = reader["NetWeight"].ToString();
                            }
                            if (reader["SourceLocation"] != DBNull.Value)
                            {
                                createConsumtion.SourceLocation = reader["SourceLocation"].ToString();
                            }
                            if (reader["SourceLotId"] != DBNull.Value)
                            {
                                createConsumtion.SourceLotId = reader["SourceLotId"].ToString();
                            }
                            if (reader["BatchUoM"] != DBNull.Value)
                            {
                                createConsumtion.BatchUoM = reader["BatchUoM"].ToString();
                            }
                            if (reader["SAPReport"] != DBNull.Value)
                            {
                                createConsumtion.SAPReport = reader["SAPReport"].ToString();
                            }
                            if (reader["FilterValue"] != DBNull.Value)
                            {
                                createConsumtion.FilterValue = reader["FilterValue"].ToString();
                            }
                            if (reader["StartHeelPhase"] != DBNull.Value)
                            {
                                createConsumtion.StartHeelPhase = reader["StartHeelPhase"].ToString();
                            }
                            if (reader["UniqueId"] != DBNull.Value)
                            {
                                createConsumtion.UniqueId = reader["UniqueId"].ToString();
                            }
                            createConsumtionResult.Add(createConsumtion);
                        }

                    }
                    getArchiveDataResult.createConsumtion = createConsumtionResult;

                    reader.NextResult();

                    if (reader.HasRows)
                    {
                        while (reader.Read())
                        {
                            TestConformance testConformance = new TestConformance();
                            if (reader["ParmType"] != DBNull.Value)
                            {
                                testConformance.ParmType = reader["ParmType"].ToString();
                            }
                            if (reader["Phase"] != DBNull.Value)
                            {
                                testConformance.Phase = reader["Phase"].ToString();
                            }
                            if (reader["ParmTime"] != DBNull.Value)
                            {
                                testConformance.ParmTime = Convert.ToDateTime(reader["ParmTime"]);
                            }
                            if (reader["ParmName"] != DBNull.Value)
                            {
                                testConformance.ParmName = reader["ParmName"].ToString();
                            }
                            if (reader["ParmValue"] != DBNull.Value)
                            {
                                testConformance.ParmValue = reader["ParmValue"].ToString();
                            }
                            if (reader["UniqueId"] != DBNull.Value)
                            {
                                testConformance.UniqueId = reader["UniqueId"].ToString();
                            }
                            testConformanceResult.Add(testConformance);
                        }

                    }


                    getArchiveDataResult.testConformance = testConformanceResult;

                    reader.NextResult();

                    if (reader.HasRows)
                    {
                        while (reader.Read())
                        {
                            ErrorMessages errorMessages = new ErrorMessages();
                            if (reader["ErrorMessage"] != DBNull.Value)
                            {
                                errorMessages.ErrorMessage = reader["ErrorMessage"].ToString();
                            }
                            if (reader["UniqueId"] != DBNull.Value)
                            {
                                errorMessages.UniqueId = reader["UniqueId"].ToString();
                            }
                            errorMessagesResult.Add(errorMessages);

                        }
                    }

                    getArchiveDataResult.errorMessages = errorMessagesResult;

                    reader.Close();
                }
                var message = command.Parameters["@op_vchErrorMessage"].Value.ToString();

                if (message != "Success")
                {
                    getArchiveDataResult.Message = message;
                }
            }

            return getArchiveDataResult;
        }

        public GetOrderDetailStatus GetOrderDetails(string _connectionString, string processOrder)
        {
            GetOrderDetailStatus getOrderDetailStatus = new GetOrderDetailStatus();


            List<OrderDetails> orderdetailsResult = new List<OrderDetails>();
            Status statusResult = new Status();

            if (processOrder == null || processOrder == "")
            {
                OrderDetails orderDetails = new OrderDetails();
                orderDetails.Message = "ProcessOrder should not be empty";
                orderdetailsResult.Add(orderDetails);
                getOrderDetailStatus.orderDetails = orderdetailsResult;
                return getOrderDetailStatus;
            }



            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_BDAT_GetOrderDetails", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;


                command.Parameters.Add(new SqlParameter("@Process_Order", processOrder));

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        OrderDetails orderDetails = new OrderDetails();
                        if (reader["Id"] != DBNull.Value)
                        {
                            orderDetails.UniqueId = reader["Id"].ToString();
                        }
                        if (reader["MainData"] != DBNull.Value)
                        {
                            orderDetails.MainData = reader["MainData"].ToString();
                        }
                        if (reader["Message"] != DBNull.Value)
                        {
                            orderDetails.XMLData = reader["Message"].ToString();
                        }
                        if (reader["ProcessedDate"] != DBNull.Value)
                        {
                            orderDetails.ProcessDate = Convert.ToDateTime(reader["ProcessedDate"]);
                        }
                        if (reader["errormessage"] != DBNull.Value)
                        {
                            orderDetails.Status = reader["errormessage"].ToString();
                        }

                        orderdetailsResult.Add(orderDetails);
                    }
                    getOrderDetailStatus.orderDetails = orderdetailsResult;

                    reader.NextResult();

                    if (reader.HasRows)
                    {
                        while (reader.Read())
                        {
                            Status status = new Status();
                            if (reader["pp_status_desc"] != DBNull.Value)
                            {
                                status.OrderStatus = reader["pp_status_desc"].ToString();
                            }

                            statusResult = status;
                        }

                    }

                    getOrderDetailStatus.status = statusResult;
                    reader.Close();
                    conn.Close();
                }
            }

            return getOrderDetailStatus;

        }

        public List<OrderHistory> GetOrderHistoryDetails(string _connectionString, string processOrder)
        {
            List<OrderHistory> result = new List<OrderHistory>();

            if (processOrder == null || processOrder == "")
            {
                OrderHistory orderHistory = new OrderHistory();
                orderHistory.Message = "ProcessOrder should not be empty";
                result.Add(orderHistory);
                return result;
            }
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_BDAT_OrderHistoryDetails", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;


                command.Parameters.Add(new SqlParameter("@Process_Order", processOrder));

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        OrderHistory orderHistory = new OrderHistory();
                        if (reader["Entry_On"] != DBNull.Value)
                        {
                            orderHistory.EntryOn = Convert.ToDateTime(reader["Entry_On"]);
                        }
                        if (reader["PP_Status_Desc"] != DBNull.Value)
                        {
                            orderHistory.StatusDesc = reader["PP_Status_Desc"].ToString();
                        }
                        if (reader["Username"] != DBNull.Value)
                        {
                            orderHistory.UserName = reader["Username"].ToString();
                        }

                        result.Add(orderHistory);
                    }

                    reader.Close();
                    conn.Close();
                }
            }
            return result;
        }

        public List<BatchRecords> GetBatchRecords(string _connectionString, string batchNumber)
        {
            List<BatchRecords> result = new List<BatchRecords>();

            if (batchNumber == null || batchNumber == "")
            {
                BatchRecords batchRedcord = new BatchRecords();
                batchRedcord.Message = "Batch number should not be empty";
                result.Add(batchRedcord);
                return result;
            }
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_BDAT_GetBatchRecords", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;


                command.Parameters.Add(new SqlParameter("@BatchId", batchNumber));


                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        BatchRecords batchRedcord = new BatchRecords();

                        if (reader["GMT"] != DBNull.Value)
                        {
                            batchRedcord.GMT = (reader["GMT"]).ToString();
                        }
                        if (reader["lclTime"] != DBNull.Value)
                        {
                            batchRedcord.LclTime = Convert.ToDateTime(reader["lclTime"]);
                        }
                        if (reader["UniqueID"] != DBNull.Value)
                        {
                            batchRedcord.UniqueID = reader["UniqueID"].ToString();
                        }
                        if (reader["BatchID"] != DBNull.Value)
                        {
                            batchRedcord.BatchID = reader["BatchID"].ToString();
                        }
                        if (reader["Recipe"] != DBNull.Value)
                        {
                            batchRedcord.Recipe = reader["Recipe"].ToString();
                        }
                        if (reader["Descript"] != DBNull.Value)
                        {
                            batchRedcord.Descript = reader["Descript"].ToString();
                        }
                        if (reader["Event"] != DBNull.Value)
                        {
                            batchRedcord.EventType = reader["Event"].ToString();
                        }
                        if (reader["PValue"] != DBNull.Value)
                        {
                            batchRedcord.PValue = reader["PValue"].ToString();
                        }

                        if (reader["DescriptAPI"] != DBNull.Value)
                        {
                            batchRedcord.DescriptAPI = (reader["DescriptAPI"]).ToString();
                        }
                        if (reader["EventAPI"] != DBNull.Value)
                        {
                            batchRedcord.EventAPI = reader["EventAPI"].ToString();
                        }
                        if (reader["PValueAPI"] != DBNull.Value)
                        {
                            batchRedcord.PValueAPI = reader["PValueAPI"].ToString();
                        }
                        if (reader["EU"] != DBNull.Value)
                        {
                            batchRedcord.EU = reader["EU"].ToString();
                        }
                        if (reader["Area"] != DBNull.Value)
                        {
                            batchRedcord.Area = reader["Area"].ToString();
                        }
                        if (reader["ProcCell"] != DBNull.Value)
                        {
                            batchRedcord.ProcCell = reader["ProcCell"].ToString();
                        }
                        if (reader["Unit"] != DBNull.Value)
                        {
                            batchRedcord.Unit = reader["Unit"].ToString();
                        }
                        if (reader["Phase"] != DBNull.Value)
                        {
                            batchRedcord.Phase = reader["Phase"].ToString();
                        }
                        if (reader["Printed"] != DBNull.Value)
                        {
                            batchRedcord.Printed = (reader["Printed"]).ToString();
                        }
                        if (reader["UserID"] != DBNull.Value)
                        {
                            batchRedcord.UserID = reader["UserID"].ToString();
                        }
                        if (reader["PhaseDesc"] != DBNull.Value)
                        {
                            batchRedcord.PhaseDesc = reader["PhaseDesc"].ToString();
                        }
                        if (reader["MaterialName"] != DBNull.Value)
                        {
                            batchRedcord.MaterialName = reader["MaterialName"].ToString();
                        }
                        if (reader["MaterialID"] != DBNull.Value)
                        {
                            batchRedcord.MaterialID = reader["MaterialID"].ToString();
                        }
                        if (reader["LotName"] != DBNull.Value)
                        {
                            batchRedcord.LotName = reader["LotName"].ToString();
                        }
                        if (reader["Label"] != DBNull.Value)
                        {
                            batchRedcord.Label = reader["Label"].ToString();
                        }
                        if (reader["Container"] != DBNull.Value)
                        {
                            batchRedcord.Container = reader["Container"].ToString();
                        }

                        if (reader["PromiseID"] != DBNull.Value)
                        {
                            batchRedcord.PromiseID = reader["PromiseID"].ToString();
                        }
                        if (reader["Signature"] != DBNull.Value)
                        {
                            batchRedcord.Signature = reader["Signature"].ToString();
                        }
                        if (reader["ERP_Flag"] != DBNull.Value)
                        {
                            batchRedcord.ERP_Flag = reader["ERP_Flag"].ToString();
                        }
                        if (reader["RecordNo"] != DBNull.Value)
                        {
                            batchRedcord.RecordNo = reader["RecordNo"].ToString();
                        }
                        if (reader["ReactivationNumber"] != DBNull.Value)
                        {
                            batchRedcord.ReactivationNumber = reader["ReactivationNumber"].ToString();
                        }
                        if (reader["InstructionHTML"] != DBNull.Value)
                        {
                            batchRedcord.InstructionHTML = reader["InstructionHTML"].ToString();
                        }
                        if (reader["SignatureID"] != DBNull.Value)
                        {
                            batchRedcord.SignatureID = reader["SignatureID"].ToString();
                        }
                        if (reader["ActionID"] != DBNull.Value)
                        {
                            batchRedcord.ActionID = reader["ActionID"].ToString();
                        }

                        result.Add(batchRedcord);
                    }

                    reader.Close();
                    conn.Close();
                }

            }
            return result;
        }

        public List<BatchPO> GetBatchPODetails(string _connectionString, string searchData)
        {
            List<BatchPO> result = new List<BatchPO>();

            if (searchData == null || searchData == "")
            {
                BatchPO batchPO = new BatchPO();
                batchPO.Message = "ProcessOrder or Batch no should not be empty";
                result.Add(batchPO);
                return result;
            }
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_BDAT_SearchbyBatchorPO", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;


                command.Parameters.Add(new SqlParameter("@Searchdata", searchData));

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        BatchPO batchPO = new BatchPO();
                        if (reader["Process_Order"] != DBNull.Value)
                        {
                            batchPO.Process_Order = reader["Process_Order"].ToString();
                        }
                        if (reader["Line"] != DBNull.Value)
                        {
                            batchPO.Line = reader["Line"].ToString();
                        }
                        if (reader["PATH_ID"] != DBNull.Value)
                        {
                            batchPO.Path_ID = reader["PATH_ID"].ToString();
                        }
                        if (reader["OrderStatus"] != DBNull.Value)
                        {
                            batchPO.OrderStatus = reader["OrderStatus"].ToString();
                        }
                        if (reader["TIMESTAMP"] != DBNull.Value)
                        {
                            batchPO.TIMESTAMP = Convert.ToDateTime(reader["TIMESTAMP"]);
                        }
                        if (reader["Archivetable"] != DBNull.Value)
                        {
                            batchPO.Archivetable = reader["Archivetable"].ToString();
                        }
                        if (reader["Batchnumber"] != DBNull.Value)
                        {
                            batchPO.Batchnumber = reader["Batchnumber"].ToString();
                        }
                        if (reader["PU_ID"] != DBNull.Value)
                        {
                            batchPO.PU_ID = reader["PU_ID"].ToString();
                        }
                        if (reader["UniqueId"] != DBNull.Value)
                        {
                            batchPO.UniqueId = reader["UniqueId"].ToString();
                        }

                        result.Add(batchPO);
                    }

                    reader.Close();
                    conn.Close();
                }
            }
            return result;
        }

        public UserAuth GetModelStatus(string _connectionString)
        {
            UserAuth userAuthResult = new UserAuth();
            
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {

                UserAuth userAuth = new UserAuth();
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_BDAT_GetModelStatus", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                SqlParameter IsActive = new SqlParameter("@IsActive", SqlDbType.VarChar, 1);
                SqlParameter IsConfigured = new SqlParameter("@IsConfigured", SqlDbType.VarChar, 1);
                IsActive.Direction = ParameterDirection.Output;
                IsConfigured.Direction = ParameterDirection.Output;
               
                command.Parameters.Add(IsActive);
                command.Parameters.Add(IsConfigured);
                command.ExecuteNonQuery();

                userAuth.IsActive = command.Parameters["@IsActive"].Value.ToString();
                userAuth.IsConfigured = command.Parameters["@IsConfigured"].Value.ToString();
                userAuthResult = userAuth;
                conn.Close();
            }
            return userAuthResult;
        }




    }
}