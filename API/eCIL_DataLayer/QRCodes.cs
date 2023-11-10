using QRCoder;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.IO;

namespace eCIL_DataLayer
{
    public class QRCodes
    {
        #region Variables
        private int qrId;
        private int routeId;
        private string qrName;
        private string qrDesc;
        private string routeDesc;
        private DateTime qrDate;
        private DateTime lastModifiedTimestamp;
        #endregion
        //  private int tourStopId;


        #region Properties
        public int QrId { get => qrId; set => qrId = value; }
        public int RouteId { get => routeId; set => routeId = value; }
        public string QrName { get => qrName; set => qrName = value; }
        public string QrDesc { get => qrDesc; set => qrDesc = value; }
        public string RouteDesc { get => routeDesc; set => routeDesc = value; }
        public DateTime QrDate { get => qrDate; set => qrDate = value; }
        public DateTime LastModifiedTimestamp { get => lastModifiedTimestamp; set => lastModifiedTimestamp = value; }
        //  public int TourStopId { get => tourStopId; set => tourStopId = value; }
        #endregion

        // url, lines, units, workcells, tasksIds, routeId
        #region SubClasses
        public class QRCodeProps
        {
            #region Variables
            private string url;
            // private string[] lines;
            private string lines;
            private string line;
            private string units;
            private string unit;
            private string workcells;
            private string workcell;
            private string[] tasksIds;
            private string tasksId;
            private string routeId;
            private string routeIdstr;
            private int qrId;
            private string qrName;
            private string qrDesc;
            private DateTime qrDate;
            private string varId;
            private DateTime lastModifiedTimestamp;
            private string lineDesc;
            private string unitIdDesc;
            private string workcellDesc;
            private string isRoute;
            private string tourStopIds;
            //private string tourStopId;
            //private string routeDesc;
            //private string tourDesc;
            //private string[] tourStopIds;
            #endregion

            #region Properties
            public string Url { get => url; set => url = value; }
            // public string[] Lines { get => lines; set => lines = value; }
            public string Lines { get => lines; set => lines = value; }
            public string Line { get => line; set => line = value; }
            public string Units { get => units; set => units = value; }
            public string Unit { get => unit; set => unit = value; }
            public string Workcells { get => workcells; set => workcells = value; }
            public string Workcell { get => workcell; set => workcell = value; }
            public string[] TasksIds { get => tasksIds; set => tasksIds = value; }
            public string TasksId { get => tasksId; set => tasksId = value; }
            public string RouteId { get => routeId; set => routeId = value; }
            public string RouteIdstr { get => routeIdstr; set => routeIdstr = value; }
            public int QrId { get => qrId; set => qrId = value; }
            public string VarId { get => varId; set => varId = value; }
            public string QrName { get => qrName; set => qrName = value; }
            public string QrDesc { get => qrDesc; set => qrDesc = value; }
            public DateTime QrDate { get => qrDate; set => qrDate = value; }
            public DateTime LastModifiedTimestamp { get => lastModifiedTimestamp; set => lastModifiedTimestamp = value; }
            public string LineDesc { get => lineDesc; set => lineDesc = value; }
            public string UnitIdDesc { get => unitIdDesc; set => unitIdDesc = value; }
            public string WorkcellDesc { get => workcellDesc; set => workcellDesc = value; }
            public string IsRoute { get => isRoute; set => isRoute = value; }
            public string TourStopId { get => tourStopIds; set => tourStopIds = value; }
            //public string TourStopId { get => tourStopId; set => tourStopId = value; }
            //public string RouteDesc { get => routeDesc; set => routeDesc = value; }
            //public string TourDesc { get => tourDesc; set => tourDesc = value; }
            //public string[] TourStopIds { get => tourStopIds; set => tourStopIds = value; }
            #endregion
        }

        public class QRCodeTourStop
        {
            #region Variables
            private string url;
            private string routeId;
            private int qrId;
            private string qrName;
            private string qrDesc;
            private DateTime qrDate;
            private DateTime lastModifiedTimestamp;
            private string tourStopId;
            private string routeDesc;
            private string tourDesc;
            private string[] tourStopIds;
            #endregion

