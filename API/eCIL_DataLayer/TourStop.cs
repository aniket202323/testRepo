using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Web.Management;

namespace eCIL_DataLayer
{

    public class TourStopDetails {
         int tourId { get; set; }
         string tourDesc { get; set; }
         int routeId { get; set; }
         string routeDesc { get; set; }
         int tourOrder;

        #region Properties
        public int TourId { get => tourId; set => tourId = value; }
        public string TourDesc { get => tourDesc; set => tourDesc = value; }
        public string RouteDesc { get => routeDesc; set => routeDesc = value; }
        public int RouteId { get => routeId; set => routeId = value; }
        public int TourOrder { get => tourOrder; set => tourOrder = value; }
        #endregion
    }
    public class TourStopTask : TourStopDetails
    {
        private int varId;
        private int tourTaskOrder;
        
        #region Properties
        public int VarId { get => varId; set => varId = value; }
        public int TourTaskOrder { get => tourTaskOrder; set => tourTaskOrder = value; }
        #endregion
    }

    public class TourStopMap : TourStopDetails
    {
        private string tourMap;
        private int tourStopMapImageCount;

        #region Properties
        public string TourMap { get => tourMap; set => tourMap = value; }
        public int TourStopMapImageCount { get => tourStopMapImageCount; set => tourStopMapImageCount = value; }
        #endregion
    }
    public class TourStopInfo
    {
      
        #region Methods

        //Returns the list of all tourStops for specific route
        public List<TourStopTask> getTourStopInfo(string _connectionString, int routeId)
        {
            List<TourStopTask> result = new List<TourStopTask>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "select t.Tour_Stop_Id,t.Tour_Stop_Desc,r.Var_Id,r.Tour_Stop_Task_Order,t.Tour_Stop_Order from Local_PG_eCIL_RouteTasks r left join " +
                    "Local_PG_eCIL_TourStops t on t.Tour_Stop_Id = r.Tour_Stop_Id where r.Route_Id = @param1";
                SqlCommand command = new SqlCommand(sql, conn);
                command.Parameters.Add("@param1", SqlDbType.VarChar, 50).Value = routeId;

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        TourStopTask tourStop = new TourStopTask();

                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Id")))
                            tourStop.TourId = reader.GetInt32(reader.GetOrdinal("Tour_Stop_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Desc")))
                            tourStop.TourDesc = reader.GetString(reader.GetOrdinal("Tour_Stop_Desc"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Var_Id")))
                            tourStop.VarId = reader.GetInt32(reader.GetOrdinal("Var_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Task_Order")))
                            tourStop.TourTaskOrder = reader.GetInt32(reader.GetOrdinal("Tour_Stop_Task_Order"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Order")))
                            tourStop.TourOrder = reader.GetInt32(reader.GetOrdinal("Tour_Stop_Order"));
                      
                        result.Add(tourStop);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        public string getTourMapImage(string _connectionString, int tourId)
        {
            string tourMap = "";

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "SELECT Tour_Map_Link from Local_PG_eCIL_TourStops where Tour_Stop_Id = @param1";
                SqlCommand command = new SqlCommand(sql, conn);
                command.Parameters.Add("@param1", SqlDbType.VarChar, 50).Value = tourId;
              
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Map_Link")))
                            tourMap = reader.GetString(reader.GetOrdinal("Tour_Map_Link"));
                    }
                    reader.Close();
                }
            }
            return tourMap;
        }

