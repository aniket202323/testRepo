using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Web.Script.Serialization;

namespace eCIL_DataLayer
{
    public class Defect
    {
        #region Variables
        Task taskObject;
        private string description;
        private DefectSelector defectType;
        private string notificationNumber;
        private int userId;
        private Int64 testId;
        #endregion

        #region Properties
        public string Description { get => description; set => description = value; }
        public DefectSelector DefectType { get => defectType; set => defectType = value; }
        public string NotificationNumber { get => notificationNumber; set => notificationNumber = value; }
        public int UserId { get => userId; set => userId = value; }
        public Int64 TestId { get => testId; set => testId = value; }
        #endregion

        public  Defect() 
        {
            taskObject = new Task(); 
        }
        #region SubClasses
        public class DefectSelector
        {
            #region Variables
            private int id;
            private string globalName;
            private string code;
            #endregion

            #region Properties
            public int Id { get => id; set => id = value; }
            public string GlobalName { get => globalName; set => globalName = value; }
            public string Code { get => code; set => code = value; }
            #endregion
        }

        public class AddDefectResult
        {
            #region Variables
            private int defectId;
            private string notifNO;
            private string errorMSG;
            #endregion

            #region Properties
            public int DefectId { get => defectId; set => defectId = value; }
            public string NotifNO { get => notifNO; set => notifNO = value; }
            public string ErrorMSG { get => errorMSG; set => errorMSG = value; }
            #endregion
        }

        public class CILDefect
        {
            #region Variables
            private string fLCode;
            private string description;
            private Int64? sourceRecordID;
            private int userId;
            private string userName;
            private int? defectTypeId;
            private string defectTypeCode;
            private int? defectComponentId;
            private int? howFoundId;
            private bool? pMNotification;
            private int? priorityId;
            private string cm1;
            private string cm2;
            private string cm3;
            private bool fixedDefect;
            private string foundBy;
            private string closedBy;
            private string fixedBy;
            private string serverCurrentResult;
            private bool repeat;
            private DateTime? dueDate;
            #endregion

            #region Properties
            public string FLCode { get => fLCode; set => fLCode = value; }
            public string Description { get => description; set => description = value; }
            public Int64? SourceRecordID { get => sourceRecordID; set => sourceRecordID = value; }
            public int UserId { get => userId; set => userId = value; }
            public string UserName { get => userName; set => userName = value; }
            public int? DefectTypeId { get => defectTypeId; set => defectTypeId = value; }
            public string DefectTypeCode { get => defectTypeCode; set => defectTypeCode = value; }
            public int? DefectComponentId { get => defectComponentId; set => defectComponentId = value; }
            public int? HowFoundId { get => howFoundId; set => howFoundId = value; }
            public bool? PMNotification { get => pMNotification; set => pMNotification = value; }
            public int? PriorityId { get => priorityId; set => priorityId = value; }
            public string CM1 { get => cm1; set => cm1 = value; }
            public string CM2 { get => cm2; set => cm2 = value; }
            public string CM3 { get => cm3; set => cm3 = value; }
            public bool Fixed { get => fixedDefect; set => fixedDefect = value; }
            public string FoundBy { get => foundBy; set => foundBy = value; }
            public string ClosedBy { get => closedBy; set => closedBy = value; }
            public string FixedBy { get => fixedBy; set => fixedBy = value; }
            public string ServerCurrentResult { get => serverCurrentResult; set => serverCurrentResult = value; }
            public bool Repeat { get => repeat; set => repeat = value; }
            public DateTime? DueDate { get => dueDate; set => dueDate = value; }
            #endregion
        }