            #region Properties
            public string Url { get => url; set => url = value; }
            // public string[] Lines { get => lines; set => lines = value; }
            public string RouteId { get => routeId; set => routeId = value; }
            public int QrId { get => qrId; set => qrId = value; }
            public string QrName { get => qrName; set => qrName = value; }
            public string QrDesc { get => qrDesc; set => qrDesc = value; }
            public DateTime QrDate { get => qrDate; set => qrDate = value; }
            public DateTime LastModifiedTimestamp { get => lastModifiedTimestamp; set => lastModifiedTimestamp = value; }
            public string TourStopId { get => tourStopId; set => tourStopId = value; }
            public string RouteDesc { get => routeDesc; set => routeDesc = value; }
            public string TourDesc { get => tourDesc; set => tourDesc = value; }
            public string[] TourStopIds { get => tourStopIds; set => tourStopIds = value; }
            #endregion
        }
        public class QRLineDetails
        {
            #region Variables
            private int qrId;
            private string qrName;
            private string qrDesc;
            private string line;
            private string unit;
            private string workcell;
            private string tasksId;
            private string routeIdstr;
            private string varId;
            private string lineDesc;
            private string unitIdDesc;
            private string workcellDesc;
            private string varDesc;
            private string routeDesc;
            private string eventSubtypeDesc;
            #endregion

            #region Properties
            public int QrId { get => qrId; set => qrId = value; }
            public string QrName { get => qrName; set => qrName = value; }
            public string QrDesc { get => qrDesc; set => qrDesc = value; }
            public string Line { get => line; set => line = value; }
            public string Unit { get => unit; set => unit = value; }
            public string Workcell { get => workcell; set => workcell = value; }
            public string TasksId { get => tasksId; set => tasksId = value; }
            public string RouteIdstr { get => routeIdstr; set => routeIdstr = value; }
            public string VarId { get => varId; set => varId = value; }
            public string LineDesc { get => lineDesc; set => lineDesc = value; }
            public string UnitIdDesc { get => unitIdDesc; set => unitIdDesc = value; }
            public string WorkcellDesc { get => workcellDesc; set => workcellDesc = value; }
            public string VarDesc { get => varDesc; set => varDesc = value; }
            public string RouteDesc { get => routeDesc; set => routeDesc = value; }
            public string EventSubtypeDesc { get => eventSubtypeDesc; set => eventSubtypeDesc = value; }
            #endregion
        }
        #endregion

        #region Methods
        public QRCodes()
        {
            qrId = 0;
            routeId = 0;
            qrName = "";
            qrDesc = "";
            qrDate = DateTime.Now;
            lastModifiedTimestamp = DateTime.Now;
        }
        public QRCodes(int id, int rId, string name, string desc, DateTime qdate, DateTime lasttime)
        {
            qrId = id;
            routeId = rId;
            qrName = name;
            qrDesc = desc;
            qrDate = qdate;
            lastModifiedTimestamp = lasttime;
        }

        //Generate QR Image from QRCoder library
        public Byte[] getQRCodeForTask(QRCodes.QRCodeProps qrCodeProps)
        {
            String urlPath = qrCodeProps.Url;

            if (qrCodeProps.Line != null)
            {
                urlPath += "lines=";

                if (qrCodeProps.Line != null)
                    urlPath += qrCodeProps.Line;

                urlPath += "&units=";
                if (qrCodeProps.Unit != null)
                    urlPath += qrCodeProps.Unit;

                urlPath += "&workcells=";
                if (qrCodeProps.Workcell != null)
                    urlPath += qrCodeProps.Workcell;
            }
            else
            {
                urlPath += "myroute=";
                if (qrCodeProps.RouteIdstr != null)
                {
                    urlPath += qrCodeProps.RouteIdstr;
                }
            }
            urlPath += "&tasksIds=";
            urlPath += qrCodeProps.TasksId;


            QRCodeGenerator qrGenerator = new QRCodeGenerator();
            QRCodeData qrCodeData = qrGenerator.CreateQrCode(urlPath, QRCodeGenerator.ECCLevel.Q);

            QRCode qrCode = new QRCode(qrCodeData);
            Bitmap qrCodeImage = qrCode.GetGraphic(40);
            Byte[] qrARRAY = BitmapToBytes(qrCodeImage);
            return qrARRAY;
        }

        //Generate QR Image from QRCoder library by QR_Id parameter only
        public Byte[] getQRCodeForTaskById(QRCodes.QRCodeProps qrCodeProps)
        {
            String urlPath = qrCodeProps.Url;


            urlPath += "qrId=";

            if (qrCodeProps.QrId > 0)
            {
                urlPath += qrCodeProps.QrId;
                urlPath += "&isRoute=";
                urlPath += qrCodeProps.IsRoute;

            }


            QRCodeGenerator qrGenerator = new QRCodeGenerator();
            QRCodeData qrCodeData = qrGenerator.CreateQrCode(urlPath, QRCodeGenerator.ECCLevel.Q);

            QRCode qrCode = new QRCode(qrCodeData);
            Bitmap qrCodeImage = qrCode.GetGraphic(40);
            Byte[] qrARRAY = BitmapToBytes(qrCodeImage);
            return qrARRAY;
        }
        //just to check empty string wherever needed
        private static bool IsNullOrEmpty(string[] myStringArray)
        {
            return myStringArray == null || myStringArray.Length < 1;
        }

