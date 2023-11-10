using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eCIL_DataLayer.Reports
{
    public class ReportSchedulingErrors : TaskEdit
    {
        #region Variablss
        private int rowId;
        private string rowType;
        private string prodCode;
        private string period;
        #endregion

        #region Properties
        public int RowId { get => rowId; set => rowId = value; }
        public string RowType { get => rowType; set => rowType = value; }
        public string ProdCode { get => prodCode; set => prodCode = value; }
        public string Period { get => period; set => period = value; }
        #endregion

        public List<ReportSchedulingErrors> GetTaskList(string connectionString, string deptIds, string lineIds, string masterIds,string slaveIds, string groupIds, string variableIds)
        {
            List<ReportSchedulingErrors> result = new List<ReportSchedulingErrors>();
            try
            {
                using(SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_ReportSchedulingErrors", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@DeptsList", deptIds == null ? (object)DBNull.Value : deptIds));
                    command.Parameters.Add(new SqlParameter("@LinesList", lineIds == null ? (object)DBNull.Value : lineIds));
                    command.Parameters.Add(new SqlParameter("@MastersList", masterIds == null ? (object)DBNull.Value : masterIds));
                    command.Parameters.Add(new SqlParameter("@SlavesList", slaveIds == null ? (object)DBNull.Value : slaveIds));
                    command.Parameters.Add(new SqlParameter("@GroupsList", groupIds == null ? (object)DBNull.Value : groupIds));
                    command.Parameters.Add(new SqlParameter("@VarsList", variableIds == null ? (object)DBNull.Value : variableIds));
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while(reader.Read())
                        {
                            ReportSchedulingErrors temp = new ReportSchedulingErrors();
                            if (!reader.IsDBNull(reader.GetOrdinal("RowId")))
                                temp.RowId = reader.GetInt32(reader.GetOrdinal("RowId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("RowType")))
                                temp.RowType = reader.GetString(reader.GetOrdinal("RowType"));
                            if (!reader.IsDBNull(reader.GetOrdinal("DepartmentDesc")))
                                temp.DepartmentDesc = reader.GetString(reader.GetOrdinal("DepartmentDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("LineDesc")))
                                temp.LineDesc = reader.GetString(reader.GetOrdinal("LineDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitDesc")))
                                temp.MasterUnitDesc = reader.GetString(reader.GetOrdinal("MasterUnitDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitDesc")))
                                temp.SlaveUnitDesc = reader.GetString(reader.GetOrdinal("SlaveUnitDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("ProductionGroupDesc")))
                                temp.ProductionGroupDesc = reader.GetString(reader.GetOrdinal("ProductionGroupDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("TaskDesc")))
                                temp.VarDesc = reader.GetString(reader.GetOrdinal("TaskDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                                temp.FL1 = reader.GetString(reader.GetOrdinal("FL1"));
                            if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                                temp.FL2 = reader.GetString(reader.GetOrdinal("FL2"));
                            if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                                temp.FL3 = reader.GetString(reader.GetOrdinal("FL3"));
                            if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                                temp.FL4 = reader.GetString(reader.GetOrdinal("FL4"));
                            if (!reader.IsDBNull(reader.GetOrdinal("ProdCode")))
                                temp.ProdCode = reader.GetString(reader.GetOrdinal("ProdCode"));
                            var active = false;
                            if (!reader.IsDBNull(reader.GetOrdinal("Active")))
                            {
                                try
                                {
                                    active = reader.GetString(reader.GetOrdinal("Active")) == "1";
                                }
                                catch (Exception ex)
                                {
                                    throw new Exception(ex.Message);
                                }
                            }
                            temp.Active = active;
                            if (!reader.IsDBNull(reader.GetOrdinal("Period")))
                                temp.Period = reader.GetString(reader.GetOrdinal("Period"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Window")))
                                temp.Window = reader.GetString(reader.GetOrdinal("Window"));
                            if (!reader.IsDBNull(reader.GetOrdinal("VarID")))
                                temp.VarId = reader.GetInt32(reader.GetOrdinal("VarID"));
                            result.Add(temp);
                        }
                    }
                }
                return result;
            }catch(Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
    }
}
