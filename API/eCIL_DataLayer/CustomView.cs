using System;
using System.Collections.Generic;
using System.Data.SqlClient;

namespace eCIL_DataLayer
{
    public class CustomView
    {
        
        #region Variables

        private int uPId;
        private CustomViewType viewType;
        private int userId;
        private string viewDescription;
        private string data;
        private string screenDescription;
        private int screenId;
        private int defaultViewId;
        //This will allow administrators to save views as public
        private bool isPublic;
        //This indicates if this is a Default view(User or Screen)
        private int isDefault;
        //This will allow each user to select his own default view per page
        private bool isUserDefault;
        //This will allow an admin to select a default view for the site
        private bool isSiteDefault;
        //This will allow mapping the runtime MenuItem with the correct Profile
        private int menuItemIndex;
        //Check if Wrap is enable or not
        private bool isWrapEnable;

        public enum CustomViewType
        {
            FL = 1,
            PlantModel = 2,
            Routes = 3,
            Teams = 4,
            RawData = 5,
            UserDefined = 6
        }

        #endregion

        #region Properties

        public int UPId { get => uPId; set => uPId = value; }
        public CustomViewType ViewType { get => viewType; set => viewType = value; }
        public int UserId { get => userId; set => userId = value; }
        public string ViewDescription { get => viewDescription; set => viewDescription = value; }
        public string Data { get => data; set => data = value; }
        public string ScreenDescription { get => screenDescription; set => screenDescription = value; }
        public int ScreenId { get => screenId; set => screenId = value; }
        public int DefaultViewId { get => defaultViewId; set => defaultViewId = value; }
        public bool IsPublic { get => isPublic; set => isPublic = value; }
        public int IsDefault { get => isDefault; set => isDefault = value; }
        public bool IsUserDefault { get => isUserDefault; set => isUserDefault = value; }
        public bool IsSiteDefault { get => isSiteDefault; set => isSiteDefault = value; }
        public int MenuItemIndex { get => menuItemIndex; set => menuItemIndex = value; }
        public bool IsWrapEnable { get => isWrapEnable; set => isWrapEnable = value; }

        #endregion