        public Byte[] generateQRCodeForRoute(string RouteId, string mainUrl)
        {
            String urlPath = mainUrl +  "myroute=";
            urlPath += RouteId;
            QRCodeGenerator qrGenerator = new QRCodeGenerator();
            QRCodeData qrCodeData = qrGenerator.CreateQrCode(urlPath, QRCodeGenerator.ECCLevel.Q);

            QRCode qrCode = new QRCode(qrCodeData);
            Bitmap qrCodeImage = qrCode.GetGraphic(20);
            Byte[] qrARRAY = BitmapToBytes(qrCodeImage);
            return qrARRAY;
        }

        private static Byte[] BitmapToBytes(Bitmap img)
        {
            using (MemoryStream stream = new MemoryStream())
            {
                img.Save(stream, System.Drawing.Imaging.ImageFormat.Jpeg);
                return stream.ToArray();
            }
        }
  

        //Insert qr name and description qnd other info in DB
        public string SaveQRCodeInfo(string _connectionString, QRCodeProps qrCodeProps, Int64 UserId)
        {
            if (qrCodeProps.QrName == null)
                throw new Exception("The parameter Qr Name should be supplied");

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                SqlParameter Param_ErrorMessage = new SqlParameter("@ErrorMessage", SqlDbType.VarChar, 1000);
                Param_ErrorMessage.Direction = ParameterDirection.Output;
                Param_ErrorMessage.Value = String.Empty;

                try
                {
                    command.CommandText = "spLocal_eCIL_SaveQRCodeInfo";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@LinesList", qrCodeProps.Lines));
                    command.Parameters.Add(new SqlParameter("@RoutesList", qrCodeProps.RouteIdstr));
                    command.Parameters.Add(new SqlParameter ("@TourStopList", qrCodeProps.TourStopId));
                    command.Parameters.Add(new SqlParameter("@QRName", qrCodeProps.QrName));
                    command.Parameters.Add(new SqlParameter("@QRDesc", qrCodeProps.QrDesc));
                    command.Parameters.Add(new SqlParameter("@VarIdList", qrCodeProps.VarId));
                    command.Parameters.Add(new SqlParameter("@EntryBy", UserId));

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

            return "Success";
        }

        //Update QR_Name or QR_Desc 
        public string UpdateQRCodeName(string _connectionString, QRCodes qrDetailsProps, Int64 UserId)
        {
            if (qrDetailsProps.qrName == null)
                throw new Exception("The parameter QR Name should be supplied");


            if (qrDetailsProps.QrName.Length > 50)
                throw new Exception("The QR Code name should be less then 50 characters");

            if (qrDetailsProps.qrDesc.Length > 255)
                throw new Exception("The QR Code description should be less then 255 characters");

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "UPDATE Local_PG_eCIL_QRInfo set QR_Name =@param1, QR_Description =@param2 , LastModified_On=@param3, Entry_By=@param5  where QR_Id =@param4";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {

                    cmd.Parameters.Add("@param1", SqlDbType.VarChar).Value = qrDetailsProps.qrName;
                    cmd.Parameters.Add("@param2", SqlDbType.VarChar).Value = qrDetailsProps.qrDesc;
                    cmd.Parameters.Add("@param3", SqlDbType.DateTime).Value = lastModifiedTimestamp;
                    cmd.Parameters.Add("@param4", SqlDbType.VarChar).Value = qrDetailsProps.qrId;
                    cmd.Parameters.Add("@param5", SqlDbType.Int).Value = UserId;

                    cmd.CommandType = CommandType.Text;
                    cmd.ExecuteNonQuery();
                    return "1";
                }
            }

        }

