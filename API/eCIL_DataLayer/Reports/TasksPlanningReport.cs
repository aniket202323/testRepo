using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace eCIL_DataLayer.Reports
{
    public class TasksPlanningReport
    {

        public class TasksPlanning
        {
            #region Variables
            private int varId;
            private string team;
            private string route;
            private string department;
            private string line;
            private string masterUnit;
            private string slaveUnit;
            private string taskId;
            private string task;
            private string longTaskName;
            private string taskAction;
            private string taskFrequency;
            private string taskType;
            private string projectedScheduleDate;
            private string fl1;
            private string fl2;
            private string fl3;
            private string fl4;
            private string duration;
            private System.DateTime entryOn;
            private string criteria;
            private string hazards;
            private string method;
            private string ppe;
            private string tools;
            private string lubricant;
            private string lateTime;
            private string externalLink;
            #endregion

            #region Properties
            public int VarId { get => varId; set => varId = value; }
            public string Team { get => team; set => team = value; }
            public string Route { get => route; set => route = value; }
            public string Department { get => department; set => department = value; }
            public string Line { get => line; set => line = value; }
            public string MasterUnit { get => masterUnit; set => masterUnit = value; }
            public string SlaveUnit { get => slaveUnit; set => slaveUnit = value; }
            public string TaskId { get => taskId; set => taskId = value; }
            public string Task { get => task; set => task = value; }
            public string LongTaskName { get => longTaskName; set => longTaskName = value; }
            public string TaskAction { get => taskAction; set => taskAction = value; }
            public string TaskFrequency { get => taskFrequency; set => taskFrequency = value; }
            public string TaskType { get => taskType; set => taskType = value; }
            public string ProjectedScheduleDate { get => projectedScheduleDate; set => projectedScheduleDate = value; }
            public string FL1 { get => fl1; set => fl1 = value; }
            public string FL2 { get => fl2; set => fl2 = value; }
            public string FL3 { get => fl3; set => fl3 = value; }
            public string FL4 { get => fl4; set => fl4 = value; }
            public string Duration { get => duration; set => duration = value; }
            public System.DateTime EntryOn { get => entryOn; set => entryOn = value; }
            public string Criteria { get => criteria; set => criteria = value; }
            public string Hazards { get => hazards; set => hazards = value; }
            public string Method { get => method; set => method = value; }
            public string PPE { get => ppe; set => ppe = value; }
            public string Tools { get => tools; set => tools = value; }
            public string Lubricant { get => lubricant; set => lubricant = value; }
            public string LateTime { get => lateTime; set => lateTime = value; }
            public string ExternalLink { get => externalLink; set => externalLink = value; }
            #endregion

            #region Constructor
            public TasksPlanning()
            {
                VarId = 0;
                Team = string.Empty;
                Route = string.Empty;
                Department = string.Empty;
                Line = string.Empty;
                MasterUnit = string.Empty;
                SlaveUnit = string.Empty;
                TaskId = string.Empty;
                Task = string.Empty;
                LongTaskName = string.Empty;
                TaskAction = string.Empty;
                TaskFrequency = string.Empty;
                TaskType = string.Empty;
                ProjectedScheduleDate = string.Empty;
                FL1 = string.Empty;
                FL2 = string.Empty;
                FL3 = string.Empty;
                FL4 = string.Empty;
                Duration = string.Empty;
                EntryOn = new System.DateTime();
                Criteria = string.Empty;
                Hazards = string.Empty;
                Method = string.Empty;
                PPE = string.Empty;
                Tools = string.Empty;
                Lubricant = string.Empty;
                LateTime = string.Empty;
                ExternalLink = string.Empty;
            }
            #endregion
        }

        enum Granularity
        {
            None,
            Team,
            Route,
            Site,
            Department,
            Line,
            MasterUnit,
            Module,
            Task
        }

        
       
        #region Methods
        /// <summary>
        /// 
        /// </summary>
        /// <param name="connectionString">ConnectionString to database</param>
        /// <param name="granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="topLevelId">The Id from which the report was initiated, before drill-down</param>
        /// <param name="subLevel">The id of the current level being drilled-down</param>
        /// <param name="startTime">The beginning period of the report</param>
        /// <param name="endTime">The end period of the report</param>
        /// <param name="userId">User asking for the report</param>
        /// <param name="routeIds">The list of IDs representing routes to include in the report</param>
        /// <param name="teamIds">The list of IDs representing teams to include in the report</param>
        /// <param name="teamDetails">The level of details we want for Team (1=Summary  2=Routes  4=Plant Model)</param>
        /// <returns>List of Tasks Planning Report </returns>
        public List<TasksPlanning> GetData(string connectionString, int granularity, string startTime, string endTime, int? userId, string routeIds, string teamIds, int? teamDetails, string departments, string lines, string units, int topLevelId = 0, int subLevel = 0)
        {
            List<TasksPlanning> result = new List<TasksPlanning>();
            try
            {

                string fieldFilter = String.Empty, fieldValue = String.Empty;

                fieldFilter = 
                    granularity == Convert.ToInt32(Granularity.Department) ? "Department" 
                    : granularity == Convert.ToInt32(Granularity.MasterUnit) ? "Master" 
                    : granularity == Convert.ToInt32(Granularity.Line) ? "Line"
                    : "";

                fieldValue = 
                    granularity == Convert.ToInt32(Granularity.Department) ? departments 
                    : granularity == Convert.ToInt32(Granularity.MasterUnit) ? units 
                    : granularity == Convert.ToInt32(Granularity.Line) ? lines
                    : "";

                //granularity = granularity == 1 || granularity == 2 ? granularity : 3;

                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_Report_Planning", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@Granularity", granularity));
                    command.Parameters.Add(new SqlParameter("@TopLevelID", topLevelId));
                    command.Parameters.Add(new SqlParameter("@SubLevel", subLevel));
                    command.Parameters.Add(new SqlParameter("@StartTime", startTime));
                    command.Parameters.Add(new SqlParameter("@EndTime", endTime));
                    command.Parameters.Add(new SqlParameter("@UserId", userId ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@RouteIds", routeIds ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@TeamIds", teamIds ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@TeamDetail", teamDetails ?? (object)DBNull.Value));

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            TasksPlanning temp = new TasksPlanning();

                            if (String.IsNullOrEmpty(fieldFilter) || (!String.IsNullOrEmpty(fieldFilter) & reader.GetString(reader.GetOrdinal(fieldFilter)) == fieldValue))
                            {
                                if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                                    temp.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));
                                if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                                    temp.Team = reader.GetString(reader.GetOrdinal("Team"));
                                if (!reader.IsDBNull(reader.GetOrdinal("Route")))
                                    temp.Route = reader.GetString(reader.GetOrdinal("Route"));
                                if (!reader.IsDBNull(reader.GetOrdinal("Department")))
                                    temp.Department = reader.GetString(reader.GetOrdinal("Department"));
                                if (!reader.IsDBNull(reader.GetOrdinal("Line")))
                                    temp.Line = reader.GetString(reader.GetOrdinal("Line"));
                                if (!reader.IsDBNull(reader.GetOrdinal("Master")))
                                    temp.MasterUnit = reader.GetString(reader.GetOrdinal("Master"));
                                if (!reader.IsDBNull(reader.GetOrdinal("Slave")))
                                    temp.SlaveUnit = reader.GetString(reader.GetOrdinal("Slave"));
                                if (!reader.IsDBNull(reader.GetOrdinal("TaskId")))
                                    temp.TaskId = reader.GetString(reader.GetOrdinal("TaskId"));
                                if (!reader.IsDBNull(reader.GetOrdinal("Task")))
                                    temp.Task = reader.GetString(reader.GetOrdinal("Task"));
                                if (!reader.IsDBNull(reader.GetOrdinal("ProjectedScheduleDate")))
                                    temp.ProjectedScheduleDate = reader.GetString(reader.GetOrdinal("ProjectedScheduleDate"));
                                if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                                    temp.FL1 = reader.GetString(reader.GetOrdinal("FL1"));
                                if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                                    temp.FL2 = reader.GetString(reader.GetOrdinal("FL2"));
                                if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                                    temp.FL3 = reader.GetString(reader.GetOrdinal("FL3"));
                                if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                                    temp.FL4 = reader.GetString(reader.GetOrdinal("FL4"));
                                if (!reader.IsDBNull(reader.GetOrdinal("Duration")))
                                    temp.Duration = reader.GetString(reader.GetOrdinal("Duration"));
                                if (!reader.IsDBNull(reader.GetOrdinal("LongTaskName")))
                                    temp.LongTaskName = reader.GetString(reader.GetOrdinal("LongTaskName"));
                                if (!reader.IsDBNull(reader.GetOrdinal("TaskType")))
                                    temp.TaskType = reader.GetString(reader.GetOrdinal("TaskType"));
                                if (!reader.IsDBNull(reader.GetOrdinal("Lubricant")))
                                    temp.Lubricant = reader.GetString(reader.GetOrdinal("Lubricant"));
                                if (!reader.IsDBNull(reader.GetOrdinal("TaskFreq")))
                                    temp.TaskFrequency = reader.GetString(reader.GetOrdinal("TaskFreq"));
                                if (!reader.IsDBNull(reader.GetOrdinal("LateTime")))
                                    temp.LateTime = reader.GetString(reader.GetOrdinal("LateTime"));
                                if (!reader.IsDBNull(reader.GetOrdinal("ExternalLink")))
                                    temp.ExternalLink = reader.GetString(reader.GetOrdinal("ExternalLink"));

                                result.Add(temp);
                            }

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


        /// <summary>
        /// 
        /// </summary>
        /// <param name="connectionString">ConnectionString to database</param>
        /// <param name="varId"></param>
        /// <param name="granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="topLevelId">The Id from which the report was initiated, before drill-down</param>
        /// <param name="subLevel">The id of the current level being drilled-down</param>
        /// <param name="startTime">The beginning period of the report</param>
        /// <param name="endTime">The end period of the report</param>
        /// <param name="userId">User asking for the report</param>
        /// <param name="routeIds">The list of IDs representing routes to include in the report</param>
        /// <param name="teamIds">The list of IDs representing teams to include in the report</param>
        /// <param name="teamDetails">The level of details we want for Team (1=Summary  2=Routes  4=Plant Model)</param>
        /// <returns>Tasks Planning Report Detail</returns>
        public List<TasksPlanning> GetDetail(string connectionString, int varId, int granularity, string startTime, string endTime, int? userId, string routeIds, string teamIds, int? teamDetails, int topLevelId = 0, int subLevel = 0)
        {
            List<TasksPlanning> result = new List<TasksPlanning>();
            try
            {

                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_GetTaskPlanningDetails", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@VarId", varId));
                    command.Parameters.Add(new SqlParameter("@Granularity", granularity));
                    command.Parameters.Add(new SqlParameter("@TopLevelID", topLevelId));
                    command.Parameters.Add(new SqlParameter("@SubLevel", subLevel));
                    command.Parameters.Add(new SqlParameter("@StartTime", startTime));
                    command.Parameters.Add(new SqlParameter("@EndTime", endTime));
                    command.Parameters.Add(new SqlParameter("@UserId", userId ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@RouteIds", routeIds ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@TeamIds", teamIds ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@TeamDetail", teamDetails ?? (object)DBNull.Value));

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            TasksPlanning temp = new TasksPlanning();

                            if (!reader.IsDBNull(reader.GetOrdinal("VarID")))
                                temp.VarId = reader.GetInt32(reader.GetOrdinal("VarID"));
                            if (!reader.IsDBNull(reader.GetOrdinal("TaskName")))
                                temp.Task = reader.GetString(reader.GetOrdinal("TaskName"));
                            if (!reader.IsDBNull(reader.GetOrdinal("LongTaskName")))
                                temp.LongTaskName = reader.GetString(reader.GetOrdinal("LongTaskName"));
                            if (!reader.IsDBNull(reader.GetOrdinal("TaskAction")))
                                temp.TaskAction = reader.GetString(reader.GetOrdinal("TaskAction"));
                            if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                                temp.FL1 = reader.GetString(reader.GetOrdinal("FL1"));
                            if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                                temp.FL2 = reader.GetString(reader.GetOrdinal("FL2"));
                            if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                                temp.FL3 = reader.GetString(reader.GetOrdinal("FL3"));
                            if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                                temp.FL4 = reader.GetString(reader.GetOrdinal("FL4"));
                            if (!reader.IsDBNull(reader.GetOrdinal("TaskId")))
                                temp.TaskId = reader.GetString(reader.GetOrdinal("TaskId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("TaskFreq")))
                                temp.TaskFrequency = reader.GetString(reader.GetOrdinal("TaskFreq"));
                            if (!reader.IsDBNull(reader.GetOrdinal("TaskType")))
                                temp.TaskType = reader.GetString(reader.GetOrdinal("TaskType"));
                            if (!reader.IsDBNull(reader.GetOrdinal("EntryOn")))
                                temp.EntryOn = reader.GetDateTime(reader.GetOrdinal("EntryOn"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Criteria")))
                                temp.Criteria = reader.GetString(reader.GetOrdinal("Criteria"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Hazards")))
                                temp.Hazards = reader.GetString(reader.GetOrdinal("Hazards"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Method")))
                                temp.Method = reader.GetString(reader.GetOrdinal("Method"));
                            if (!reader.IsDBNull(reader.GetOrdinal("PPE")))
                                temp.PPE = reader.GetString(reader.GetOrdinal("PPE"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Tools")))
                                temp.Tools = reader.GetString(reader.GetOrdinal("Tools"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Lubricant")))
                                temp.Lubricant = reader.GetString(reader.GetOrdinal("Lubricant"));
                            
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