        public class FLDefects
        {
            #region Variables
            private int id;
            private string fLCode;
            private string description;
            private DateTime? dateFound;
            private DateTime? dateSolved;
            private DateTime? pmOpenDate;
            private DateTime? pmCloseDate;
            private int? flId;
            private int? sourceEventID;
            private Int64? sourceRecordID;
            private string userName;
            private int? defectTypeId;
            private string defectType;
            private int? defectComponentId;
            private string defectComponent;
            private int? howFoundId;
            private string howFound;
            private bool? pmNotification;
            private string notificationNum;
            private string pmStatus;
            private int? priorityId;
            private string priority;
            private string fileURL;
            private string cm1Text;
            private string cm2Text;
            private string cm3Text;
            private string cm1;
            private string cm2;
            private string cm3;
            private string responsibility;
            private int? workPlanId;
            private string workPlan;
            private string file;
            private string fileName;
            private string createdBy;
            private string foundBy;
            private string closedBy;
            private string fixedBy;
            private string otherFlDescription;
            public string department;
            public string prodLineDesc;
            public string prodUnitDesc;
            private string puGroupDesc;
            private int? departmentId;
            private int? prodLineId;
            private int? prodUnitId;
            private int? puGroupId;
            private bool? nonEquipment;
            private string cilLongDescription;
            private int? totalDefects;
            private Int32? teamId;
            private string team;
            #endregion

            #region Properties
            public int Id { get => id; set => id = value; }
            public string FLCode { get => fLCode; set => fLCode = value; }
            public string Description { get => description; set => description = value; }
            public DateTime? DateFound { get => dateFound; set => dateFound = value; }
            public DateTime? DateSolved { get => dateSolved; set => dateSolved = value; }
            public System.DateTime? PMOpenDate { get => pmOpenDate; set => pmOpenDate = value; }
            public System.DateTime? PMCloseDate { get => pmCloseDate; set => pmCloseDate = value; }
            public int? FLId { get => flId; set => flId = value ; }
            public int? SourceEventID { get => sourceEventID; set => sourceEventID = value; }
            public Int64? SourceRecordID { get => sourceRecordID; set => sourceRecordID = value; }
            public string UserName { get => userName; set => userName = value; }
            public int? DefectTypeId { get => defectTypeId; set => defectTypeId = value; }
            public string DefectType { get => defectType; set => defectType = value; }
            public int? DefectComponentId { get => defectComponentId; set => defectComponentId = value; }
            public string DefectComponent { get => defectComponent; set => defectComponent = value; }
            public int? HowFoundId { get => howFoundId; set => howFoundId = value; }
            public string HowFound { get => howFound; set => howFound = value; }
            public bool? PMNotification { get => pmNotification; set => pmNotification = value; }
            public string NotificationNum { get => notificationNum; set => notificationNum = value; }
            public string PMStatus { get => pmStatus; set => pmStatus = value; }
            public int? PriorityId { get => priorityId; set => priorityId = value; }
            public string Priority { get => priority; set => priority = value; }
            public string FileURL { get => fileURL; set => fileURL = value; }
            public string CM1Text { get => cm1Text; set => cm1Text = value; }
            public string CM2Text { get => cm2Text; set => cm2Text = value; }
            public string CM3Text { get => cm3Text; set => cm3Text = value; }
            public string CM1 { get => cm1; set => cm1 = value; }
            public string CM2 { get => cm2; set => cm2 = value; }
            public string CM3 { get => cm3; set => cm3 = value; }
            public string Responsibility { get => responsibility; set => responsibility = value; }
            public int? WorkPlanId { get => workPlanId; set => workPlanId = value; }
            public string WorkPlan { get => workPlan; set => workPlan = value; }
            public string File { get => file; set => file = value; }
            public string FileName { get => fileName; set => fileName = value; }
            public string CreatedBy { get => createdBy; set => createdBy = value; }
            public string FoundBy { get => foundBy; set => foundBy = value; }
            public string ClosedBy { get => closedBy; set => closedBy = value; }
            public string FixedBy { get => fixedBy; set => fixedBy = value; }
            public string OtherFLDescription { get => otherFlDescription; set => otherFlDescription = value; }
            public string Department { get => department; set => department = value; }
            public string ProdLineDesc { get => prodLineDesc; set => prodLineDesc = value; }
            public string ProdUnitDesc { get => prodUnitDesc; set => prodUnitDesc = value; }
            public string PUGroupDesc { get => puGroupDesc; set => puGroupDesc = value; }
            public int? DepartmentId { get => departmentId; set => departmentId = value; }
            public int? ProdLineId { get => prodLineId; set => prodLineId = value; }
            public int? ProdUnitId { get => prodUnitId; set => prodUnitId = value; }
            public int? PUGroupId { get => puGroupId; set => puGroupId = value; }
            public bool? NonEquipment { get => nonEquipment; set => nonEquipment = value; }
            public string CILLongDescription { get => cilLongDescription; set => cilLongDescription = value; }
            public int? TotalDefects { get => totalDefects; set => totalDefects = value; }
            public Int32? TeamId { get => teamId; set => teamId = value; }
            public string Team { get => team; set => team = value; }
            #endregion
        }