          //Update data in Local_PG_eCIL_Tasks_QRInfo table for specific QR Id
        public string updateQRCodeInfoForTask(string _connectionString, QRCodes.QRCodeProps qrCodeProps, Int64 UserId)
        {
            if (qrCodeProps.QrName == null)
                throw new Exception("The parameter QR Name should be supplied");

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "UPDATE Local_PG_eCIL_QRInfo set QR_Name =@param1, QR_Description =@param2 ," +
                    " LastModified_On=@param3 , Var_Ids=@param5 ,Line_Ids = @param6, Entry_By = @param7, Route_Ids=@param8 where QR_Id =@param4";


                DateTime myDateTime = DateTime.Now;
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {

                    cmd.Parameters.Add("@param1", SqlDbType.VarChar).Value = qrCodeProps.QrName;
                    //cmd.Parameters.Add("@param2", SqlDbType.VarChar).Value = qrCodeProps.QrDesc;
                    cmd.Parameters.Add("@param3", SqlDbType.DateTime).Value = lastModifiedTimestamp;
                    cmd.Parameters.Add("@param4", SqlDbType.VarChar).Value = qrCodeProps.QrId;
                    cmd.Parameters.Add("@param5", SqlDbType.VarChar).Value = qrCodeProps.VarId;
                    cmd.Parameters.Add("@param7", SqlDbType.Int).Value = UserId;
                    if (qrCodeProps.Lines.Equals(""))
                    {
                        cmd.Parameters.Add("@param6", SqlDbType.VarChar).Value = DBNull.Value;
                    }
                    else { cmd.Parameters.Add("@param6", SqlDbType.VarChar).Value = qrCodeProps.Lines; }
                    if (qrCodeProps.QrDesc.Equals(""))
                    {
                        cmd.Parameters.Add("@param2", SqlDbType.VarChar).Value = DBNull.Value;
                    }
                    else { cmd.Parameters.Add("@param2", SqlDbType.VarChar).Value = qrCodeProps.QrDesc; }
                    if (qrCodeProps.RouteIdstr.Equals(""))
                    {
                        cmd.Parameters.Add("@param8", SqlDbType.VarChar).Value = DBNull.Value;
                    }
                    else { cmd.Parameters.Add("@param8", SqlDbType.VarChar).Value = qrCodeProps.RouteIdstr; }

                    cmd.CommandType = CommandType.Text;
                    cmd.ExecuteNonQuery();
                    return "1";
                }
            }

        }
        //Returns the list of all QR details  for specific QR Id for URL, This will be used when user scans QR code, it will return details of URL for specific QRId
        public QRLineDetails getURLInfoByQRId(string _connectionString, string qrId)
        {
            QRCodes.QRLineDetails temp = new QRCodes.QRLineDetails();
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {

                conn.Open();
                string sql = "select * from Local_PG_eCIL_QRInfo where QR_Id=@param1";
                SqlCommand commandVar = new SqlCommand(sql, conn);

                commandVar.Parameters.Add("@param1", SqlDbType.VarChar, 50).Value = qrId;
                using (SqlDataReader reader = commandVar.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Id")))
                            temp.QrId = reader.GetInt32(reader.GetOrdinal("QR_Id"));

                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Name")))
                            temp.QrName = reader.GetString(reader.GetOrdinal("QR_Name"));

                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Description")))
                            temp.QrDesc = reader.GetString(reader.GetOrdinal("QR_Description"));

                        if (!reader.IsDBNull(reader.GetOrdinal("Line_Ids")))
                            temp.Line = reader.GetString(reader.GetOrdinal("Line_Ids"));

                        if (!reader.IsDBNull(reader.GetOrdinal("Var_Ids")))
                            temp.VarId = reader.GetString(reader.GetOrdinal("Var_Ids"));

                        if (!reader.IsDBNull(reader.GetOrdinal("Route_Ids")))
                            temp.RouteIdstr = reader.GetString(reader.GetOrdinal("Route_Ids"));


                    }
                }

            }
            return temp;
        }
        //Returns the list of all QR details with Line ,variables and route description This will be used form info button in QR Report grid
        public List<QRCodes.QRLineDetails> getInfoForQRId(string _connectionString, string qrId, Boolean IsRouteId)
        {

            List<QRCodes.QRLineDetails> result = new List<QRCodes.QRLineDetails>();
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                string Var_Ids = "";
                string Route_Ids = "";
                string sqlVar = "select Var_Ids from Local_PG_eCIL_QRInfo where QR_Id=@param1";
                string sqlRoute = "select Route_Ids from Local_PG_eCIL_QRInfo where QR_Id=@param1";

                SqlCommand commandVar = new SqlCommand(sqlVar, conn);

                commandVar.Parameters.Add("@param1", SqlDbType.VarChar, 50).Value = qrId;

                using (SqlDataReader reader = commandVar.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        QRCodes.QRLineDetails temp = new QRCodes.QRLineDetails();

                        if (!reader.IsDBNull(reader.GetOrdinal("Var_Ids")))
                            Var_Ids = reader.GetString(reader.GetOrdinal("Var_Ids"));
                    }
                }

                if (IsRouteId)
                {

                    SqlCommand commandRoute = new SqlCommand(sqlRoute, conn);

                    commandRoute.Parameters.Add("@param1", SqlDbType.VarChar, 50).Value = qrId;

                    using (SqlDataReader reader = commandRoute.ExecuteReader())
                    {
                        while (reader.Read())

                        {
                            QRCodes.QRLineDetails temp = new QRCodes.QRLineDetails();

                            if (!reader.IsDBNull(reader.GetOrdinal("Route_Ids")))
                                Route_Ids = reader.GetString(reader.GetOrdinal("Route_Ids"));
                        }
                    }
                }

                string sql = " select tqr.QR_Id,tqr.QR_Name,tqr.QR_Description,v.Var_Id,v.Var_Desc,spu.PU_Id as slave_id,spu.PU_Desc as slave_desc," +
                    "pl.PL_Id,pl.PL_Desc, mpu.PU_Desc as master_desc,mpu.PU_Id as master_id, es.Event_Subtype_Desc as Event_Subtype_Desc from Variables_Base v join Prod_Units_Base spu" +
                    " on spu.PU_Id = v.PU_Id  join Prod_Units_Base mpu on mpu.PU_Id = spu.Master_Unit join Prod_Lines_Base pl" +
                    " on spu.PL_Id = pl.PL_Id  join Event_Subtypes es on v.Event_Subtype_Id = es.Event_Subtype_Id, Local_PG_eCIL_QRInfo tqr where v.PU_Id = spu.PU_Id and " +
                    "spu.PL_Id = pl.PL_Id and tqr.QR_Id = @param1 and v.Var_Id in (";

                string sqlR = "select v.Var_Id,v.Var_Desc,tqr.QR_Name,tqr.QR_Id,tqr.QR_Description,rt.Route_Id,r.Route_Desc,es.Event_Subtype_Desc as Event_Subtype_Desc from Variables_Base v join Event_Subtypes es on v.Event_Subtype_Id =es.Event_Subtype_Id, " +
                    "Local_PG_eCIL_QRInfo tqr, Local_PG_eCIL_RouteTasks rt, Local_PG_eCIL_Routes r  " +
                    "where v.Var_Id = rt.Var_Id  and rt.Route_Id = r.Route_Id and tqr.QR_Id = @param1 and v.Var_Id in (";

                string finalSql = "";
                string tempStr = Var_Ids + ")";
                if (!IsRouteId)
                {
                    finalSql = sql + tempStr;
                }
                else
                {
                    finalSql = sqlR + tempStr + "and r.Route_Id in (" + Route_Ids + ")";

                }

                SqlCommand command = new SqlCommand(finalSql, conn);

                command.Parameters.Add("@param1", SqlDbType.VarChar, 50).Value = qrId;

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        QRCodes.QRLineDetails temp = new QRCodes.QRLineDetails();

                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Id")))
                            temp.QrId = reader.GetInt32(reader.GetOrdinal("QR_Id"));

                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Name")))
                            temp.QrName = reader.GetString(reader.GetOrdinal("QR_Name"));

                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Description")))
                            temp.QrDesc = reader.GetString(reader.GetOrdinal("QR_Description"));

                        if (!reader.IsDBNull(reader.GetOrdinal("Var_Id")))
                            temp.VarId = reader.GetInt32(reader.GetOrdinal("Var_Id")) + "";

                        if (!reader.IsDBNull(reader.GetOrdinal("Var_Desc")))
                            temp.VarDesc = reader.GetString(reader.GetOrdinal("Var_Desc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("Event_Subtype_Desc")))
                            temp.EventSubtypeDesc = reader.GetString(reader.GetOrdinal("Event_Subtype_Desc"));

                        if (!IsRouteId)
                        {
                            if (!reader.IsDBNull(reader.GetOrdinal("PL_Id")))
                                temp.Line = reader.GetInt32(reader.GetOrdinal("PL_Id")) + "";

                            if (!reader.IsDBNull(reader.GetOrdinal("PL_Desc")))
                                temp.LineDesc = reader.GetString(reader.GetOrdinal("PL_Desc"));

                            if (!reader.IsDBNull(reader.GetOrdinal("master_id")))
                                temp.Unit = reader.GetInt32(reader.GetOrdinal("master_id")) + "";

                            if (!reader.IsDBNull(reader.GetOrdinal("master_desc")))
                                temp.UnitIdDesc = reader.GetString(reader.GetOrdinal("master_desc"));

                            if (!reader.IsDBNull(reader.GetOrdinal("slave_id")))
                                temp.Workcell = reader.GetInt32(reader.GetOrdinal("slave_id")) + "";

                            if (!reader.IsDBNull(reader.GetOrdinal("slave_desc")))
                                temp.WorkcellDesc = reader.GetString(reader.GetOrdinal("slave_desc"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Event_Subtype_Desc")))
                                temp.EventSubtypeDesc = reader.GetString(reader.GetOrdinal("Event_Subtype_Desc"));
                        }
                        else
                        {
                            if (!reader.IsDBNull(reader.GetOrdinal("Route_Id")))
                                temp.RouteIdstr = reader.GetInt32(reader.GetOrdinal("Route_Id")) + "";

                            if (!reader.IsDBNull(reader.GetOrdinal("Route_Desc")))
                                temp.RouteDesc = reader.GetString(reader.GetOrdinal("Route_Desc"));
                        }

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }

            return result;
        }

        //Returns the list of all QR details Routes
        public List<QRCodes> getAllQRCodeInfoForRoute(string _connectionString)
        {
            List<QRCodes> result = new List<QRCodes>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "select * from Local_PG_eCIL_QRInfo q , Local_PG_eCIL_Routes r where q.Route_Ids=r.Route_Id and q.QR_Type like 'ByRoute'";
                SqlCommand command = new SqlCommand(sql, conn);

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        QRCodes temp = new QRCodes();

                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Id")))
                            temp.qrId = reader.GetInt32(reader.GetOrdinal("QR_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Name")))
                            temp.qrName = reader.GetString(reader.GetOrdinal("QR_Name"));
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Description")))
                            temp.qrDesc = reader.GetString(reader.GetOrdinal("QR_Description"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Route_Desc")))
                            temp.routeDesc = reader.GetString(reader.GetOrdinal("Route_Desc"));
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Created_On")))
                            temp.qrDate = reader.GetDateTime(reader.GetOrdinal("QR_Created_On"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Route_Ids")))
                            temp.routeId = Convert.ToInt32(reader.GetString(reader.GetOrdinal("Route_Ids")));

                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Returns the list of saved QR details for ByTask QR code
        public List<QRCodes.QRCodeProps> getAllQRCodeInfoForTask(string _connectionString)
        {
            List<QRCodes.QRCodeProps> result = new List<QRCodes.QRCodeProps>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "SELECT * FROM Local_PG_eCIL_QRInfo where QR_Type like '%Task%' ";
                SqlCommand command = new SqlCommand(sql, conn);

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        QRCodes.QRCodeProps temp = new QRCodes.QRCodeProps();

                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Id")))
                            temp.QrId = reader.GetInt32(reader.GetOrdinal("QR_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Name")))
                            temp.QrName = reader.GetString(reader.GetOrdinal("QR_Name"));
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Description")))
                            temp.QrDesc = reader.GetString(reader.GetOrdinal("QR_Description"));
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Created_On")))
                            temp.QrDate = reader.GetDateTime(reader.GetOrdinal("QR_Created_On"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Var_Ids")))
                            temp.VarId = reader.GetString(reader.GetOrdinal("Var_Ids"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Line_Ids")))
                            temp.Line = reader.GetString(reader.GetOrdinal("Line_Ids"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Route_Ids")))
                            temp.RouteIdstr = reader.GetString(reader.GetOrdinal("Route_Ids"));


                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Delete the QR code from Local_PG_eCIL_QRInfo table
        public string DeleteQRCode(string _connectionString, QRCodes qrDetailsProps)
        {

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "DELETE FROM Local_PG_eCIL_QRInfo  where QR_Id = @ParamQRId";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {

                    cmd.Parameters.Add("@ParamQRId", SqlDbType.VarChar).Value = qrDetailsProps.qrId;

                    cmd.CommandType = CommandType.Text;
                    cmd.ExecuteNonQuery();
                    return "QR Code deleted";
                }
            }

        }

              //Insert QR details into databse for specified route ID and TourStop Ids
        //public List<QRCodeTourStop> saveQRCodeForTourStop(string _connectionString, QRCodeTourStop qrCodeTourStop, Int64 UserId)
        //{
        //    List<QRCodeTourStop> QRDetails = new List<QRCodeTourStop>();
        //    using (SqlConnection conn = new SqlConnection(_connectionString))
        //    {
        //        conn.Open();
        //        SqlCommand command = new SqlCommand("spLocal_eCIL_CreateQRCodeTourStop", conn);
        //        command.CommandType = CommandType.StoredProcedure;
        //        command.Parameters.Add(new SqlParameter("@RouteId", qrCodeTourStop.RouteId));
        //        command.Parameters.Add(new SqlParameter("@TourStopIds", qrCodeTourStop.TourStopId));
        //        command.Parameters.Add(new SqlParameter("@Entry_By", UserId));

        //        using (SqlDataReader reader = command.ExecuteReader())
        //        {
        //            while (reader.Read())
        //            {
        //                var temp = new QRCodeTourStop();

        //                if (!reader.IsDBNull(reader.GetOrdinal("QR_Id")))
        //                    qrCodeTourStop.QrId = reader.GetInt32(reader.GetOrdinal("QR_Id"));
        //                else
        //                    qrCodeTourStop.QrName = string.Empty;

        //                if (!reader.IsDBNull(reader.GetOrdinal("QR_Name")))
        //                    qrCodeTourStop.QrName = reader.GetString(reader.GetOrdinal("QR_Name"));
        //                else
        //                    qrCodeTourStop.QrName = string.Empty;

        //                if (!reader.IsDBNull(reader.GetOrdinal("QR_Description")))
        //                    qrCodeTourStop.QrName = reader.GetString(reader.GetOrdinal("QR_Description"));
        //                else
        //                    qrCodeTourStop.QrName = string.Empty;

        //                QRDetails.Add(temp);

        //            }
        //            reader.Close();
        //        }
        //        conn.Close();
        //    }
        //    return QRDetails;
        //}


        //Insert qr name and description qnd other info in DB for TourStop
        //public string SaveQRCodeInfo_TS(string _connectionString, QRCodes.QRCodeTourStop qRCodeTourStop, Int64 UserId)
        //{
          

        //    using (SqlConnection conn = new SqlConnection(_connectionString))
        //    {
        //        conn.Open();
        //        SqlCommand command = new SqlCommand();
        //        SqlTransaction transaction;

        //        transaction = conn.BeginTransaction("StartTransaction");

        //        command.Connection = conn;
        //        command.Transaction = transaction;

        //        //SqlParameter Param_QrId = new SqlParameter("@QRId", SqlDbType.Int);
        //        //Param_QrId.Direction = ParameterDirection.Output;
        //        //Param_QrId.Value = String.Empty;

        //        SqlParameter Param_ErrorMessage = new SqlParameter("@ErrorMessage", SqlDbType.VarChar, 1000);
        //        Param_ErrorMessage.Direction = ParameterDirection.Output;
        //        Param_ErrorMessage.Value = String.Empty;

        //        try
        //        {
        //            command.CommandText = "spLocal_eCIL_SaveQRCodeInfo_TS";
        //            command.CommandType = CommandType.StoredProcedure;
        //            //command.Parameters.Add(Param_QrId);
        //            //command.Parameters.Add(new SqlParameter("@LinesList", qrCodeProps.Lines));
        //            command.Parameters.Add(new SqlParameter("@RoutesList", qRCodeTourStop.RouteId));
        //            command.Parameters.Add(new SqlParameter("@TourStopList", qRCodeTourStop.TourStopId));
        //            command.Parameters.Add(new SqlParameter("@QRName", qRCodeTourStop.QrName));
        //            command.Parameters.Add(new SqlParameter("@QRDesc", qRCodeTourStop.QrDesc));
        //           // command.Parameters.Add(new SqlParameter("@VarIdList", qrCodeProps.VarId));
        //            command.Parameters.Add(new SqlParameter("@EntryBy", UserId));

        //            command.ExecuteNonQuery();
        //            transaction.Commit();
        //        }
        //        catch (Exception ex)
        //        {
        //            try
        //            {
        //                transaction.Rollback();
        //            }
        //            catch (Exception ex2)
        //            {
        //                conn.Close();
        //                throw new Exception(ex2.Message);
        //            }

        //            conn.Close();
        //            throw new Exception(ex.Message);
        //        }

        //        conn.Close();
        //       // int QrId = (Convert.ToInt32(Param_QrId.Value));

        //    }

        //   // return QrId + "";
        //    return null;
        //}


        //Generate QR Image from QRCoder library for TourStop
        public List<Byte[]> getQRCodeForTourStop(QRCodes.QRCodeTourStop qrCodeTourStop)
        {

            List<Byte[]> QRCodeImage = new List<byte[]>();

            for (int i = 0; i < qrCodeTourStop.TourStopIds.Length; i++)
            {
                String urlPath = qrCodeTourStop.Url;

                urlPath += "myroute=";
                if (qrCodeTourStop.RouteId != null)
                {
                    urlPath += qrCodeTourStop.RouteId;
                }

                urlPath += "&tourStopId=";
                urlPath += qrCodeTourStop.TourStopIds[i];


                QRCodeGenerator qrGenerator = new QRCodeGenerator();
                QRCodeData qrCodeData = qrGenerator.CreateQrCode(urlPath, QRCodeGenerator.ECCLevel.Q);

                QRCode qrCode = new QRCode(qrCodeData);
                Bitmap qrCodeImage = qrCode.GetGraphic(40);
                Byte[] qrARRAY = BitmapToBytes(qrCodeImage);
                QRCodeImage.Add(qrARRAY);
            }

            return QRCodeImage;

        }

        //Returns the list of saved QR details for Tour Stops from Local_PG_eCIL_TourStop_QRInfo table
        public List<QRCodes.QRCodeTourStop> getAllQRCodeInfoForTourStop(string _connectionString)
        {
            List<QRCodes.QRCodeTourStop> result = new List<QRCodes.QRCodeTourStop>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                string sql = "select QR_ID,QR_Name, QR_Description,Route_Ids,tq.Tour_Stop_Id as Tour_Stop_Id,Route_Desc,Tour_Stop_Desc,QR_Created_On from Local_PG_eCIL_QRInfo tq left join  Local_PG_eCIL_Routes r ON tq.Route_Ids = r.Route_Id left join Local_PG_eCIL_TourStops ts on tq.Tour_Stop_Id = ts.Tour_Stop_Id where (tq.Route_Ids) in (Select Route_Ids from Local_PG_eCIL_QRInfo where QR_Type='ByTourStop') and tq.QR_Type='ByTourStop'";
                SqlCommand command = new SqlCommand(sql, conn);

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())

                    {
                        QRCodes.QRCodeTourStop temp = new QRCodes.QRCodeTourStop();

                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Id")))
                            temp.QrId = reader.GetInt32(reader.GetOrdinal("QR_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Name")))
                            temp.QrName = reader.GetString(reader.GetOrdinal("QR_Name"));
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Description")))
                            temp.QrDesc = reader.GetString(reader.GetOrdinal("QR_Description"));
                        if (!reader.IsDBNull(reader.GetOrdinal("QR_Created_On")))
                            temp.QrDate = reader.GetDateTime(reader.GetOrdinal("QR_Created_On"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Route_Ids")))
                            temp.RouteId = reader.GetString(reader.GetOrdinal("Route_Ids")).ToString();
                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Id")))
                            temp.TourStopId = reader.GetInt32(reader.GetOrdinal("Tour_Stop_Id")).ToString();
                        if (!reader.IsDBNull(reader.GetOrdinal("Route_Desc")))
                            temp.RouteDesc = reader.GetString(reader.GetOrdinal("Route_Desc"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Desc")))
                            temp.TourDesc = reader.GetString(reader.GetOrdinal("Tour_Stop_Desc"));


                        result.Add(temp);
                    }
                    reader.Close();
                }
            }
            return result;
        }

        //Delete the QR details of specific Tour Stop ID from Local_PG_eCIL_Tasks_QRInfo table
        //public string deleteQRCodeInforForTourStop(string _connectionString, QRCodeTourStop qrCodeTourStop)
        //{

        //    using (SqlConnection conn = new SqlConnection(_connectionString))
        //    {
        //        conn.Open();
        //        string sql = "DELETE FROM Local_PG_eCIL_TourStop_QRInfo where QR_Id = @param1";

        //        using (SqlCommand cmd = new SqlCommand(sql, conn))
        //        {

        //            cmd.Parameters.Add("@param1", SqlDbType.VarChar, 50).Value = qrCodeTourStop.QrId;

        //            cmd.CommandType = CommandType.Text;
        //            cmd.ExecuteNonQuery();
        //            return "1";
        //        }
        //    }

        //}

        //Update QR_Name or QR_Desc in Local_PG_eCIL_TourStop_QRInfo table
        //public string updateQRCodeNameForTourStop(string _connectionString, QRCodes.QRCodeTourStop qrCodeTourStop, Int64 UserId)
        //{
        //    if (qrCodeTourStop.QrName == null || qrCodeTourStop.QrDesc == "")
        //        throw new Exception("The parameter Route Description should be supplied");

        //    if (qrCodeTourStop.QrName.Length > 50)
        //        throw new Exception("The QR Code name should be less then 50 characters");

        //    using (SqlConnection conn = new SqlConnection(_connectionString))
        //    {
        //        conn.Open();
        //        string sql = "UPDATE Local_PG_eCIL_TourStop_QRInfo set QR_Name =@param1, QR_Description =@param2 , Last_ModifiedTimeStamp=@param3  where QR_Id =@param4";
        //        DateTime myDateTime = DateTime.Now;
        //        using (SqlCommand cmd = new SqlCommand(sql, conn))
        //        {

        //            cmd.Parameters.Add("@param1", SqlDbType.VarChar).Value = qrCodeTourStop.QrName;
        //            cmd.Parameters.Add("@param2", SqlDbType.VarChar).Value = qrCodeTourStop.QrDesc;
        //            cmd.Parameters.Add("@param3", SqlDbType.DateTime).Value = lastModifiedTimestamp;
        //            cmd.Parameters.Add("@param4", SqlDbType.VarChar).Value = qrCodeTourStop.QrId;
        //            cmd.Parameters.Add("@param5", SqlDbType.Int).Value = UserId;

        //            cmd.CommandType = CommandType.Text;
        //            cmd.ExecuteNonQuery();
        //            return "1";
        //        }
        //    }

        //}

        #endregion

    }
}

