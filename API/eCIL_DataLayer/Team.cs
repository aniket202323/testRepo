using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Web.Management;

namespace eCIL_DataLayer
{
    public class Team
    {
        #region Variables
        private int teamId;
        private string teamDesc;
        #endregion

        #region Properties
        public int TeamId { get => teamId; set => teamId = value; }
        public string TeamDesc { get => teamDesc; set => teamDesc = value; }
        #endregion

        #region SubClasses
        public class TeamUsers
        {
            #region Variables
            private bool selected;
            private int userId;
            private string userName;
            #endregion

            #region Properties
            public bool Selected { get => selected; set=> selected = value; }
            public int UserId { get => userId; set => userId = value; }
            public string Username { get => userName; set => userName = value; }
            #endregion
        }

        public class TeamTasks
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

        public class TeamRoutes
        {
            #region Variables
            private bool selected;
            private int routeId;
            private string routeDesc;
            #endregion

            #region Properties
            public bool Selected { get => selected; set => selected = value; }
            public int RouteId { get => routeId; set => routeId = value; }
            public string RouteDesc { get => routeDesc; set => routeDesc = value; }
            #endregion
        }

        public class TeamsSummary
        {
            #region Variables
            private int teamId;
            private string teamDescription;
            private int nbrRoutes;
            private int nbrTasks;
            private int nbrUsers;
            private int nbrCrews;
            #endregion

            #region Properties
            public int TeamId { get => teamId; set => teamId = value; }
            public string TeamDescription { get => teamDescription; set => teamDescription = value; }
            public int NbrRoutes { get => nbrRoutes; set => nbrRoutes = value; }
            public int NbrTasks { get => nbrTasks; set => nbrTasks = value; }
            public int NbrUsers { get => nbrUsers; set => nbrUsers = value; }
            public int NbrCrews { get => nbrCrews; set => nbrCrews = value; }
            #endregion
        }

        public class ReportTeamRoutes
        {
            #region Variables
            private string team;
            private int routeId;
            private string route;
            #endregion

            #region Properties
            public string Team { get => team; set => team = value; }
            public int RouteId { get => routeId; set => routeId = value; }
            public string Route { get => route; set => route = value; }
            #endregion
        }

        public class ReportTeamUser
        {
            #region Variables
            private string team;
            private string username;
            #endregion

            #region Properties
            public string Team { get => team; set => team = value; }
            public string Username { get => username; set => username = value; }
            #endregion
        }

        public class ReportTeamTasks
        {
            #region Variables
            private string team;
            private string line;
            private string masterUnit;
            private string slaveUnit;
            private string group;
            private string task;
            #endregion

            #region Properties
            public string Team { get => team; set => team = value; }
            public string Line { get => line; set => line = value; }
            public string MasterUnit { get => masterUnit; set => masterUnit = value; }
            public string SlaveUnit { get => slaveUnit; set => slaveUnit = value; }
            public string Group { get => group; set => group = value; }
            public string Task { get => task; set => task = value; }
            #endregion
        }

        public class ReportTeamUsersAssociations
        {
            #region Variables
            private string team;
            private int userId;
            private string userName;
            #endregion

            #region Properties
            public string Team { get => team; set => team = value; }
            public int UserId { get => userId; set => userId = value; }
            public string Username { get => userName; set => userName = value; }
            #endregion
        }

        public class ReportTeamCrewsAssociations
        {
            #region Variables
            private string team;
            private int teamId;
            private int lineId;
            private string line;
            private int routeId;
            private string route;
            private string crew;
            #endregion

            #region Variables
            public string Team { get => team; set => team = value; }
            public int TeamId { get => teamId; set => teamId = value; }
            public int LineId { get => lineId; set => lineId = value; }
            public string Line { get => line; set => line = value; }
            public int RouteId { get => routeId; set => routeId = value; }
            public string Route { get => route; set => route = value; }
            public string Crew { get => crew; set => crew = value; }
            #endregion
        }