        public class DefectHistory
        {
            #region Variables
            private string defectStart;
            private string defectEnd;
            private string fl;
            private string defectType;
            private string reportedBy;
            private string notification;
            private string description;
            #endregion

            #region Properties
            public string DefectStart { get => defectStart; set => defectStart = value; }
            public string DefectEnd { get => defectEnd; set => defectEnd = value; }
            public string FL { get => fl; set => fl = value; }
            public string DefectType { get => defectType; set => defectType = value; }
            public string ReportedBy { get => reportedBy; set => reportedBy = value; }
            public string Notification { get => notification; set => notification = value; }
            public string Description { get => description; set => description = value; }
            #endregion
        }

        public class eDH
        {
            #region Variables
            private int udeId;
            private string udeDesc;
            private int puId;
            private int eventSubTypeId;
            private DateTime startTime;
            private DateTime endTime;
            private int duration;
            private string cause1;
            private string cause2;
            private string cause3;
            private string cause4;
            private int causeCommentId;
            private string action1;
            private string action2;
            private string action3;
            private string action4;
            private int actionCommentId;
            private int reaserchUserId;
            private int reaserchStatusId;
            private string reasearchOpenDate;
            private string reasearchCloseDate;
            private int researchCommentId;
            private int commentId;
            private int eventId;
            private int eventStatus;
            private int testingStatus;
            #endregion

            #region Properties
            public int UDEId { get => udeId; set => udeId = value; }
            public string UDEDesc { get => udeDesc; set => udeDesc = value; }
            public int PUId { get => puId; set => puId = value; }
            public int EventSubTypeId { get => eventSubTypeId; set => eventSubTypeId = value; }
            public DateTime StartTime { get => startTime; set => startTime = value; }
            public DateTime EndTime { get => endTime; set => endTime = value; }
            public int Duration { get => duration; set => duration = value; }
            public string Cause1 { get => cause1; set => cause1 = value; }
            public string Cause2 { get => cause2; set => cause2 = value; }
            public string Cause3 { get => cause3; set => cause3 = value; }
            public string Cause4 { get => cause4; set => cause4 = value; }
            public int CauseCommentId { get => causeCommentId; set => causeCommentId = value; }
            public string Action1 { get => action1; set => action1 = value; }
            public string Action2 { get => action2; set => action2 = value; }
            public string Action3 { get => action3; set => action3 = value; }
            public string Action4 { get => action4; set => action4 = value; }
            public int ActionCommentId { get => actionCommentId; set => actionCommentId = value; }
            public int ReaserchUserId { get => reaserchUserId; set => reaserchUserId = value; }
            public int ReaserchStatusId { get => reaserchStatusId; set => reaserchStatusId = value; }
            public string ReasearchOpenDate { get => reasearchOpenDate; set => reasearchOpenDate = value; }
            public string ReasearchCloseDate { get => reasearchCloseDate; set => reasearchCloseDate = value; }
            public int ResearchCommentId { get => researchCommentId; set => researchCommentId = value; }
            public int CommentId { get => commentId; set => commentId = value; }
            public int EventId { get => eventId; set => eventId = value; }
            public int EventStatus { get => eventStatus; set => eventStatus = value; }
            public int TestingStatus { get => testingStatus; set => testingStatus = value; }
            #endregion
        }

        public class FLPlantModel
        {
            #region Variables
            private int? flId;
            private string flCode;
            private int? departmentId;
            private int? prodLineId;
            private int? prodUnitId;
            private int? puGroupId;
            #endregion

            #region Properties
            public int? FLId { get => flId; set => flId = value; }
            public string FLCode { get => flCode; set => flCode = value; }
            public int? DepartmentId { get => departmentId; set => departmentId = value; }
            public int? ProdLineId { get => prodLineId; set => prodLineId = value; }
            public int? ProdUnitId { get => prodUnitId; set => prodUnitId = value; }
            public int? PuGroupId { get => puGroupId; set => puGroupId = value; }
            #endregion
        }
        #endregion