        #region Methods
        //Get a list with all Custom Views of the current user
        public List<CustomView> ReadCustomViews(string _connectionString, int UserId, string ScreenDescription = "DataEntry")
        {
            List<CustomView> result = new List<CustomView>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetCustomViews", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@UserId", UserId));
                command.Parameters.Add(new SqlParameter("@ScreenDesc", ScreenDescription));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        CustomView temp = new CustomView();
                        temp.UPId = reader.GetInt32(reader.GetOrdinal("UP_Id"));
                        temp.ViewType = (CustomViewType)reader.GetInt32(reader.GetOrdinal("ViewType"));
                        temp.UserId = reader.GetInt32(reader.GetOrdinal("User_Id"));
                        temp.ViewDescription = reader.GetString(reader.GetOrdinal("Profile_Desc"));
                        temp.Data = reader.GetString(reader.GetOrdinal("Data"));
                        temp.ScreenDescription = reader.GetString(reader.GetOrdinal("ScreenDesc"));
                        temp.ScreenId = reader.GetInt32(reader.GetOrdinal("ScreenId"));
                        temp.DefaultViewId = reader.GetOrdinal("DefaultViewId");
                        temp.IsWrapEnable = reader.GetBoolean(reader.GetOrdinal("IsWrapEnable"));
                        temp.IsDefault = reader.GetInt32(reader.GetOrdinal("IsDefault"));
                        temp.IsSiteDefault = reader.GetBoolean(reader.GetOrdinal("IsSiteDefault"));
                        temp.IsUserDefault = reader.GetBoolean(reader.GetOrdinal("IsUserDefault"));
                        temp.IsPublic = reader.GetBoolean(reader.GetOrdinal("IsPublic"));
                        result.Add(temp);
                    }
                }
                conn.Close();
            }
            return result;
           
        }

        //Save the Tasks List Custom View for a user
        //This data will allow restoring the settings of the grid
        public string SaveCustomView(CustomView SavedView, string _connectionString)
        {
            SqlParameter ParamUPId = new SqlParameter();
            SqlParameter ParamErrorMessage = new SqlParameter();
            string ErrorMessage = string.Empty;

            ParamUPId.ParameterName = "@UPId";
            ParamUPId.DbType = System.Data.DbType.Int32;
            ParamUPId.Direction = System.Data.ParameterDirection.Input;

            //If UPId is 0, we pass a NULL parameter to indicate the SP that it should create
            //If there is a value, wew pass it, indicating the SP that is an update
            switch (SavedView.UPId)
            {
                case 0:     ParamUPId.Value = DBNull.Value;
                            break;
                default:    ParamUPId.Value = SavedView.UPId;
                            break;
            }

            ParamErrorMessage.ParameterName = "@ErrorMessage";
            ParamErrorMessage.DbType = System.Data.DbType.String;
            ParamErrorMessage.Direction = System.Data.ParameterDirection.Output;
            ParamErrorMessage.Value = String.Empty;

            using(SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    command.CommandText = "spLocal_eCIL_SaveCustomView";
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@UserId", SavedView.UserId));
                    command.Parameters.Add(new SqlParameter("@ViewDescription", SavedView.ViewDescription));
                    command.Parameters.Add(new SqlParameter("@Data", SavedView.Data));
                    command.Parameters.Add(new SqlParameter("@ScreenDescription", SavedView.ScreenDescription));
                    command.Parameters.Add(new SqlParameter("@UPId", ParamUPId.Value));
                    command.Parameters.Add(new SqlParameter("@IsPublic", SavedView.IsPublic));
                    if(SavedView.isUserDefault == true)
                        command.Parameters.Add(new SqlParameter("@IsUserDefault", SavedView.IsUserDefault));
                    command.Parameters.Add(new SqlParameter("@IsWrapEnable", SavedView.IsWrapEnable));
                    command.Parameters.Add(ParamErrorMessage);
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
            if (ParamErrorMessage.Value != DBNull.Value)
                if (ParamErrorMessage.Value.Equals("EXISTS"))
                    return "A public view already exists with the same description";
            return "The view was saved successfully";
        }
        
        //Delete a Custom View
        public  string DeleteCustomView(int UPId, string _connectionString)
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
                    command.CommandText = "spLocal_eCIL_DeleteCustomView";
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@UPId", UPId));
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

            return "The Custom View was deleted";
        }

        //Set this View as the Site Default View
        //Only an user admin can do this job

        public  string SetSiteDefaultView(int UPId, int LanguageId, string _connectionString, string ScreenDescription = "DataEntry")
        {
            using(SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    command.CommandText = "spLocal_eCIL_SetSiteDefaultView";
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@ScreenDescription", ScreenDescription));
                    command.Parameters.Add(new SqlParameter("@UPId", UPId));
                    command.Parameters.Add(new SqlParameter("@LanguageId", LanguageId));
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

            return "The Current View was set as site default view";
        }

        //Set this View as User Default View
        public string SetUserDefaultView(int UPId, int UserId, int LanguageId, string _connectionString, string ScreenDescription = "DataEntry")
        {
            using(SqlConnection conn = new SqlConnection(_connectionString)) 
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                try
                {
                    command.CommandText = "spLocal_eCIL_SetUserDefaultView";
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@ScreenDescription", ScreenDescription));
                    command.Parameters.Add(new SqlParameter("@UPId", UPId));
                    command.Parameters.Add(new SqlParameter("@UserId", UserId));
                    command.Parameters.Add(new SqlParameter("@LanguageId", LanguageId));
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

            return "The view was set as user default view";
        }
        #endregion

    }
}
