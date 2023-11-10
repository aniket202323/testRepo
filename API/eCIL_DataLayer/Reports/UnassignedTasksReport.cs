using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eCIL_DataLayer.Reports
{
    public class UnassignedTasksReport
    {
        public class UnassignedTasks { 
            #region Variables
        private int plId;
        private string line;
        private int masterPUId;
        private string masterUnit;
        private int slavePUId;
        private string slaveUnit;
        private int pugId;
        private string group;
        private int varId;
        private string task;
        #endregion

            #region Properties
        public int PLId { get => plId; set => plId = value; }
        public string Line { get => line; set => line = value; }
        public int MasterPUId { get => masterPUId; set => masterPUId = value; }
        public string MasterUnit { get => masterUnit; set => masterUnit = value; }
        public int SlavePUId { get => slavePUId; set => slavePUId = value; }
        public string SlaveUnit { get => slaveUnit; set => slaveUnit = value; }
        public int PUGId { get => pugId; set => pugId = value; }
        public string Group { get => group; set => group = value; }
        public int VarId { get => varId; set => varId = value; }
        public string Task { get => task; set => task = value; }
            #endregion
        }

        #region Methods
        public List<UnassignedTasks> GetData(string connectionString, string plIds, bool routeFlag = false, bool teamFlag = false)
        {
            List<UnassignedTasks> result = new List<UnassignedTasks>();
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_ReportUnassignedTasks", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@RouteFlag", routeFlag));
                    command.Parameters.Add(new SqlParameter("@TeamFlag", teamFlag));
                    command.Parameters.Add(new SqlParameter("@PLIDs", plIds));

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            UnassignedTasks temp = new UnassignedTasks();

                            if (!reader.IsDBNull(reader.GetOrdinal("PLId")))
                                temp.PLId = reader.GetInt32(reader.GetOrdinal("PLId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Line")))
                                temp.Line = reader.GetString(reader.GetOrdinal("Line"));
                            if (!reader.IsDBNull(reader.GetOrdinal("MasterPUId")))
                                temp.MasterPUId = reader.GetInt32(reader.GetOrdinal("MasterPUId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("MasterUnit")))
                                temp.MasterUnit = reader.GetString(reader.GetOrdinal("MasterUnit"));
                            if (!reader.IsDBNull(reader.GetOrdinal("SlavePUId")))
                                temp.SlavePUId = reader.GetInt32(reader.GetOrdinal("SlavePUId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnit")))
                                temp.SlaveUnit = reader.GetString(reader.GetOrdinal("SlaveUnit"));
                            if (!reader.IsDBNull(reader.GetOrdinal("PUGId")))
                                temp.PUGId = reader.GetInt32(reader.GetOrdinal("PUGId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Group")))
                                temp.Group = reader.GetString(reader.GetOrdinal("Group"));
                            if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                                temp.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Task")))
                                temp.Task = reader.GetString(reader.GetOrdinal("Task"));

                            result.Add(temp);
                        }
                        reader.Close();
                    }
                    conn.Close();
                }

                return result;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
        #endregion
    }
}