        #region Methods
        //Get all the opened defects for an instance of a task
        //parameter: TestId
        public  List<DefectHistory> GetInstanceOpenedDefects(string _connectionString, Int64 TestId)
        {
            var result = new List<DefectHistory>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetInstanceOpenedDefects", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@TestId", TestId));
                using(SqlDataReader reader = command.ExecuteReader())
                {
                    while(reader.Read())
                    {
                        DefectHistory temp = new DefectHistory();

                        if (!reader.IsDBNull(reader.GetOrdinal("DefectStart")))
                            temp.DefectStart = reader.GetString(reader.GetOrdinal("DefectStart"));
                        if (!reader.IsDBNull(reader.GetOrdinal("FL")))
                            temp.FL = reader.GetString(reader.GetOrdinal("FL"));
                        if (!reader.IsDBNull(reader.GetOrdinal("DefectType")))
                            temp.DefectType = reader.GetString(reader.GetOrdinal("DefectType"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ReportedBy")))
                            temp.ReportedBy = reader.GetString(reader.GetOrdinal("ReportedBy"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Notification")))
                            temp.Notification = reader.GetString(reader.GetOrdinal("Notification"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Description")))
                            temp.Description = reader.GetString(reader.GetOrdinal("Description"));

                        result.Add(temp);
                    }
                }
                conn.Close();
            }
            return result;
            

        }

        //Get all the opened defects for task, regardless of the instance
        //Parameter :VarId
        public  List<DefectHistory> GetTaskOpenedDefects(string _connectionString, int VarId)
        {
            var result = new List<DefectHistory>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetTaskOpenedDefects", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@VarId", VarId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        DefectHistory temp = new DefectHistory();

                        if (!reader.IsDBNull(reader.GetOrdinal("DefectStart")))
                            temp.DefectStart = reader.GetString(reader.GetOrdinal("DefectStart"));
                        if (!reader.IsDBNull(reader.GetOrdinal("FL")))
                            temp.FL = reader.GetString(reader.GetOrdinal("FL"));
                        if (!reader.IsDBNull(reader.GetOrdinal("DefectType")))
                            temp.DefectType = reader.GetString(reader.GetOrdinal("DefectType"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ReportedBy")))
                            temp.ReportedBy = reader.GetString(reader.GetOrdinal("ReportedBy"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Notification")))
                            temp.Notification = reader.GetString(reader.GetOrdinal("Notification"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Description")))
                            temp.Description = reader.GetString(reader.GetOrdinal("Description"));

                        result.Add(temp);
                    }
                }
                conn.Close();
            }
            return result;

        }

        //Get the N closed defects in the history of a task
        public  List<DefectHistory> GetDefectsHistory(string _connectionString, int VarId, int NbrBack)
        {
            var result = new List<DefectHistory>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetDefectHistory", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@VarId", VarId));
                command.Parameters.Add(new SqlParameter("@NbrLastDefects", NbrBack));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        DefectHistory temp = new DefectHistory();

                        if (!reader.IsDBNull(reader.GetOrdinal("DefectStart")))
                            temp.DefectStart = reader.GetString(reader.GetOrdinal("DefectStart"));
                        if (!reader.IsDBNull(reader.GetOrdinal("DefectEnd")))
                            temp.DefectEnd = reader.GetString(reader.GetOrdinal("DefectEnd"));
                        if (!reader.IsDBNull(reader.GetOrdinal("FL")))
                            temp.FL = reader.GetString(reader.GetOrdinal("FL"));
                        if (!reader.IsDBNull(reader.GetOrdinal("DefectType")))
                            temp.DefectType = reader.GetString(reader.GetOrdinal("DefectType"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ReportedBy")))
                            temp.ReportedBy = reader.GetString(reader.GetOrdinal("ReportedBy"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Notification")))
                            temp.Notification = reader.GetString(reader.GetOrdinal("Notification"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Description")))
                            temp.Description = reader.GetString(reader.GetOrdinal("Description"));

                        result.Add(temp);
                    }
                }
                conn.Close();
            }
            return result;

        }

        // Get the list of Defect Types from eCIl
        // Retrieved from all rows in Event_Subtypes having Extended_Info = 'DefectType'
        public  List<DefectSelector> GetDefectTypes(string eDHWebService, string eDHToken, string language) 
        {
            var result = new List<DefectSelector>();
            using (WebClient webClient = new System.Net.WebClient())
            {
                webClient.Headers[HttpRequestHeader.Authorization] = eDHToken;
                webClient.Encoding = System.Text.Encoding.UTF8;
                webClient.QueryString.Add("lang", language);
                var json = webClient.DownloadString(eDHWebService + "DefectTypes");

                DefectSelector temp = new DefectSelector();
                DefectSelector[] array = JsonConvert.DeserializeObject<DefectSelector[]>(json);

                foreach(DefectSelector item in array)
                {
                    result.Add(item);
                }
            }
            return result;
        }

        public List<DefectSelector> GetDefectComponents(string eDHWebService, string eDHToken, string language)
        {
            var result = new List<DefectSelector>();
            using (WebClient webClient = new System.Net.WebClient())
            {
                webClient.Headers[HttpRequestHeader.Authorization] = eDHToken;
                webClient.Encoding = System.Text.Encoding.UTF8;
                webClient.QueryString.Add("lang", language);
                var json = webClient.DownloadString(eDHWebService + "DefectComponents");

                DefectSelector temp = new DefectSelector();
                DefectSelector[] array = JsonConvert.DeserializeObject<DefectSelector[]>(json);

                foreach (DefectSelector item in array)
                {
                    result.Add(item);
                }
            }
            return result;
        }

        public List<DefectSelector> GetDefectHowFoundList(string eDHWebService, string eDHToken, string language)
        {
            var result = new List<DefectSelector>();
            using (WebClient webClient = new System.Net.WebClient())
            {
                webClient.Headers[HttpRequestHeader.Authorization] = eDHToken;
                webClient.Encoding = System.Text.Encoding.UTF8;
                webClient.QueryString.Add("lang", language);
                var json = webClient.DownloadString(eDHWebService + "DefectHowFoundList");

                DefectSelector temp = new DefectSelector();
                DefectSelector[] array = JsonConvert.DeserializeObject<DefectSelector[]>(json);

                foreach (DefectSelector item in array)
                {
                    result.Add(item);
                }
            }
            return result;
        }

        public List<DefectSelector> GetDefectPriorities(string eDHWebService, string eDHToken, string language)
        {
            var result = new List<DefectSelector>();
            using (WebClient webClient = new System.Net.WebClient())
            {
                webClient.Headers[HttpRequestHeader.Authorization] = eDHToken;
                webClient.Encoding = System.Text.Encoding.UTF8;
                webClient.QueryString.Add("lang", language);
                var json = webClient.DownloadString(eDHWebService + "DefectPriorities");

                DefectSelector temp = new DefectSelector();
                DefectSelector[] array = JsonConvert.DeserializeObject<DefectSelector[]>(json);

                foreach (DefectSelector item in array)
                {
                    result.Add(item);
                }
            }
            return result;
        }

        public List<FLDefects> GetFLDefects(string _connectionString, string eDHToken, string Credentials, string DepartmentId, string ProdLineId, string ProdUnitId)
        {
            var result = new List<FLDefects>();

            using (WebClient webClient = new WebClient())
            {

                webClient.QueryString.Add("departmentId", DepartmentId ?? "0");
                webClient.QueryString.Add("prodLineId", ProdLineId ?? null);
                webClient.QueryString.Add("prodUnitId", ProdUnitId ?? null);
                webClient.QueryString.Add("puGroupId", null);
                webClient.QueryString.Add("lvl5SubassemblyId", null);
                webClient.QueryString.Add("lvl6SubassemblyId", null);
                webClient.QueryString.Add("lvl7SubassemblyId", null);
                webClient.QueryString.Add("showAll", "true");

                webClient.Headers[HttpRequestHeader.Authorization] = String.Format("Basic {0}", Credentials);
                webClient.Encoding = System.Text.Encoding.UTF8;

                var url = _connectionString.Substring(0, _connectionString.IndexOf("CIL/")) + "/Defect";

                webClient.Headers[HttpRequestHeader.Authorization] = eDHToken;
                var json = webClient.DownloadString(url);

                FLDefects temp = new FLDefects();
                FLDefects[] array = JsonConvert.DeserializeObject<FLDefects[]>(json);

                foreach (FLDefects item in array)
                {
                    //if (item.PMNotification != null)
                    //{
                    //    result.Add(item);
                    //}

                    result.Add(item);
                }
            }
            return result;
        }

        public bool UpdateUDE(string _connectionString, string eDHToken, int edhId, int udeId, bool close = false)
        {
            using (WebClient webClient = new WebClient())
            {
                try
                {
                    string url = _connectionString + edhId.ToString() + "?UDEId=" + udeId.ToString();
                    webClient.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
                    webClient.Headers[HttpRequestHeader.Authorization] = eDHToken;
                    string parameters = "UDEId=" + udeId.ToString();
                    var data = Encoding.UTF8.GetBytes(parameters);
                    webClient.UploadData(url, "PUT", data);
                    return true;
                } catch
                {
                    return false;
                }
            }
        }

        public string AddDefect(CILDefect Defect, string _connectionString, string eDHToken)
        {
            String DefectComponentId = Defect.DefectComponentId.ToString();
            String HowFoundId = Defect.HowFoundId.ToString();
            String PriorityId = Defect.PriorityId.ToString();
            if (String.IsNullOrEmpty(DefectComponentId) || String.IsNullOrEmpty(HowFoundId) || String.IsNullOrEmpty(PriorityId))
            {
                throw new Exception("Defect Component, How Found and/or Priority: cannot be empty");
            }

            using (WebClient webClient = new WebClient())
            {
                try
                {

                    NameValueCollection valuesCollection = new NameValueCollection();

                    valuesCollection.Add("UserName", Defect.UserName);
                    valuesCollection.Add("FLCode", Defect.FLCode);
                    valuesCollection.Add("PMNotification", Defect.PMNotification.ToString());
                    valuesCollection.Add("Description", Defect.Description);
                    valuesCollection.Add("SourceRecordID", Defect.SourceRecordID.ToString());
                    valuesCollection.Add("DefectComponentId", DefectComponentId);
                    valuesCollection.Add("HowFoundId", HowFoundId);
                    valuesCollection.Add("PriorityId", PriorityId);
                    valuesCollection.Add("CM1", Defect.CM1);
                    valuesCollection.Add("CM2", Defect.CM2);
                    valuesCollection.Add("CM3", Defect.CM3);
                    valuesCollection.Add("FoundBy", Defect.FoundBy);
                    valuesCollection.Add("DefectTypeId", Defect.DefectTypeId.ToString());
                    valuesCollection.Add("FixedBy", Defect.FixedBy);
                    valuesCollection.Add("ClosedBy", Defect.ClosedBy);
                    valuesCollection.Add("Repeat", Defect.Repeat.ToString());
                    valuesCollection.Add("DueDate", Defect.DueDate.ToString());

                    //webClient.Headers.Set(HttpRequestHeader.ContentType, "application/x-www-form-urlencoded");
                    //webClient.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";

                    webClient.Headers[HttpRequestHeader.ContentType]="application/x-www-form-urlencoded";

                    var url = _connectionString + "AddDefect";
                    var method = "POST";

                    webClient.Headers[HttpRequestHeader.Authorization] = eDHToken;
                    var data = webClient.UploadValues(url, method, valuesCollection);
                    var response = UnicodeEncoding.UTF8.GetString(data);

                    var jss = new JavaScriptSerializer();
                    Dictionary<string, string> serializeResponse = jss.Deserialize<Dictionary<string, string>>(response);
                    string errorMSG = serializeResponse["errorMSG"];
                    string notifNO = serializeResponse["notifNO"];
                    string defectId = serializeResponse["defectId"];
                    string outPut = errorMSG != string.Empty ? errorMSG : "OK";

                    try
                        {
                            string param_connectionString = ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"];
                            Int64 param_testId = Convert.ToInt64(Defect.SourceRecordID);
                            int param_defectId = Convert.ToInt32(defectId);
                            string param_notifNbr = notifNO;
                            string param_defectType = Defect.DefectTypeCode;
                            string param_description = Defect.Description;
                            int param_userId = Defect.UserId;
                            bool param_fixed = Defect.Fixed;

                            var resultCreated = AddTaskDefectEDH(param_connectionString, param_testId, param_defectId, param_notifNbr, param_defectType, param_description, param_userId, param_fixed);

                            //update UDE
                            UpdateUDE(ConfigurationManager.ConnectionStrings["eDHWebService"].ConnectionString, eDHToken, param_defectId, resultCreated.UDEId, param_fixed);

                            Task tempTask = taskObject.GetTask(param_connectionString, param_testId);
                            tempTask.CurrentResult = Defect.ServerCurrentResult;
                            List<Task> toBeSaved = new List<Task>();
                            toBeSaved.Add(tempTask);
                            return taskObject.SaveTasks(param_connectionString,toBeSaved, param_userId, outPut);
                        }
                        catch (Exception ex)
                        {
                            throw new Exception(ex.Message);
                        }

                }
                catch (WebException ex)
                {
                    if (ex.Message.Contains("404"))
                        throw new Exception("Functional location is not valid");

                    throw new Exception(ex.Message);
                }
            }
        }

        //Add defect in eDefects
        public eDH AddTaskDefectEDH(string _connectionString, Int64 TestId, int DefectId, string NotifNbr, string DefectType, string DefectMsg, int UserId, bool Fixed)
        {
            eDH result = new eDH();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_AddTaskDefect", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.Add(new SqlParameter("@TestId", TestId));
                command.Parameters.Add(new SqlParameter("@NotifNbr", NotifNbr));
                command.Parameters.Add(new SqlParameter("@DefectType", DefectType));
                command.Parameters.Add(new SqlParameter("@DefectMsg", DefectMsg));
                command.Parameters.Add(new SqlParameter("@UserId", UserId));

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        if (!reader.IsDBNull(reader.GetOrdinal("UDE_Id")))
                            result.UDEId = reader.GetInt32(reader.GetOrdinal("UDE_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("UDE_Desc")))
                            result.UDEDesc = reader.GetString(reader.GetOrdinal("UDE_Desc"));
                        if (!reader.IsDBNull(reader.GetOrdinal("PU_Id")))
                            result.PUId = reader.GetInt32(reader.GetOrdinal("PU_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Event_SubType_Id")))
                            result.EventSubTypeId = reader.GetInt32(reader.GetOrdinal("Event_SubType_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Start_Time")))
                            result.StartTime = reader.GetDateTime(reader.GetOrdinal("Start_Time"));
                        if (!reader.IsDBNull(reader.GetOrdinal("End_Time")))
                            result.EndTime = reader.GetDateTime(reader.GetOrdinal("End_Time"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Duration")))
                            result.Duration = reader.GetInt32(reader.GetOrdinal("Duration"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Cause1")))
                            result.Cause1 = reader.GetString(reader.GetOrdinal("Cause1"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Cause2")))
                            result.Cause2 = reader.GetString(reader.GetOrdinal("Cause2"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Cause3")))
                            result.Cause3 = reader.GetString(reader.GetOrdinal("Cause3"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Cause4")))
                            result.Cause4 = reader.GetString(reader.GetOrdinal("Cause4"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Cause_Comment_Id")))
                            result.CauseCommentId = reader.GetInt32(reader.GetOrdinal("Cause_Comment_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Action1")))
                            result.Action1 = reader.GetString(reader.GetOrdinal("Action1"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Action2")))
                            result.Action2 = reader.GetString(reader.GetOrdinal("Action2"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Action3")))
                            result.Action3 = reader.GetString(reader.GetOrdinal("Action3"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Action4")))
                            result.Action4 = reader.GetString(reader.GetOrdinal("Action4"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Action_comment_Id")))
                            result.ActionCommentId = reader.GetInt32(reader.GetOrdinal("Action_comment_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Research_User_Id")))
                            result.ReaserchUserId = reader.GetInt32(reader.GetOrdinal("Research_User_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Research_Status_Id")))
                            result.ReaserchStatusId = reader.GetInt32(reader.GetOrdinal("Research_User_Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Research_Open_Date")))
                            result.ReasearchOpenDate = reader.GetString(reader.GetOrdinal("Research_Open_Date"));
                    }

                    reader.Read();

                    if (reader.HasRows)
                    {
                        try
                        {
                            string param_connectionString = ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"];
                            bool param_close = Fixed;

                            if (param_close)
                            {
                                CloseDefect(param_connectionString, result.UDEId);
                            }
                            
                        }
                        catch (Exception ex)
                        {
                            throw new Exception(ex.Message);
                        }
                    } else
                    {
                        throw new Exception("Notification was created in SAP but an error occurred while saving to eCIL.");
                    }

                }
            }
            return result;
        }

        //Close a defect based on TestId
        public string CloseDefect(string _connectionString, int UDEId)
        {

            SqlParameter ParamErrorMessage = new SqlParameter();
            ParamErrorMessage.ParameterName = "@ErrorMessage";
            ParamErrorMessage.DbType = System.Data.DbType.String;
            ParamErrorMessage.Direction = System.Data.ParameterDirection.Output;
            ParamErrorMessage.Value = String.Empty;

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_CloseDefect", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@UDEId", UDEId));
                command.Parameters.Add(ParamErrorMessage);

                command.ExecuteNonQuery();
                conn.Close();
            }
            if (ParamErrorMessage.Value == DBNull.Value)
                return string.Empty;
            else
                return ParamErrorMessage.Value.ToString();
        }


        public FLPlantModel GetPlantModelByFLCode(string _connectionString, string FLCode)
        {
            var FLPlantModel = new FLPlantModel();

            if (FLCode == null) return FLPlantModel;

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {

                try
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eDHGetPlantModelByFLCode", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@FLCode", FLCode));

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            if (!reader.IsDBNull(reader.GetOrdinal("FLId")))
                                FLPlantModel.FLId = reader.GetInt32(reader.GetOrdinal("FLId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("FLCode")))
                                FLPlantModel.FLCode = reader.GetString(reader.GetOrdinal("FLCode"));
                            if (!reader.IsDBNull(reader.GetOrdinal("DepartmentId")))
                                FLPlantModel.DepartmentId = reader.GetInt32(reader.GetOrdinal("DepartmentId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("ProdLineId")))
                                FLPlantModel.ProdLineId = reader.GetInt32(reader.GetOrdinal("ProdLineId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("ProdUnitId")))
                                FLPlantModel.ProdUnitId = reader.GetInt32(reader.GetOrdinal("ProdUnitId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("PuGroupId")))
                                FLPlantModel.PuGroupId = reader.GetInt32(reader.GetOrdinal("PuGroupId"));
                        }

                    }
                    conn.Close();
                }
                catch (Exception ex)
                {
                    throw new Exception(ex.Message);
                }
            }

            return FLPlantModel;
        }

        public List<DefectHistory> GetEmagDefectDetails(string _connectionString, int VarId, string ColumnTime)
        {
            var result = new List<DefectHistory>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_Report_eMag_defectDetails", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@VarId", VarId));
                command.Parameters.Add(new SqlParameter("@ColumnTime", ColumnTime));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        DefectHistory temp = new DefectHistory();

                        if (!reader.IsDBNull(reader.GetOrdinal("DefectStart")))
                            temp.DefectStart = reader.GetString(reader.GetOrdinal("DefectStart"));
                        if (!reader.IsDBNull(reader.GetOrdinal("DefectEnd")))
                            temp.DefectEnd = reader.GetString(reader.GetOrdinal("DefectEnd"));
                        if (!reader.IsDBNull(reader.GetOrdinal("FL")))
                            temp.FL = reader.GetString(reader.GetOrdinal("FL"));
                        if (!reader.IsDBNull(reader.GetOrdinal("DefectType")))
                            temp.DefectType = reader.GetString(reader.GetOrdinal("DefectType"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ReportedBy")))
                            temp.ReportedBy = reader.GetString(reader.GetOrdinal("ReportedBy"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Notification")))
                            temp.Notification = reader.GetString(reader.GetOrdinal("Notification"));
                        if (!reader.IsDBNull(reader.GetOrdinal("Description")))
                            temp.Description = reader.GetString(reader.GetOrdinal("Description"));

                        result.Add(temp);
                    }
                }
                conn.Close();
            }
            return result;


        }

        #endregion

    }

}
