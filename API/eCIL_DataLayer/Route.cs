using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Web.Management;

namespace eCIL_DataLayer
{
    public class Route
    {
        #region Variables
        private int routeId;
        private string routeDesc;
        private Boolean isCreateActivity;
        private int activityTrigger;
        #endregion

        #region Properties
        public int RouteId { get => routeId; set => routeId = value; }
        public string RouteDesc { get => routeDesc; set => routeDesc = value; }
        public Boolean IsCreateActivity { get => isCreateActivity; set => isCreateActivity = value; }
        public int ActivityTrigger { get => activityTrigger; set => activityTrigger = value; }
        #endregion

        #region SubClasses
        public class RouteTeams
        {
            #region Variables
            private bool selected;
            private int teamId;
            private string teamDesc;
            #endregion

            #region Properties
            public bool Selected { get => selected; set => selected = value; }
            public int TeamId { get => teamId; set => teamId = value; }
            public string TeamDesc { get => teamDesc; set => teamDesc = value; }
            #endregion
        }

        public class RouteTasks
        {
            #region Variables
            private int id;
            private int parentId;
            private int level;
            private int itemId;
            private string itemDesc;
            private int taskOrder;
            private bool selected;
            private string line;
            private string masterUnit;
            private string slaveUnit;
            private string group;
            private int lineId;
            #endregion

            #region Properties
            public int Id { get => id; set => id = value; }
            public int ParentId { get => parentId; set => parentId = value; }
            public int Level { get => level; set => level = value; }
            public int ItemId { get => itemId; set => itemId = value; }
            public string ItemDesc { get => itemDesc; set => itemDesc = value; }
            public int TaskOrder { get => taskOrder; set => taskOrder = value; }
            public bool Selected { get => selected; set => selected = value; }
            public string Line { get => line; set => line = value; }
            public string MasterUnit { get => masterUnit; set => masterUnit = value; }
            public string SlaveUnit { get => slaveUnit; set => slaveUnit = value; }
            public string Group { get => group; set => group = value; }
            public int LineId { get => lineId; set => lineId = value; }
            #endregion
        }

        public class RoutesSummary
        {
            #region Variables
            private int routeId;
            private string routeDescription;
            private int nbrItems;
            private int nbrTasks;
            #endregion

            #region Properties
            public int RouteId { get => routeId; set => routeId = value; }
            public string RouteDescription { get => routeDescription; set => routeDescription = value; }
            public int NbrTeams { get => nbrItems; set => nbrItems = value; }
            public int NbrTasks { get => nbrTasks; set => nbrTasks = value; }
            #endregion
        }

        public class ReportRouteTeams
        {
            #region Variables
            private string route;
            private int teamId;
            private string team;
            #endregion

            #region Properties
            public string Route { get => route; set => route = value; }
            public int TeamId { get => teamId; set => teamId = value; }
            public string Team { get => team; set => team = value; }
            #endregion
        }

        public class ReportRouteTasks
        {
            #region Variables
            private string route;
            private string line;
            private string masterUnit;
            private string slaveUnit;
            private string group;
            private string task;
            private int taskOrder;
            #endregion

            #region Properties
            public string Route { get => route; set => route = value; }
            public string Line { get => line; set => line = value; }
            public string MasterUnit { get => masterUnit; set => masterUnit = value; }
            public string SlaveUnit { get => slaveUnit; set => slaveUnit = value; }
            public string Group { get => group; set => group = value; }
            public string Task { get => task; set => task = value; }
            public int TaskOrder { get => taskOrder; set => taskOrder = value; }
            #endregion
        }

        public class RouteAssociations
        {
            #region Variables
            private int routeId;
            private string idList;

            #endregion

            #region Properties
            public int RouteId { get => routeId; set => routeId = value; }
            public string IdList { get => idList; set => idList = value; }

            #endregion
        }
        #endregion

        #region Methods
        public Route()
        {
            routeId = 0;
            routeDesc = "";
        }
        public Route(int id, string desc)
        {
            routeId = id;
            routeDesc = desc;
        }