        public class Crews
        {
            #region Variables
            private int lineId;
            private string crew;
            #endregion

            #region Properties
            public int LineId { get => lineId; set => lineId = value; }
            public string Crew { get => crew; set => crew = value; }
            #endregion

        }

        public class TeamsAssociations
        {
            #region Variables
            private int teamId;
            private string idList;
            #endregion

            #region Properties
            public int TeamId { get => teamId; set => teamId = value; }
            public string IdList { get => idList; set => idList = value; }
            #endregion
        }

        public class TeamCrewRoutes
        {
            #region Variables
            private int teamId;
            private int routeId;
            private int lineId;
            private string crewDesc;
            #endregion

            #region Properties
            public int TeamId { get => teamId; set => teamId = value; }
            public int RouteId { get => routeId; set => routeId = value; }
            public int LineId { get => lineId; set => lineId = value; }
            public string CrewDesc { get => crewDesc; set => crewDesc = value; }
            #endregion
        }
        #endregion

        #region Methods
        public Team()
        {
            TeamId = 0;
            TeamDesc = "";
        }
        public Team(int id, string value)
        {
            TeamId = id;
            TeamDesc = value;
        }

        //Returns the list of all Teams
        public List<Team> GetAllTeams(string _connectionString)
        {

            var result = new List<Team>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetTeams", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        result.Add(new Team(reader.GetInt32(0), reader.GetString(1)));
                    }
                    reader.Close();
                }
            }
            return result;

        }

        //Returns the list of Teams for which a User is associated to
        public List<Team> GetMyTeams(string _connectionString, int userId)
        {
            var result = new List<Team>();
           
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetTeams", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@UserId", userId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        result.Add(new Team(reader.GetInt32(0), reader.GetString(1)));

                    }
                }
            }
            return result;
        }

        //Get the list of Users related to a Team
        public List<TeamUsers> GetTeamUsers(string _connectionString, int teamId)
        {
            List<TeamUsers> result = new List<TeamUsers>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetTeamUsers", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@TeamId", teamId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        TeamUsers temp = new TeamUsers();

                        if (!reader.IsDBNull(reader.GetOrdinal("Selected")))
                            temp.Selected = reader.GetBoolean(reader.GetOrdinal("Selected"));
                        if (!reader.IsDBNull(reader.GetOrdinal("UserId")))
                            temp.UserId = reader.GetInt32(reader.GetOrdinal("UserId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Username")))
                            temp.Username = reader.GetString(reader.GetOrdinal("Username"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Get the list of Tasks related to a Team
        public List<TeamTasks> GetTeamTasks(string _connectionString, int teamId)
        {
            List<TeamTasks> result = new List<TeamTasks>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetTeamTasks", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@TeamId", teamId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        TeamTasks temp = new TeamTasks();

                        if (!reader.IsDBNull(reader.GetOrdinal("Id")))
                            temp.Id = reader.GetInt32(reader.GetOrdinal("Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ParentId")))
                            temp.ParentId = reader.GetInt32(reader.GetOrdinal("ParentId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Level")))
                            temp.Level = reader.GetInt32(reader.GetOrdinal("Level"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ItemId")))
                            temp.ItemId = reader.GetInt32(reader.GetOrdinal("ItemId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ItemDesc")))
                            temp.ItemDesc = reader.GetString(reader.GetOrdinal("ItemDesc"));
                        // if (!reader.IsDBNull(reader.GetOrdinal("TaskOrder")))
                        //     temp.TaskOrder = reader.GetInt32(reader.GetOrdinal("TaskOrder"));
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

        //Get the list of Routes related to a Team
        public List<TeamRoutes> GetTeamRoutes(string _connectionString, int teamId)
        {
            List<TeamRoutes> result = new List<TeamRoutes>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetTeamRoutes", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@TeamId", teamId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        TeamRoutes temp = new TeamRoutes();

                        if (!reader.IsDBNull(reader.GetOrdinal("Selected")))
                            temp.Selected = reader.GetBoolean(reader.GetOrdinal("Selected"));
                        if (!reader.IsDBNull(reader.GetOrdinal("RouteId")))
                            temp.RouteId = reader.GetInt32(reader.GetOrdinal("RouteId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("RouteDesc")))
                            temp.RouteDesc = reader.GetString(reader.GetOrdinal("RouteDesc"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Get the list of all Teams, including statistics for each Team
        //Statitistics include : Number of Tasks referencing the Team and Number of Users related to the Team
        public List<TeamsSummary> GetTeamsSummary(string _connectionString)
        {
            List<TeamsSummary> result = new List<TeamsSummary>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_TeamsSummary", conn);
                command.CommandType = CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        TeamsSummary temp = new TeamsSummary();

                        if (!reader.IsDBNull(reader.GetOrdinal("TeamId")))
                            temp.TeamId = reader.GetInt32(reader.GetOrdinal("TeamId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("TeamDescription")))
                            temp.TeamDescription = reader.GetString(reader.GetOrdinal("TeamDescription"));
                        if (!reader.IsDBNull(reader.GetOrdinal("NbrRoutes")))
                            temp.NbrRoutes = reader.GetInt32(reader.GetOrdinal("NbrRoutes"));
                        if (!reader.IsDBNull(reader.GetOrdinal("NbrTasks")))
                            temp.NbrTasks = reader.GetInt32(reader.GetOrdinal("NbrTasks"));
                        if (!reader.IsDBNull(reader.GetOrdinal("NbrUsers")))
                            temp.NbrUsers = reader.GetInt32(reader.GetOrdinal("NbrUsers"));
                        if (!reader.IsDBNull(reader.GetOrdinal("NbrCrews")))
                            temp.NbrCrews = reader.GetInt32(reader.GetOrdinal("NbrCrews"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Routes associated to the Team received as parameter
        public List<ReportTeamRoutes> GetReportTeamRoutes(string _connectionString, int teamId)
        {
            List<ReportTeamRoutes> result = new List<ReportTeamRoutes>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportTeamRoutes", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@TeamId", teamId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportTeamRoutes temp = new ReportTeamRoutes();

                        if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                            temp.Team = reader.GetString(reader.GetOrdinal("Team"));
                        if (!reader.IsDBNull(reader.GetOrdinal("RouteId")))
                            temp.RouteId = reader.GetInt32(reader.GetOrdinal("RouteId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Route")))
                            temp.Route = reader.GetString(reader.GetOrdinal("Route"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Routes associated to all Teams
        public List<ReportTeamRoutes> GetReportAllTeamRoutes(string _connectionString)
        {
            List<ReportTeamRoutes> result = new List<ReportTeamRoutes>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportAllTeamRoutes", conn);
                command.CommandType = CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportTeamRoutes temp = new ReportTeamRoutes();

                        if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                            temp.Team = reader.GetString(reader.GetOrdinal("Team"));
                        if (!reader.IsDBNull(reader.GetOrdinal("RouteId")))
                            temp.RouteId = reader.GetInt32(reader.GetOrdinal("RouteId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Route")))
                            temp.Route = reader.GetString(reader.GetOrdinal("Route"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Users associated to all Teams
        public List<ReportTeamUser> GetReportAllTeamUsers(string _connectionString)
        {
            List<ReportTeamUser> result = new List<ReportTeamUser>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportAllTeamUsers", conn);
                command.CommandType = CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportTeamUser temp = new ReportTeamUser();

                        if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                            temp.Team = reader.GetString(reader.GetOrdinal("Team"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Username")))
                            temp.Username = reader.GetString(reader.GetOrdinal("Username"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Tasks associated to all Teams
        public List<ReportTeamTasks> GetReportAllTeamTasks(string _connectionString)
        {
            List<ReportTeamTasks> result = new List<ReportTeamTasks>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportAllTeamTasks", conn);
                command.CommandType = CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportTeamTasks temp = new ReportTeamTasks();

                        if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                            temp.Team = reader.GetString(reader.GetOrdinal("Team"));
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

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Tasks associated to the Team received as parameter
        public List<ReportTeamTasks> GetReportTeamTasks(string _connectionString, int? teamId = null)
        {
            List<ReportTeamTasks> result = new List<ReportTeamTasks>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportTeamTasks", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@TeamId", teamId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportTeamTasks temp = new ReportTeamTasks();

                        if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                            temp.Team = reader.GetString(reader.GetOrdinal("Team"));
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
                        //we will not add obsoleted tasks because will cause error into the UI
                        //obsoleted tasks have the same ItemId
                        //if(!temp.Task.StartsWith("z_obs_")) 
                            result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Users associated to the Team received as parameter
        public List<ReportTeamUsersAssociations> GetReportTeamUsers(string _connectionString, int? teamId = null)
        {
            List<ReportTeamUsersAssociations> result = new List<ReportTeamUsersAssociations>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportTeamUsers", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@TeamId", teamId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportTeamUsersAssociations temp = new ReportTeamUsersAssociations();

                        if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                            temp.Team = reader.GetString(reader.GetOrdinal("Team"));
                        if (!reader.IsDBNull(reader.GetOrdinal("UserId")))
                            temp.UserId = reader.GetInt32(reader.GetOrdinal("UserId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Username")))
                            temp.Username = reader.GetString(reader.GetOrdinal("Username"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Crews/Routes associated to the Team received as parameter
        public List<ReportTeamCrewsAssociations> GetReportTeamCrews(string _connectionString, int? teamId = null)
        {
            List<ReportTeamCrewsAssociations> result = new List<ReportTeamCrewsAssociations>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_ReportTeamCrews", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@TeamId", teamId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        ReportTeamCrewsAssociations temp = new ReportTeamCrewsAssociations();

                        if (!reader.IsDBNull(reader.GetOrdinal("Team")))
                            temp.Team = reader.GetString(reader.GetOrdinal("Team"));
                        if (!reader.IsDBNull(reader.GetOrdinal("TeamId")))
                            temp.TeamId = reader.GetInt32(reader.GetOrdinal("TeamId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("LineId")))
                            temp.LineId = reader.GetInt32(reader.GetOrdinal("LineId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Line")))
                            temp.Line = reader.GetString(reader.GetOrdinal("Line"));
                        if (!reader.IsDBNull(reader.GetOrdinal("RouteId")))
                            temp.RouteId = reader.GetInt32(reader.GetOrdinal("RouteId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Route")))
                            temp.Route = reader.GetString(reader.GetOrdinal("Route"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Crew")))
                            temp.Crew = reader.GetString(reader.GetOrdinal("Crew"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of all Crews
        public List<Crews> GetAllCrews(string _connectionString, int? lineId = null)
        {
            List<Crews> result = new List<Crews>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetAllCrews", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@LineId", lineId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        Crews temp = new Crews();

                        if (!reader.IsDBNull(reader.GetOrdinal("LineId")))
                            temp.LineId = reader.GetInt32(reader.GetOrdinal("LineId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Crew")))
                            temp.Crew = reader.GetString(reader.GetOrdinal("Crew"));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Creates a new Team
        public string AddTeam(string _connectionString, Team team)
        {
            if (team.TeamDesc == null || team.TeamDesc == "")
                throw new Exception("The parameter Route Description should be supplied");

            SqlParameter ParamTeamId = new SqlParameter();
            ParamTeamId.ParameterName = "@TeamId";
            ParamTeamId.DbType = DbType.Int32;
            ParamTeamId.Direction = ParameterDirection.Output;
            ParamTeamId.Value = DBNull.Value;

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
                    command.CommandText = "spLocal_eCIL_CreateTeam";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@TeamDesc", team.TeamDesc));
                    command.Parameters.Add(ParamTeamId);
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

            //if (ParamTeamId.Value != DBNull.Value)
            return "The team was saved";
        }

        //Update the description of a Team
        public string UpdateTeam(string _connectionString, Team team)
        {
            if (team.TeamId == 0)
                throw new Exception("The parameter Team Id should be supplied");

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
                    command.CommandText = "spLocal_eCIL_UpdateTeam";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@TeamId", team.TeamId));
                    command.Parameters.Add(new SqlParameter("@NewTeamDescription", team.TeamDesc));
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

            return "The team was updated";
        }

        //Delete Team information (Including relations to Tasks, Routes and Users)
        public string DeleteTeam(string _connectionString, string teamIds)
        {
            //if (teamId == 0)
            //    throw new Exception("The parameter Team Id should be supplied");

            var tempIds = teamIds.Split(new String[] { "," }, StringSplitOptions.None);

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                foreach (string teamId in tempIds)
                {
                    SqlCommand command = new SqlCommand();
                    SqlTransaction transaction;

                    transaction = conn.BeginTransaction("StartTransaction");

                    command.Connection = conn;
                    command.Transaction = transaction;

                    try
                    {
                        command.CommandText = "spLocal_eCIL_DeleteTeam";
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.Add(new SqlParameter("@TeamId", Convert.ToInt32(teamId)));
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

            return "The team was deleted";
        }

        //Save Team-Routes associations
        public string UpdateTeamRoutesAssociations(string _connectionString, TeamsAssociations team)
        {
            //The maximum allowed by the @RouteIDsList parameter of the SP is 8000 characters
            if (!String.IsNullOrEmpty(team.IdList))
            {
                if (team.IdList.Length > 8000)
                {
                    throw new Exception("Too many routes selected. Cannot save");
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
                    command.CommandText = "spLocal_eCIL_UpdateTeamRoutes";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@TeamId", team.TeamId));
                    command.Parameters.Add(new SqlParameter("@RouteIdsList", String.IsNullOrEmpty(team.IdList) ? (object)DBNull.Value : team.IdList));
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

            return "The team-routes associations was updated";
        }

        //Save Team-Users associations
        public string UpdateTeamUsersAssociations(string _connectionString, TeamsAssociations team)
        {
            //The maximum allowed by the @UserIDsList parameter of the SP is 8000 characters
            if (!String.IsNullOrEmpty(team.IdList))
            {
                if (team.IdList.Length > 8000)
                {
                    throw new Exception("Too many users selected. Cannot save");
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
                    command.CommandText = "spLocal_eCIL_UpdateTeamUsers";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@TeamId", team.TeamId));
                    command.Parameters.Add(new SqlParameter("@UserIdsList", String.IsNullOrEmpty(team.IdList) ? (object)DBNull.Value : team.IdList));
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

            return "The team-users associations was updated";
        }

        //Save Team-Tasks associations
        public string UpdateTeamTasksAssociations(string _connectionString, TeamsAssociations team)
        {
            //The maximum allowed by the @TaskIdsList parameter of the SP is 8000 characters
            if (!String.IsNullOrEmpty(team.IdList))
            {
                if (team.IdList.Length > 8000)
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
                    command.CommandText = "spLocal_eCIL_UpdateTeamTasks";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@TeamId", team.TeamId));
                    command.Parameters.Add(new SqlParameter("@TaskIdsList", String.IsNullOrEmpty(team.IdList) ? (object)DBNull.Value : team.IdList));
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

            return "The team-tasks associations was updated";
        }


        public string UpdateTeamCrewRoutes(string _connectionString, TeamCrewRoutes team)
        {

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
                    command.CommandText = "spLocal_eCIL_UpdateTeamCrewRoutes";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@TeamId", team.TeamId));
                    command.Parameters.Add(new SqlParameter("@RouteId", team.RouteId));
                    command.Parameters.Add(new SqlParameter("@LineId", team.LineId));
                    command.Parameters.Add(new SqlParameter("@CrewDesc", team.CrewDesc));
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

            return "The team-crew-routes was updated";
        }
        #endregion

    }
}
