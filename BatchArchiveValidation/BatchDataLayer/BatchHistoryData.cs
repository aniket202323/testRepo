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
    public class BatchHistoryData
    {
        public List<BatchHistoryLine> GetBatchHistoryLines(string _connectionString)
        {
            List<BatchHistoryLine> batchHistoryResult = new List<BatchHistoryLine>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                              
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_BDAT_GetBatchHistoryLineDetails", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;


                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        BatchHistoryLine batchHistoryLine = new BatchHistoryLine();
                        if (reader["Line_name"] != DBNull.Value)
                        {
                            batchHistoryLine.LineName = reader["Line_name"].ToString();
                        }
                        if (reader["Path_code"] != DBNull.Value)
                        {
                            batchHistoryLine.PathCode = reader["Path_code"].ToString();
                        }
                        if (reader["JoinBatch"] != DBNull.Value)
                        {
                            batchHistoryLine.JoinBatch = reader["JoinBatch"].ToString();
                        }

                        batchHistoryResult.Add(batchHistoryLine);
                    }

                    reader.Close();
                    conn.Close();
                }
            }
            return batchHistoryResult;
        }
    }
}