        //Get the list of Routes
        public List<Route> GetAllRoutes(string _connectionString)
        {
            var result = new List<Route>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetRoutes", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        result.Add(new Route(reader.GetInt32(0), reader.GetString(1)));
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Get the list of Teams related to a Route
        public List<RouteTeams> GetRouteTeams(string _connectionString, int routeId)
        {
            List<RouteTeams> result = new List<RouteTeams>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetRouteTeams", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@RouteId", routeId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        RouteTeams temp = new RouteTeams();

                        if (!reader.IsDBNull(reader.GetOrdinal("Selected")))
                            temp.Selected = reader.GetBoolean(reader.GetOrdinal("Selected"));
                        if (!reader.IsDBNull(reader.GetOrdinal("TeamId")))
                            temp.TeamId = reader.GetInt32(reader.GetOrdinal("TeamId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("TeamDesc")))
                            temp.TeamDesc = reader.GetString(reader.GetOrdinal("TeamDesc"));
                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Get the Plant Model associated to the Line(s) by the Route. Returns also other lines not associated
        public List<RouteTasks> GetRouteTasks(string _connectionString, int routeId, string lineIds = null)
        {
            List<RouteTasks> result = new List<RouteTasks>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetRouteTasks", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@RouteId", routeId));
                command.Parameters.Add(new SqlParameter("@LineIds", lineIds ?? (object)DBNull.Value));

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        RouteTasks temp = new RouteTasks();

                        if (!reader.IsDBNull(reader.GetOrdinal("Id")))
                            temp.Id = reader.GetInt32(reader.GetOrdinal("Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ParentId")))
                        {
                            int tempId = reader.GetInt32(reader.GetOrdinal("Id"));
                            int tempParentId = reader.GetInt32(reader.GetOrdinal("ParentId"));

                            temp.ParentId = tempId == tempParentId ? 0 : tempParentId;
                        }
                        if (!reader.IsDBNull(reader.GetOrdinal("Level")))
                            temp.Level = reader.GetInt32(reader.GetOrdinal("Level"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ItemId")))
                            temp.ItemId = reader.GetInt32(reader.GetOrdinal("ItemId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ItemDesc")))
                            temp.ItemDesc = reader.GetString(reader.GetOrdinal("ItemDesc"));
                        if (!reader.IsDBNull(reader.GetOrdinal("TaskOrder")))
                            temp.TaskOrder = reader.GetInt32(reader.GetOrdinal("TaskOrder"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Selected")))
                            temp.Selected = reader.GetInt32(reader.GetOrdinal("Selected")) == 1 ? true : false;
                        if (!reader.IsDBNull(reader.GetOrdinal("Line")))
                            temp.Line = reader.GetString(reader.GetOrdinal("Line"));
                        if (!reader.IsDBNull(reader.GetOrdinal("MasterUnit")))
                            temp.MasterUnit = reader.GetString(reader.GetOrdinal("MasterUnit"));
                        if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnit")))
                            temp.SlaveUnit = reader.GetString(reader.GetOrdinal("SlaveUnit"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Group")))
                            temp.Group = reader.GetString(reader.GetOrdinal("Group"));
                        if (!reader.IsDBNull(reader.GetOrdinal("LineId")))
                            temp.LineId = reader.GetInt32(reader.GetOrdinal("LineId"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Get the Routes for which a user is member
        public List<Route> GetMyRoutes(string _connectionString, int userId)
        {
            var result = new List<Route>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetRoutes", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@UserId", userId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        result.Add(new Route(reader.GetInt32(0), reader.GetString(1)));
                    }
                }
            }
            return result;
        }

        //Get the list of all routes, including statistics for each route
        //Statitistics include : Number of Teams referencing the Route and Number of Tasks related to the Route
        public List<RoutesSummary> GetRoutesSummary(string _connectionString)
        {
            List<RoutesSummary> result = new List<RoutesSummary>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_RoutesSummary", conn);
                command.CommandType = CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        RoutesSummary temp = new RoutesSummary();

                        if (!reader.IsDBNull(reader.GetOrdinal("RouteId")))
                            temp.RouteId = reader.GetInt32(reader.GetOrdinal("RouteId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("RouteDescription")))
                            temp.RouteDescription = reader.GetString(reader.GetOrdinal("RouteDescription"));
                        if (!reader.IsDBNull(reader.GetOrdinal("NbrTeams")))
                            temp.NbrTeams = reader.GetInt32(reader.GetOrdinal("NbrTeams"));
                        if (!reader.IsDBNull(reader.GetOrdinal("NbrTasks")))
                            temp.NbrTasks = reader.GetInt32(reader.GetOrdinal("NbrTasks"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Teams associated to the Route received as parameter
        public List<ReportRouteTeams> GetReportRouteTeams(string _connectionString, int routeId)
        {
            List<ReportRouteTeams> result = new List<ReportRouteTeams>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportRouteTeams", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@RouteId", routeId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportRouteTeams temp = new ReportRouteTeams();

                        if (!reader.IsDBNull(reader.GetOrdinal("Route")))
                            temp.Route = reader.GetString(reader.GetOrdinal("Route"));
                        if (!reader.IsDBNull(reader.GetOrdinal("TeamId")))
                            temp.TeamId = reader.GetInt32(reader.GetOrdinal("TeamId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                            temp.Team = reader.GetString(reader.GetOrdinal("Team"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Get the list of all Tasks related to a Route
        public List<ReportRouteTasks> GetReportRouteTasks(string _connectionString, int routeId)
        {
            List<ReportRouteTasks> result = new List<ReportRouteTasks>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportRouteTasks", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@RouteId", routeId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportRouteTasks temp = new ReportRouteTasks();

                        if (!reader.IsDBNull(reader.GetOrdinal("Route")))
                            temp.Route = reader.GetString(reader.GetOrdinal("Route"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Line")))
                            temp.Line = reader.GetString(reader.GetOrdinal("Line"));
                        if (!reader.IsDBNull(reader.GetOrdinal("MasterUnit")))
                            temp.MasterUnit = reader.GetString(reader.GetOrdinal("MasterUnit"));
                        if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnit")))
                            temp.SlaveUnit = reader.GetString(reader.GetOrdinal("SlaveUnit"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Group")))
                            temp.Group = reader.GetString(reader.GetOrdinal("Group"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Task")))
                            temp.Task = reader.GetString(reader.GetOrdinal("Task"));
                        if (!reader.IsDBNull(reader.GetOrdinal("TaskOrder")))
                            temp.TaskOrder = reader.GetInt32(reader.GetOrdinal("TaskOrder"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Teams associated to all Routes
        public List<ReportRouteTeams> GetReportAllRouteTeams(string _connectionString)
        {
            List<ReportRouteTeams> result = new List<ReportRouteTeams>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportAllRouteTeams", conn);
                command.CommandType = CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportRouteTeams temp = new ReportRouteTeams();

                        if (!reader.IsDBNull(reader.GetOrdinal("Route")))
                            temp.Route = reader.GetString(reader.GetOrdinal("Route"));
                        if (!reader.IsDBNull(reader.GetOrdinal("TeamId")))
                            temp.TeamId = reader.GetInt32(reader.GetOrdinal("TeamId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                            temp.Team = reader.GetString(reader.GetOrdinal("Team"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the Is create activity for Route 
        public Route GetReportRouteActivity(string _connectionString, int routeId)
        {
            Route result = new Route();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "select * from Local_PG_eCIL_RouteSheetInfo where Route_Id=" + routeId;
                SqlCommand command = new SqlCommand(sql, conn);

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {

                        if (!reader.IsDBNull(reader.GetOrdinal("Route_Id")))
                            result.routeId = reader.GetInt32(reader.GetOrdinal("Route_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("IsCreateActivity")))
                            result.IsCreateActivity = reader.GetBoolean(reader.GetOrdinal("IsCreateActivity"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Trigger_Option_Id")))
                            result.ActivityTrigger = reader.GetInt32(reader.GetOrdinal("Trigger_Option_Id"));

                    }
                    reader.Close();
                }
                conn.Close();
            }
            return result;
        }

        //Returns the list of all Tasks associated to all Routes
        public List<ReportRouteTasks> GetReportAllRouteTasks(string _connectionString)
        {
            List<ReportRouteTasks> result = new List<ReportRouteTasks>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportAllRouteTasks", conn);
                command.CommandType = CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportRouteTasks temp = new ReportRouteTasks();

                        if (!reader.IsDBNull(reader.GetOrdinal("Route")))
                            temp.Route = reader.GetString(reader.GetOrdinal("Route"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Line")))
                            temp.Line = reader.GetString(reader.GetOrdinal("Line"));
                        if (!reader.IsDBNull(reader.GetOrdinal("MasterUnit")))
                            temp.MasterUnit = reader.GetString(reader.GetOrdinal("MasterUnit"));
                        if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnit")))
                            temp.SlaveUnit = reader.GetString(reader.GetOrdinal("SlaveUnit"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Group")))
                            temp.Group = reader.GetString(reader.GetOrdinal("Group"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Task")))
                            temp.Task = reader.GetString(reader.GetOrdinal("Task"));
                        if (!reader.IsDBNull(reader.GetOrdinal("TaskOrder")))
                            temp.TaskOrder = reader.GetInt32(reader.GetOrdinal("TaskOrder"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Creates a new Route
        public string AddRoute(string _connectionString, Route route)
        {
            if (route.RouteDesc == null || route.RouteDesc == "")
                throw new Exception("The parameter Route Description should be supplied");

            SqlParameter ParamRouteId = new SqlParameter();
            ParamRouteId.ParameterName = "@RouteId";
            ParamRouteId.DbType = DbType.Int32;
            ParamRouteId.Direction = ParameterDirection.Output;
            ParamRouteId.Value = DBNull.Value;

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    command.CommandText = "spLocal_eCIL_CreateRoute";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@RouteDesc", route.RouteDesc));
                    command.Parameters.Add(ParamRouteId);
                    command.ExecuteNonQuery();
                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    try
                    {
                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }

            return "The route was saved";
        }

        //check if route exist

        public string CheckRouteActivity(string _connectionString, Route route)
        {
            if (route.RouteDesc == null || route.RouteDesc == "")
                throw new Exception("The parameter Route Description should be supplied");

            string SaveActivitySQL = "select count(*) from Local_PG_eCIL_RouteSheetInfo where Route_Id= @param1";
            string IsRouteExist;
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand(SaveActivitySQL, conn);
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                cmd.Connection = conn;
                cmd.Transaction = transaction;

                try
                {
                    cmd.Parameters.Add("@param1", SqlDbType.VarChar).Value = route.RouteId;

                    cmd.CommandType = CommandType.Text;
                    IsRouteExist = cmd.ExecuteScalar().ToString();
                    // int.TryParse(Result, out count);
                    transaction.Commit();
                    //return "1";
                }
                catch (Exception ex)
                {
                    try
                    {

                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }
            return IsRouteExist;
        }

        //Save Activity details
        public string SaveRouteActivity(string _connectionString, Route route)
        {
            if (route.RouteDesc == null || route.RouteDesc == "")
                throw new Exception("The parameter Route Description should be supplied");

            string IsRouteExist = CheckRouteActivity(_connectionString, route);
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string SqlQuery;
                if (IsRouteExist == "1")
                {
                    SqlQuery = "UPDATE Local_PG_eCIL_RouteSheetInfo set IsCreateActivity = @param2,Trigger_Option_Id = @param3 where Route_Id=@param1 ";
                }
                else
                {
                    SqlQuery = "INSERT INTO Local_PG_eCIL_RouteSheetInfo (Route_Id,IsCreateActivity,Trigger_Option_Id) VALUES(@param1,@param2,@param3)";
                }
                SqlCommand cmd = new SqlCommand(SqlQuery, conn);
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                cmd.Connection = conn;
                cmd.Transaction = transaction;

                try
                {
                    cmd.Parameters.Add("@param1", SqlDbType.VarChar).Value = route.RouteId;
                    cmd.Parameters.Add("@param2", SqlDbType.VarChar).Value = route.isCreateActivity;
                    cmd.Parameters.Add("@param3", SqlDbType.VarChar).Value = route.activityTrigger;
                    cmd.CommandType = CommandType.Text;
                    cmd.ExecuteNonQuery();
                    transaction.Commit();
                    //return "1";
                }
                catch (Exception ex)
                {
                    try
                    {

                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }
            return "Activity Data is saved";
        }

        //Creates display for the route or rename display
        public string CreateRouteDisplay(string _connectionString, Route route, Int64 UserId, string ServerName, string url)
        {
            if (route.RouteDesc == null || route.RouteDesc == "")
                throw new Exception("The parameter Route Description should be supplied");
            string SecurityGroupName = ServerName.Substring(7, ServerName.Length - 8);
            SaveRouteActivity(_connectionString, route);

            SqlParameter NewSheetId = new SqlParameter();
            NewSheetId.ParameterName = "@NewSheetId";
            NewSheetId.DbType = DbType.Int32;
            NewSheetId.Direction = ParameterDirection.Output;
            NewSheetId.Value = DBNull.Value;

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    if (route.IsCreateActivity == true)
                    {
                        command.CommandText = "dbo.spLocal_eCIL_RouteDisplayCreation";
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.Add(new SqlParameter("@Sheet_Desc", route.RouteDesc));
                        command.Parameters.Add(new SqlParameter("@UserId", UserId));
                        command.Parameters.Add(new SqlParameter("@IsCreateActivity", route.IsCreateActivity));
                        command.Parameters.Add(new SqlParameter("@RouteId", route.routeId));
                        command.Parameters.Add(new SqlParameter("@ServerName", SecurityGroupName));
                        command.Parameters.Add(new SqlParameter("@Serverlink", url));
                        command.Parameters.Add(NewSheetId);
                    }
                    else
                    {
                        command.CommandText = "spLocal_eCIL_ObsoleteRouteDisplay";
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.Add(new SqlParameter("@RouteId", route.RouteId));
                        command.Parameters.Add(new SqlParameter("@UserId", UserId));

                    }
                    command.ExecuteNonQuery();
                    transaction.Commit();

                }
                catch (Exception ex)
                {
                    try
                    {
                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }

            return "The display for route is created";
        }

        //Update the description of a Sheet when route description is modified
        public string UpdateSheetDesc(string _connectionString, Route route, Int64 UserId)
        {
            if (route.RouteId == 0)
                throw new Exception("The parameter Route Id should be supplied");

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    command.CommandText = "spLocal_eCIL_UpdateRouteSheet";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@RouteId", route.RouteId));
                    command.Parameters.Add(new SqlParameter("@NewSheetDescription", route.RouteDesc));
                    command.Parameters.Add(new SqlParameter("@UserId", UserId));
                    command.ExecuteNonQuery();
                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    try
                    {
                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }

            return "The sheet description was updated";
        }

        //Update the description of a Route
        public string UpdateRoute(string _connectionString, Route route)
        {
            if (route.RouteId == 0)
                throw new Exception("The parameter Route Id should be supplied");

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    command.CommandText = "spLocal_eCIL_UpdateRoute";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@RouteId", route.RouteId));
                    command.Parameters.Add(new SqlParameter("@NewRouteDescription", route.RouteDesc));
                    command.ExecuteNonQuery();
                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    try
                    {
                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }

            return "The route was updated";
        }

        //Delete Route information (Route_Desc, Units, UnitOrder)
        public string DeleteRoute(string _connectionString, string routeIds, int UserId)
        {
            //if (routeId == 0)
            //    throw new Exception("The parameter Route Id should be supplied");

            var tempIds = routeIds.Split(new String[] { "," }, StringSplitOptions.None);

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                foreach (string routeId in tempIds)
                {
                    SqlCommand command = new SqlCommand();
                    SqlTransaction transaction;

                    transaction = conn.BeginTransaction("StartTransaction");

                    command.Connection = conn;
                    command.Transaction = transaction;

                    try
                    {
                        command.CommandText = "spLocal_eCIL_ObsoleteRouteDisplay";
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.Add(new SqlParameter("@RouteId", Convert.ToInt32(routeId)));
                        command.Parameters.Add(new SqlParameter("@UserId", UserId));
                        command.ExecuteNonQuery();
                        command.Parameters.Clear();

                        command.CommandText = "spLocal_eCIL_DeleteRoute";
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.Add(new SqlParameter("@RouteId", Convert.ToInt32(routeId)));
                        command.ExecuteNonQuery();
                        transaction.Commit();
                    }
                    catch (Exception ex)
                    {
                        try
                        {
                            transaction.Rollback();
                        }
                        catch (Exception ex2)
                        {
                            conn.Close();
                            throw new Exception(ex2.Message);
                        }

                        conn.Close();
                        throw new Exception(ex.Message);
                    }

                }

                conn.Close();
            }

            return "The routes was deleted";
        }

        //Save Route-Teams associations
        public string UpdateRouteTeamsAssociations(string _connectionString, RouteAssociations route)
        {
            //The maximum allowed by the @TeamIDsList parameter of the SP is 8000 characters
            if (!String.IsNullOrEmpty(route.IdList))
            {
                if (route.IdList.Length > 8000)
                {
                    throw new Exception("Too many teams selected. Cannot save");
                }
            }

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    command.CommandText = "spLocal_eCIL_UpdateRouteTeams";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@RouteId", route.RouteId));
                    command.Parameters.Add(new SqlParameter("@TeamIDsList", String.IsNullOrEmpty(route.IdList) ? (object)DBNull.Value : route.IdList));
                    command.ExecuteNonQuery();
                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    try
                    {
                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }

            return "The route-teams associations was updated";
        }

        //Save Route-Tasks associations
        public string UpdateRouteTasksAssociations(string _connectionString, RouteAssociations route)
        {
            //The maximum allowed by the @TaskIDsList parameter of the SP is 8000 characters
            if (!String.IsNullOrEmpty(route.IdList))
            {
                if (route.IdList.Length > 8000)
                {
                    throw new Exception("Too many tasks selected. Cannot save");
                }
            }

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    command.CommandText = "spLocal_eCIL_UpdateRouteTasks";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@RouteId", route.RouteId));
                    command.Parameters.Add(new SqlParameter("@TaskIDsList", String.IsNullOrEmpty(route.IdList) ? (object)DBNull.Value : route.IdList));
                    command.ExecuteNonQuery();
                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    try
                    {
                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }

            return "The route-tasks associations was updated";
        }


        //Save Display-Variable associations
        public string UpdateDisplayVariablesAssociations(string _connectionString, RouteAssociations route, Int64 UserId)
        {
            //The maximum allowed by the @TaskIDsList parameter of the SP is 8000 characters
            if (!String.IsNullOrEmpty(route.IdList))
            {
                if (route.IdList.Length > 8000)
                {
                    throw new Exception("Too many tasks selected. Cannot save");
                }
            }

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    command.CommandText = "spLocal_eCIL_UpdateDisplayVariables";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@RouteId", route.RouteId));
                    command.Parameters.Add(new SqlParameter("@TaskIDsList", String.IsNullOrEmpty(route.IdList) ? (object)DBNull.Value : route.IdList));
                    command.Parameters.Add(new SqlParameter("@UserId", UserId));

                    command.ExecuteNonQuery();
                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    try
                    {
                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }

            return "The display-variables associations was updated";
        }


        // Find Route Id
        public int FindRouteId(string _connectionString, int Var_Id)
        {
            int result = 0;
            string query = "SELECT Route_Id FROM dbo.Local_PG_eCIL_RouteTasks WHERE Var_Id = " + Var_Id;
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                SqlCommand command = new SqlCommand(query, connection);
                command.CommandType = CommandType.Text;
                connection.Open();
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        result = Convert.ToInt32(reader[0]);
                    }
                }
            }
            return result;
        }

        // Check if Route is IntegrateTour Route (If it has any CL tasks)
        public Boolean IsIntegratedTourRoute(string _connectionString, int Route_Id)
        {
            int count = 0;
            Boolean result = false;
            string query = "SELECT COUNT(*) AS ColumnCount FROM Local_PG_eCIL_RouteTasks rt " +
                "JOIN Variables_Base v ON  rt.Var_Id = v.Var_Id " +
                "JOIN Event_Subtypes es ON v.Event_Subtype_Id = es.Event_Subtype_Id" +
                " WHERE Event_Subtype_Desc NOT LIKE 'eCIL' AND Route_Id = " + Route_Id;
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                SqlCommand command = new SqlCommand(query, connection);
                command.CommandType = CommandType.Text;
                connection.Open();
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        if (!reader.IsDBNull(reader.GetOrdinal("ColumnCount")))
                            count = reader.GetInt32(reader.GetOrdinal("ColumnCount"));
                    }
                    if (count > 0)
                    {
                        result = true;
                    }
                }
            }
            return result;
        }

        // Check if Route is associated with any QR Code
        public Boolean CheckIfRouteHasQRCode(string _connectionString, string Route_Ids)
        {
            int count = 0;
            Boolean result = false;
            string query = "SELECT COUNT(QR_Id) AS TotalQR FROM Local_PG_eCIL_QRInfo WHERE Route_Ids LIKE '" + Route_Ids +"'";
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                SqlCommand command = new SqlCommand(query, connection);
                command.CommandType = CommandType.Text;
                connection.Open();
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        if (!reader.IsDBNull(reader.GetOrdinal("TotalQR")))
                            count = reader.GetInt32(reader.GetOrdinal("TotalQR"));
                    }
                    if (count > 0)
                    {
                        result = true;
                    }
                }
            }
            return result;

            #endregion

        }
    }
}
