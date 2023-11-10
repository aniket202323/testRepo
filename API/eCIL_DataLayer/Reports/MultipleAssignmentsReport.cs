using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace eCIL_DataLayer.Reports
{
    public class MultipleAssignmentsReport
    {
        public class MultipleAssignments
        {
            #region Variables
            private string line;
            private string module;
            private string group;
            private string task;
            private int varId;
            private string route;
            private string team;
            private string assignmentType;
            private int routeId;
            private int teamId;
            #endregion

            #region Properties
            public string Line { get => line; set => line = value; }
            public string Module { get => module; set => module = value; }
            public string Group { get => group; set => group = value; }
            public string Task { get => task; set => task = value; }
            public int VarId { get => varId; set => varId = value; }
            public string Route { get => route; set => route = value; }
            public string Team { get => team; set => team = value; }
            public string AssignmentType { get => assignmentType; set => assignmentType = value; }
            public int RouteId { get => routeId; set => routeId = value; }
            public int TeamId { get => teamId; set => teamId = value; }
            #endregion
        }

        #region Methods
        public List<MultipleAssignments> GetData(string connectionString, string linesList)
        {
            List<MultipleAssignments> result = new List<MultipleAssignments>();
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_ReportMultipleAssignments", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@DeptsList", DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@LinesList", linesList));
                    command.Parameters.Add(new SqlParameter("@MastersList", DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@SlavesList", DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@GroupsList", DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@VarsList", DBNull.Value));

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            MultipleAssignments temp = new MultipleAssignments();

                            if (!reader.IsDBNull(reader.GetOrdinal("Line")))
                                temp.Line = reader.GetString(reader.GetOrdinal("Line"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Module")))
                                temp.Module = reader.GetString(reader.GetOrdinal("Module"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Group")))
                                temp.Group = reader.GetString(reader.GetOrdinal("Group"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Task")))
                                temp.Task = reader.GetString(reader.GetOrdinal("Task"));
                            if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                                temp.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Route")))
                                temp.Route = reader.GetString(reader.GetOrdinal("Route"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                                temp.Team = reader.GetString(reader.GetOrdinal("Team"));
                            if (!reader.IsDBNull(reader.GetOrdinal("AssignmentType")))
                                temp.AssignmentType = reader.GetString(reader.GetOrdinal("AssignmentType"));
                            if (!reader.IsDBNull(reader.GetOrdinal("RouteId")))
                                temp.RouteId = reader.GetInt32(reader.GetOrdinal("RouteId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("TeamId")))
                                temp.TeamId = reader.GetInt32(reader.GetOrdinal("TeamId"));

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