        public int getTourMapImageCount(string _connectionString, string tourMap)
        {
            int tourStopMapImageCount = 0;
            if (tourMap == null || tourMap == "")
            {
                return tourStopMapImageCount;
            }
                

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "SELECT COUNT(*) as ImageCount from Local_PG_eCIL_TourStops where Tour_Map_Link = @param1";
                SqlCommand command = new SqlCommand(sql, conn);
                command.Parameters.Add("@param1", SqlDbType.VarChar, 50).Value = tourMap;

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        if (!reader.IsDBNull(reader.GetOrdinal("ImageCount")))
                            tourStopMapImageCount = reader.GetInt32(reader.GetOrdinal("ImageCount"));
                    }
                    reader.Close();
                }
            }
            return tourStopMapImageCount;
        }

        public List<TourStopMap> getTourStop(string _connectionString, int routeId)
        {
            List<TourStopMap> result = new List<TourStopMap>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "select * from Local_PG_eCIL_TourStops where Route_Id = @param1 order by Tour_Stop_Order asc";
                
                SqlCommand command = new SqlCommand(sql, conn);
               command.Parameters.Add("@param1", SqlDbType.VarChar, 50).Value = routeId;

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        TourStopMap tourStop = new TourStopMap();

                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Id")))
                            tourStop.TourId = reader.GetInt32(reader.GetOrdinal("Tour_Stop_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Desc")))
                            tourStop.TourDesc = reader.GetString(reader.GetOrdinal("Tour_Stop_Desc"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Map_Link")))
                            tourStop.TourMap = reader.GetString(reader.GetOrdinal("Tour_Map_Link"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Order")))
                            tourStop.TourOrder = reader.GetInt32(reader.GetOrdinal("Tour_Stop_Order"));
                        
                        result.Add(tourStop);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        #endregion

    }
    public class TourStop
    {
        #region Variables
        private int tourId;
        private string tourDesc;
        private string tourMap;
        private int routeId;
        private string taskIds;
        private int varId;
        private int tourOrder;
        private string tourIdsOrder;
        //private IFormFile tourImage { get; set; }
        
        #endregion

        #region Properties
        public int RouteId { get => routeId; set => routeId = value; }
        public string TourDesc { get => tourDesc; set => tourDesc = value; }
        public string TourMap { get => tourMap; set => tourMap = value; }
        public int TourId { get => tourId; set => tourId = value; }
        public string TaskIds { get => taskIds; set => taskIds = value; }
        public int VarId { get => varId; set => varId = value; }
        public int TourOrder { get => tourOrder; set => tourOrder = value; }
        public string TourIdsOrder { get => tourIdsOrder; set => tourIdsOrder = value; }

        #endregion



        #region Methods


        //Creates a new Route
        public int AddTourStop(string _connectionString, TourStop tour)
        {
            int TourID = 0;
            if (tour.TourDesc == null || tour.TourDesc == "")
                throw new Exception("The parameter Tour Description should be supplied");

            
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");
                 
                command.Connection = conn;
                command.Transaction = transaction;
                SqlParameter NewTourID = new SqlParameter();
                NewTourID.ParameterName = "@TourStopId";
                NewTourID.DbType = DbType.Int32;
                NewTourID.Direction = ParameterDirection.Output;
                try
                {
                    command.CommandText = "spLocal_eCIL_CreateTourStop";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@TourStopDesc", tour.TourDesc));
                    command.Parameters.Add(new SqlParameter("@RouteId", tour.RouteId));
                    command.Parameters.Add(NewTourID);
                    command.ExecuteNonQuery();
                    transaction.Commit();
                    TourID= Convert.ToInt32(command.Parameters["@TourStopId"].Value.ToString());
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
          
            return TourID;
        }

        //Updates Tourstop description
        public string UpdateTourStopDesc(string _connectionString, TourStop tour)
        {

            if (tour.TourDesc == null || tour.TourDesc == "")
                throw new Exception("The parameter Tour Description should be supplied");
            if (tour.tourId == 0)
                throw new Exception("The parameter Tour Id should be supplied");
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
                        command.CommandText = "spLocal_eCIL_UpdateTourDescription";
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.Add(new SqlParameter("@RouteId", tour.routeId));
                        command.Parameters.Add(new SqlParameter("@TourStopId", tour.tourId));
                        command.Parameters.Add(new SqlParameter("@NewTourDesc", tour.tourDesc));
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

            return "The tourstop has renamed";
        }

        //Updates Tour_Map_Link column to NULL for the specific Tourstop
        public string UnlinkTourStopMapImage(string _connectionString, TourStop tourStop)
        {

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                string sql = "UPDATE Local_PG_eCIL_TourStops set Tour_Map_link=NULL where Tour_Stop_Id=@param1";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    SqlTransaction transaction;

                    transaction = conn.BeginTransaction("StartTransaction");
                    cmd.Transaction = transaction;
                    try
                    {
                        cmd.Parameters.Add("@param1", SqlDbType.VarChar).Value = tourStop.tourId;

                        cmd.CommandType = CommandType.Text;
                        cmd.ExecuteNonQuery();
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
            }
            return "Tourstop map image is unlinked for selected TourStop";
        }



        //Updates Tour_Map_Link column to NULL for all the Tourstop using that image when user deletes the image
        public string DeleteTourMapImage(string _connectionString, string filename)
        {

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "UPDATE Local_PG_eCIL_TourStops set Tour_Map_link=NULL where Tour_Map_link = @param1";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    SqlTransaction transaction;

                    transaction = conn.BeginTransaction("StartTransaction");
                    cmd.Transaction = transaction;
                    try
                    {
                        cmd.Parameters.Add("@param1", SqlDbType.VarChar).Value = filename;
                       
                        cmd.CommandType = CommandType.Text;
                        cmd.ExecuteNonQuery();
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
            }
            return "Tourstop map image is unlinked from all tourstop";
        }

        //Updates Tour_Map_Link colummn 
        public string UpdateTourMapLink(string _connectionString, TourStop tourStop)
        {
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                string sql = "UPDATE Local_PG_eCIL_TourStops set Tour_Map_link=@param2 where Tour_Stop_Id=@param1";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    SqlTransaction transaction;

                    transaction = conn.BeginTransaction("StartTransaction");
                    cmd.Transaction = transaction;
                    try
                    {
                        cmd.Parameters.Add("@param1", SqlDbType.VarChar).Value = tourStop.tourId;
                        cmd.Parameters.Add("@param2", SqlDbType.VarChar).Value = tourStop.tourMap;
                        cmd.CommandType = CommandType.Text;
                        cmd.ExecuteNonQuery();
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
            }
            return "1";
        }
        
        //Update the tour stop id for each task in a Route
        public string UpdateTourStopTask(string _connectionString, TourStop tour)
        {
            if (tour.RouteId == 0)
                throw new Exception("The parameter should be supplied");

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
                    command.CommandText = "spLocal_eCIL_UpdateTourStopTasks";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@RouteId", tour.RouteId));
                    command.Parameters.Add(new SqlParameter("@TourStopId",tour.TourId));
                    command.Parameters.Add(new SqlParameter("@TourIdsOrder", tour.tourIdsOrder));
                    command.Parameters.Add(new SqlParameter("@TaskIDsList", String.IsNullOrEmpty(tour.TaskIds) ? (object)DBNull.Value : tour.TaskIds));
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

            return "The tourstops was updated";
        }


        //Delete TourStop information 
        public string DeleteTourStop(string _connectionString, TourStop tour, int UserId)
        {

            string TourMapImageName = "";
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
               
                {
                    SqlCommand command = new SqlCommand();
                    SqlTransaction transaction;

                    transaction = conn.BeginTransaction("StartTransaction");

                    command.Connection = conn;
                    command.Transaction = transaction;
                    SqlParameter FileName = new SqlParameter();
                    FileName.ParameterName = "@TourMap";
                    FileName.DbType = DbType.String;
                    FileName.Direction = ParameterDirection.Output;
                    FileName.Size = 50;

                    try
                    {
                        command.CommandText = "spLocal_eCIL_DeleteTourStop";
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.Add(new SqlParameter("@RouteId",tour.routeId));
                        command.Parameters.Add(new SqlParameter("@TourStopId", tour.tourId));
                        command.Parameters.Add(FileName);
                        command.ExecuteNonQuery();
                        transaction.Commit();
                        TourMapImageName = command.Parameters["@TourMap"].Value.ToString();
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

            return TourMapImageName;
        }

    }
}
#endregion
