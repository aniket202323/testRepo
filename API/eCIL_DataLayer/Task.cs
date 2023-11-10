using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Web.UI.WebControls;

namespace eCIL_DataLayer
{
    public class Task
    {
        #region Variables
        private bool isDirty;
        private int slaveUnitId;
        private Int64 testId;
        private int nbrDefects;
        private int varId;
        private string slaveUnitDesc;
        private string masterUnitDesc;
        private int masterUnitId;
        private string taskId;
        private string varDesc;
        private string taskFreq;
        private string taskType;
        private string scheduleTime;
        private DateTime resulton;
        private string lateTime;
        private string dueTime;
        private string currentResult;
        private int commentId;
        private string commentInfo;
        private bool alarmFlag;
        private string lineDesc;
        private string duration;
        private string userNameTest;
        private string longTaskName;
        private string externalLink;
        private string displayLink;
        private string eventSubtypeDesc;
        private string fl3;
        private string fl4;
        private string fl1;
        private string fl2;
        private string fl;
        private int plId;
        private string routeDesc;
        private string tourDesc;
        private int tourId;
        private string teamDesc;
        private int taskOrder;
        private int itemNo;
        private string fixedFreq;
        private string taskAction;
        private string criteria;
        private string hazards;
        private string method;
        private string ppe;
        private string tools;
        private string lubricant;
        private string qFactorType;
        private string primaryQFactor;
        private bool isHSE;
        private bool isChangedHSE;
        private string nbrPeople;
        private string nbrItems;
        private bool commit;
        private string saveErrorMessage;
        private List<Defect> defects;
        //Flag to indicate if the task was posponed or not
        private bool isPosponed;
        //After a save with posponed time, this flag will indicate if the task must be
        //displayed. It should if still in the current shift
        private bool isInShift;
        //We keep a copy of the initial Result to be able to bring back
        //the original value when the result is changed to Defect, then
        //canceled before saving
        private string initialResult;
        //avoid adding defects on other instances of a task than the last one
        private bool isDefectLooked;
        private bool autoPostpone;
        private string l_Reject;
        private string target;
        private string u_Reject;
        private string varDataType;
        #endregion

        #region Properties
        public bool IsDirty { get => isDirty; set => isDirty = value; }
        public int SlaveUnitId { get => slaveUnitId; set => slaveUnitId = value; }
        public Int64 TestId { get => testId; set => testId = value; }
        public int NbrDefects { get => nbrDefects; set => nbrDefects = value; }
        public int VarId { get => varId; set => varId = value; }
        public string SlaveUnitDesc { get => slaveUnitDesc; set => slaveUnitDesc = value; }
        public string MasterUnitDesc { get => masterUnitDesc; set => masterUnitDesc = value; }
        public string TaskId { get => taskId; set => taskId = value; }
        public string VarDesc { get => varDesc; set => varDesc = value; }
        public string TaskFreq { get => taskFreq; set => taskFreq = value; }
        public string TaskType { get => taskType; set => taskType = value; }
        public string ScheduleTime { get => scheduleTime; set => scheduleTime = value; }
        public DateTime ResultOn { get => resulton; set => resulton = value; }
        public string LateTime { get => lateTime; set => lateTime = value; }
        public string DueTime { get => dueTime; set => dueTime = value; }
        public string CurrentResult { get => currentResult; set => currentResult = value; }
        public int CommentId { get => commentId; set => commentId = value; }
        public string CommentInfo { get => commentInfo; set => commentInfo = value; }
        public bool AlarmFlag { get => alarmFlag; set => alarmFlag = value; }
        public string LineDesc { get => lineDesc; set => lineDesc = value; }
        public string Duration { get => duration; set => duration = value; }
        public string UserNameTest { get => userNameTest; set => userNameTest = value; }
        public string LongTaskName { get => longTaskName; set => longTaskName = value; }
        public string ExternalLink { get => externalLink; set => externalLink = value; }
        public string DisplayLink { get => displayLink; set => displayLink = value; }
        public string EventSubtypeDesc { get => eventSubtypeDesc; set => eventSubtypeDesc = value; }
        public string FL3 { get => fl3; set => fl3 = value; }
        public string FL4 { get => fl4; set => fl4 = value; }
        public string FL1 { get => fl1; set => fl1 = value; }
        public string FL2 { get => fl2; set => fl2 = value; }
        public string FL5 { get => fl; set => fl = value; }
        public int PLId { get => plId; set => plId = value; }
        public string RouteDesc { get => routeDesc; set => routeDesc = value; }
        public string TourDesc { get => tourDesc; set => tourDesc = value; }
        public int TourId { get => tourId; set => tourId = value; }
        public string TeamDesc { get => teamDesc; set => teamDesc = value; }
        public int TaskOrder { get => taskOrder; set => taskOrder = value; }
        public int ItemNo { get => itemNo; set => itemNo = value; }
        public string Fixed { get => fixedFreq; set => fixedFreq = value; }
        public string TaskAction { get => taskAction; set => taskAction = value; }
        public string Criteria { get => criteria; set => criteria = value; }
        public string Hazards { get => hazards; set => hazards = value; }
        public string Method { get => method; set => method = value; }
        public string PPE { get => ppe; set => ppe = value; }
        public string Tools { get => tools; set => tools = value; }
        public string Lubricant { get => lubricant; set => lubricant = value; }
        public string QFactorType { get => qFactorType; set => qFactorType = value; }
        public string PrimaryQFactor { get => primaryQFactor; set => primaryQFactor = value; }
        public bool IsHSE { get => isHSE; set => isHSE = value; }
        public string NbrPeople { get => nbrPeople; set => nbrPeople = value; }
        public string NbrItems { get => nbrItems; set => nbrItems = value; }
        public bool Commit { get => commit; set => commit = value; }
        public string SaveErrorMessage { get => saveErrorMessage; set => saveErrorMessage = value; }
        public List<Defect> Defects { get => defects; set => defects = value; }
        public bool IsPosponed { get => isPosponed; set => isPosponed = value; }
        public bool IsInShift { get => isInShift; set => isInShift = value; }
        public string InitialResult { get => initialResult; set => initialResult = value; }
        public bool IsDefectLooked { get => isDefectLooked; set => isDefectLooked = value; }
        public int MasterUnitId { get => masterUnitId; set => masterUnitId = value; }
        public bool IsChangedHSE { get => isChangedHSE; set => isChangedHSE = value; }
        public bool AutoPostpone { get => autoPostpone; set => autoPostpone = value; }
        public string L_Reject { get => l_Reject; set => l_Reject = value; }
        public string Target { get => target; set => target = value; }
        public string U_Reject { get => u_Reject; set => u_Reject = value; }
        public string VarDataType { get => varDataType; set => varDataType = value; }
        #endregion

        #region Constructor
        public Task()
        {
            IsDirty = false;
            SlaveUnitId = 0;
            TestId = 0;
            NbrDefects = 0;
            VarId = 0;
            SlaveUnitDesc = string.Empty;
            MasterUnitDesc = string.Empty;
            TaskId = string.Empty;
            VarDesc = string.Empty;
            TaskFreq = string.Empty;
            TaskType = string.Empty;
            ScheduleTime = string.Empty;
            ResultOn = new DateTime();
            LateTime = string.Empty;
            DueTime = string.Empty;
            CurrentResult = string.Empty;
            CommentId = 0;
            CommentInfo = string.Empty;
            AlarmFlag = false;
            LineDesc = string.Empty;
            Duration = string.Empty;
            UserNameTest = string.Empty;
            LongTaskName = string.Empty;
            ExternalLink = string.Empty;
            DisplayLink = string.Empty;
            EventSubtypeDesc = string.Empty;
            FL3 = string.Empty;
            FL4 = string.Empty;
            FL1 = string.Empty;
            FL2 = string.Empty;
            FL5 = string.Empty;
            PLId = 0;
            RouteDesc = string.Empty;
            TeamDesc = string.Empty;
            TaskOrder = 0;
            ItemNo = 0;
            Fixed = string.Empty;
            TaskAction = string.Empty;
            Criteria = string.Empty;
            Hazards = string.Empty;
            Method = string.Empty;
            PPE = string.Empty;
            Tools = string.Empty;
            Lubricant = string.Empty;
            QFactorType = string.Empty;
            PrimaryQFactor = string.Empty;
            IsHSE = false;
            NbrPeople = string.Empty;
            NbrItems = string.Empty;
            Commit = false;
            SaveErrorMessage = string.Empty;
            Defects = new List<Defect>();
            IsPosponed = false;
            IsInShift = false;
            InitialResult = string.Empty;
            IsDefectLooked = false;
            MasterUnitId = 0;
            isChangedHSE = false;
            AutoPostpone = false;
            L_Reject = string.Empty;
            Target = string.Empty;
            U_Reject = string.Empty;
            VarDataType = string.Empty;
        }
        #endregion

        public class ResultPrompts
        {
            #region Variables
            private Dictionary<int, string> serverPrompts;
            private Dictionary<int, string> userPrompts;
            #endregion

            #region Properties
            public Dictionary<int, string> ServerPrompts { get => serverPrompts; set => serverPrompts = value; }
            public Dictionary<int, string> UserPrompts { get => userPrompts; set => userPrompts = value; }
            #endregion

        }

        public class ServerTaskResultPrompts
        {
            #region Variables
            private int promptPosition;
            private string serverPrompt;
            private string userPrompt;
            #endregion

            #region Properties
            public int PromptPosition { get => promptPosition; set => promptPosition = value; }
            public string ServerPrompt { get => serverPrompt; set => serverPrompt = value; }
            public string UserPrompt { get => userPrompt; set => userPrompt = value; }
            #endregion

            #region Methods
            public ServerTaskResultPrompts()
            {
                PromptPosition = 0;
                ServerPrompt = "";
                UserPrompt = "";
            }
            public ServerTaskResultPrompts(int promptPosition, string serverPrompt, string userPrompt)
            {
                PromptPosition = promptPosition;
                ServerPrompt = serverPrompt;
                UserPrompt = userPrompt;
            }
            #endregion
        }

        public class LineTasksForPlantModel
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

        public class TaskDetails
        {
            #region Variable
            private Int64 testId;
            private string taskName;
            private string longTaskName;
            private string taskAction;
            private string eventSubtypeDesc;
            private string fL1;
            private string fL2;
            private string fL3;
            private string fL4;
            private string taskId;
            private string taskFrequency;
            private string taskType;
            private DateTime EntryOn;
            private string criteria;
            private string hazards;
            private string method;
            private string ppe;
            private string tools;
            private string lubricant;
            #endregion

            #region Properties
            public Int64 TestId { get => testId; set => testId = value; }
            public string TaskName { get => taskName; set => taskName = value; }
            public string LongTaskName { get => longTaskName; set => longTaskName = value; }
            public string TaskAction { get => taskAction; set => taskAction = value; }
            public string EventSubtypeDesc { get => eventSubtypeDesc; set => eventSubtypeDesc = value; }
            public string FL1 { get => fL1; set => fL1 = value; }
            public string FL2 { get => fL2; set => fL2 = value; }
            public string FL3 { get => fL3; set => fL3 = value; }
            public string FL4 { get => fL4; set => fL4 = value; }
            public string TaskId { get => taskId; set => taskId = value; }
            public string TaskFrequency { get => taskFrequency; set => taskFrequency = value; }
            public string TaskType { get => taskType; set => taskType = value; }
            public DateTime EntryOn1 { get => EntryOn; set => EntryOn = value; }
            public string Criteria { get => criteria; set => criteria = value; }
            public string Hazards { get => hazards; set => hazards = value; }
            public string Method { get => method; set => method = value; }
            public string Ppe { get => ppe; set => ppe = value; }
            public string Tools { get => tools; set => tools = value; }
            public string Lubricant { get => lubricant; set => lubricant = value; }
            #endregion

            #region Contructor
            public TaskDetails()
            {
                TestId = 0;
                TaskName = string.Empty;
                LongTaskName = string.Empty;
                TaskAction = string.Empty;
                FL1 = string.Empty;
                FL2 = string.Empty;
                FL3 = string.Empty;
                FL4 = string.Empty;
                TaskId = string.Empty;
                TaskFrequency = string.Empty;
                TaskType = string.Empty;
                EntryOn = new DateTime();
                Criteria = string.Empty;
                Hazards = string.Empty;
                Method = string.Empty;
                Ppe = string.Empty;
                Tools = string.Empty;
                Lubricant = string.Empty;
                EventSubtypeDesc = string.Empty;
            }
            #endregion

            #region Methods
            public TaskDetails GetTaskDetails(string _connectionString, Int64 testIdd)
            {
                TaskDetails result = new TaskDetails();
                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_GetTaskDetails", conn);
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@TestId", testIdd));
                    using(SqlDataReader reader = command.ExecuteReader())
                    {
                        while(reader.Read())
                        {
                            if (!reader.IsDBNull(reader.GetOrdinal("TestId")))
                                result.TestId = reader.GetInt64(reader.GetOrdinal("TestId"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskName")))
                                result.TaskName = reader.GetString(reader.GetOrdinal("TaskName"));

                            if (!reader.IsDBNull(reader.GetOrdinal("LongTaskName")))
                                result.LongTaskName = reader.GetString(reader.GetOrdinal("LongTaskName"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskAction")))
                                result.TaskAction = reader.GetString(reader.GetOrdinal("TaskAction"));

                            if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                                result.FL1 = reader.GetString(reader.GetOrdinal("FL1"));

                            if(!reader.IsDBNull(reader.GetOrdinal("FL2")))
                                result.FL2 = reader.GetString(reader.GetOrdinal("FL2"));

                            if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                                result.FL3 = reader.GetString(reader.GetOrdinal("FL3"));

                            if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                                result.FL4 = reader.GetString(reader.GetOrdinal("FL4"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskId")))
                                result.TaskId = reader.GetString(reader.GetOrdinal("TaskId"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskFrequency")))
                                result.TaskFrequency = reader.GetString(reader.GetOrdinal("TaskFrequency"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskType")))
                                result.TaskType = reader.GetString(reader.GetOrdinal("TaskType"));

                            if (!reader.IsDBNull(reader.GetOrdinal("EntryOn")))
                                result.EntryOn = reader.GetDateTime(reader.GetOrdinal("EntryOn"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Criteria")))
                                result.Criteria = reader.GetString(reader.GetOrdinal("Criteria"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Hazards")))
                                result.Hazards = reader.GetString(reader.GetOrdinal("Hazards"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Method")))
                                result.Method = reader.GetString(reader.GetOrdinal("Method"));

                            if (!reader.IsDBNull(reader.GetOrdinal("PPE")))
                                result.Ppe = reader.GetString(reader.GetOrdinal("PPE"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Tools")))
                                result.Tools = reader.GetString(reader.GetOrdinal("Tools"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Lubricant")))
                                result.Lubricant = reader.GetString(reader.GetOrdinal("Lubricant"));

                        }
                        reader.Close();
                    }
                    conn.Close();
                }
                return result;
            }
            #endregion
        }



        #region Constant
        public const string START_DATE = "eCIL_StartDate";
        public const string TEST_TIME = "eCIL_TestTime";
        public const string LONG_TASK_NAME = "eCIL_LongTaskName";
        public const string TASK_ID = "eCIL_TaskId";
        public const string TASK_ACTION = "eCIL_TaskAction";
        public const string NBR_ITEMS = "eCIL_NbrItems";
        public const string TASK_TYPE = "eCIL_TaskType";
        public const string DURATION = "eCIL_Duration";
        public const string NBR_PEOPLE = "eCIL_NbrPeople";
        public const string CRITERIA = "eCIL_Criteria";
        public const string HAZARDS = "eCIL_Hazards";
        public const string METHOD = "eCIL_Method";
        public const string PPECONST = "eCIL_PPE";
        public const string TOOLS = "eCIL_Tools";
        public const string LUBRICANT = "eCIL_Lubricant";
        public const string DOCUMENT_LINK_TITLE = "eCIL_DocumentLinkTitle";
        public const string Q_FACTOR_TYPE = "Q-Factor Type";
        public const string PRIMARY_Q_FACTOR = "Primary Q-Factor?";
        public const string FIXED_FREQUENCY = "eCIL_FixedFrequency";
        public const string TASK_FREQUENCY = "eCIL_TaskFrequency";
        public const string SHIFT_OFFSET = "eCIL_ShiftOffset";
        public const string VM_ID = "eCIL_VMId";
        public const string TASK_LOCATION = "eCIL_TaskLocation";
        public const string IS_HSE = "HSE Flag";


        #endregion

        #region Methods
        public List<Task> GetTasksList(string _connectionString, string ParamTaskType, string ParamResultFilter, string ParamVarId, string ParamDepts = "", string ParamLines = "", string ParamMasters = "", string ParamSlaves = "", string ParamTeams = "", string ParamRoutes = "")
        {
            var result = new List<Task>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetTasksList", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@DeptsList", ParamDepts));
                command.Parameters.Add(new SqlParameter("@LinesList", ParamLines));
                command.Parameters.Add(new SqlParameter("@MastersList", ParamMasters));
                command.Parameters.Add(new SqlParameter("@SlavesList", ParamSlaves));
                command.Parameters.Add(new SqlParameter("@TeamsList", ParamTeams));
                command.Parameters.Add(new SqlParameter("@RoutesList", ParamRoutes));
                command.Parameters.Add(new SqlParameter("@TaskTypeFilter", ParamTaskType));
                command.Parameters.Add(new SqlParameter("@TaskResultFilter", ParamResultFilter));
                command.Parameters.Add(new SqlParameter("@VarId", ParamVarId));

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {

                        Task task = new Task();
                        if (!reader.IsDBNull(reader.GetOrdinal("Event_Subtype_Desc")))
                            task.EventSubtypeDesc = reader.GetString(reader.GetOrdinal("Event_Subtype_Desc"));
                        else
                            task.EventSubtypeDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("ItemNo")))
                            task.ItemNo = reader.GetInt32(reader.GetOrdinal("ItemNo"));
                        else
                            task.ItemNo = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitId")))
                            task.SlaveUnitId = reader.GetInt32(reader.GetOrdinal("SlaveUnitId"));
                        else
                            task.SlaveUnitId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("TestId")))
                            task.TestId = reader.GetInt64(reader.GetOrdinal("TestId"));
                        else
                            task.TestId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("NbrDefects")))
                            task.NbrDefects = reader.GetInt32(reader.GetOrdinal("NbrDefects"));
                        else
                            task.NbrDefects = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                            task.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));
                        else
                            task.VarId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitDesc")))
                            task.SlaveUnitDesc = reader.GetString(reader.GetOrdinal("SlaveUnitDesc"));
                        else
                            task.SlaveUnitDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitDesc")))
                            task.MasterUnitDesc = reader.GetString(reader.GetOrdinal("MasterUnitDesc"));
                        else
                            task.MasterUnitDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("TaskId")))
                            task.TaskId = reader.GetString(reader.GetOrdinal("TaskId"));
                        else
                            task.TaskId = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("VarDesc")))
                            task.VarDesc = reader.GetString(reader.GetOrdinal("VarDesc"));
                        else
                            task.VarDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("TaskFreq")))
                            task.TaskFreq = reader.GetString(reader.GetOrdinal("TaskFreq"));
                        else
                            task.TaskFreq = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("TaskType")))
                            task.TaskType = reader.GetString(reader.GetOrdinal("TaskType"));
                        else
                            task.TaskType = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("CurrentResult")))
                            task.CurrentResult = reader.GetString(reader.GetOrdinal("CurrentResult"));
                        else
                            task.CurrentResult = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("CommentId")))
                            task.CommentId = reader.GetInt32(reader.GetOrdinal("CommentId"));
                        else
                            task.CommentId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("CommentInfo")))
                            task.CommentInfo = reader.GetString(reader.GetOrdinal("CommentInfo"));
                        else
                            task.CommentInfo = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("LineDesc")))
                            task.LineDesc = reader.GetString(reader.GetOrdinal("LineDesc"));
                        else
                            task.LineDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("UserNameTest")))
                            task.UserNameTest = reader.GetString(reader.GetOrdinal("UserNameTest"));
                        else
                            task.UserNameTest = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Duration")))
                            task.Duration = reader.GetString(reader.GetOrdinal("Duration"));
                        else
                            task.Duration = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("LongTaskName")))
                            task.LongTaskName = reader.GetString(reader.GetOrdinal("LongTaskName"));
                        else
                            task.LongTaskName = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("ExternalLink")))
                            task.ExternalLink = reader.GetString(reader.GetOrdinal("ExternalLink"));
                        else
                            task.ExternalLink = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("DisplayLink")))
                            task.DisplayLink = reader.GetString(reader.GetOrdinal("DisplayLink"));
                        else
                            task.DisplayLink = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                            task.FL1 = reader.GetString(reader.GetOrdinal("FL1"));
                        else
                            task.FL1 = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                            task.FL2 = reader.GetString(reader.GetOrdinal("FL2"));
                        else
                            task.FL2 = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                            task.FL3 = reader.GetString(reader.GetOrdinal("FL3"));
                        else
                            task.FL3 = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                            task.FL4 = reader.GetString(reader.GetOrdinal("FL4"));
                        else
                            task.FL4 = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("PL_Id")))
                            task.PLId = reader.GetInt32(reader.GetOrdinal("PL_Id"));
                        else
                            task.PLId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("RouteDesc")))
                            task.RouteDesc = reader.GetString(reader.GetOrdinal("RouteDesc"));
                        else
                            task.RouteDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Desc")))
                            task.TourDesc = reader.GetString(reader.GetOrdinal("Tour_Stop_Desc"));
                        else
                            task.TourDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Id")))
                            task.TourId = reader.GetInt32(reader.GetOrdinal("Tour_Stop_Id"));
                        else
                            task.TourId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("TaskOrder")))
                            task.TaskOrder = reader.GetInt32(reader.GetOrdinal("TaskOrder"));
                        else
                            task.TaskOrder = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("TeamDesc")))
                            task.TeamDesc = reader.GetString(reader.GetOrdinal("TeamDesc"));
                        else
                            task.TeamDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("FixedFreq")))
                        {
                            string tempFixedFrequency = reader.GetString(reader.GetOrdinal("FixedFreq"));
                            switch (tempFixedFrequency)
                            {
                                case "0":
                                    task.Fixed = "0";
                                    task.AutoPostpone = false;
                                    break;
                                case "1":
                                    task.Fixed = "1";
                                    task.AutoPostpone = false;
                                    break;
                                case "2":
                                    task.Fixed = "0";
                                    task.AutoPostpone = true;
                                    break;
                            }
                            //task.Fixed1 = reader.GetString(reader.GetOrdinal("FixedFreq"));
                        }

                        else
                        {
                            task.Fixed = string.Empty;
                            task.AutoPostpone = false;
                        }


                        if (!reader.IsDBNull(reader.GetOrdinal("ScheduleTime")))
                            task.ScheduleTime = reader.GetString(reader.GetOrdinal("ScheduleTime"));
                        else
                            task.ScheduleTime = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("LateTime")))
                            task.LateTime = reader.GetString(reader.GetOrdinal("LateTime"));
                        else
                            task.LateTime = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("DueTime")))
                            task.DueTime = reader.GetString(reader.GetOrdinal("DueTime"));
                        else
                            task.DueTime = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("TaskAction")))
                            task.TaskAction = reader.GetString(reader.GetOrdinal("TaskAction"));
                        else
                            task.TaskAction = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Criteria")))
                            task.Criteria = reader.GetString(reader.GetOrdinal("Criteria"));
                        else
                            task.Criteria = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Hazards")))
                            task.Hazards = reader.GetString(reader.GetOrdinal("Hazards"));
                        else
                            task.Hazards = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Method")))
                            task.Method = reader.GetString(reader.GetOrdinal("Method"));
                        else
                            task.Method = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("PPE")))
                            task.PPE = reader.GetString(reader.GetOrdinal("PPE"));
                        else
                            task.PPE = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Tools")))
                            task.Tools = reader.GetString(reader.GetOrdinal("Tools"));
                        else
                            task.Tools = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Lubricant")))
                            task.Lubricant = reader.GetString(reader.GetOrdinal("Lubricant"));
                        else
                            task.Lubricant = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("QFactorType")))
                            task.QFactorType = reader.GetString(reader.GetOrdinal("QFactorType"));
                        else
                            task.QFactorType = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("PrimaryQFactor")))
                            task.PrimaryQFactor = reader.GetString(reader.GetOrdinal("PrimaryQFactor"));
                        else
                            task.PrimaryQFactor = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("NbrPeople")))
                            task.NbrPeople = reader.GetString(reader.GetOrdinal("NbrPeople"));
                        else
                            task.NbrPeople = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("NbrItems")))
                            task.NbrItems = reader.GetString(reader.GetOrdinal("NbrItems"));
                        else
                            task.NbrItems = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("HSEFlag")))
                        {
                            string aux = reader.GetString(reader.GetOrdinal("HSEFlag"));
                            if (aux == "1" || aux.ToLower() == "true")
                                task.IsHSE = true;
                            else
                                task.IsHSE = false;
                        }

                        else
                            task.IsHSE = false;

                        if (!reader.IsDBNull(reader.GetOrdinal("IsDefectLocked")))
                            task.IsDefectLooked = reader.GetBoolean(reader.GetOrdinal("IsDefectLocked"));


                        result.Add(task);
                    }
                    reader.Close();
                }
                conn.Close();
            }
            if (ParamRoutes != "")
            {
                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_GetTasksListCL", conn);
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@RoutesList", ParamRoutes));
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            Task task = new Task();
                            if (!reader.IsDBNull(reader.GetOrdinal("Event_Subtype_Desc")))
                                task.EventSubtypeDesc = reader.GetString(reader.GetOrdinal("Event_Subtype_Desc"));
                            else
                                task.EventSubtypeDesc = string.Empty;
                            if (!reader.IsDBNull(reader.GetOrdinal("ItemNo")))
                                task.ItemNo = reader.GetInt32(reader.GetOrdinal("ItemNo"));
                            else
                                task.ItemNo = -1;

                            if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitId")))
                                task.SlaveUnitId = reader.GetInt32(reader.GetOrdinal("SlaveUnitId"));
                            else
                                task.SlaveUnitId = -1;

                            if (!reader.IsDBNull(reader.GetOrdinal("TestId")))
                                task.TestId = reader.GetInt64(reader.GetOrdinal("TestId"));
                            else
                                task.TestId = -1;

                            if (!reader.IsDBNull(reader.GetOrdinal("NbrDefects")))
                                task.NbrDefects = reader.GetInt32(reader.GetOrdinal("NbrDefects"));
                            else
                                task.NbrDefects = -1;

                            if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                                task.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));
                            else
                                task.VarId = -1;

                            if (!reader.IsDBNull(reader.GetOrdinal("VarDataType")))
                                task.VarDataType = reader.GetString(reader.GetOrdinal("VarDataType"));
                            else
                                task.VarId = -1;

                            if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitDesc")))
                                task.SlaveUnitDesc = reader.GetString(reader.GetOrdinal("SlaveUnitDesc"));
                            else
                                task.SlaveUnitDesc = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitDesc")))
                                task.MasterUnitDesc = reader.GetString(reader.GetOrdinal("MasterUnitDesc"));
                            else
                                task.MasterUnitDesc = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskId")))
                                task.TaskId = reader.GetString(reader.GetOrdinal("TaskId"));
                            else
                                task.TaskId = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("VarDesc")))
                                task.VarDesc = reader.GetString(reader.GetOrdinal("VarDesc"));
                            else
                                task.VarDesc = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskFreq")))
                                task.TaskFreq = reader.GetString(reader.GetOrdinal("TaskFreq"));
                            else
                                task.TaskFreq = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskType")))
                                task.TaskType = reader.GetString(reader.GetOrdinal("TaskType"));
                            else
                                task.TaskType = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("CurrentResult")))
                                task.CurrentResult = reader.GetString(reader.GetOrdinal("CurrentResult"));
                            else
                                task.CurrentResult = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("CommentId")))
                                task.CommentId = reader.GetInt32(reader.GetOrdinal("CommentId"));
                            else
                                task.CommentId = -1;

                            if (!reader.IsDBNull(reader.GetOrdinal("CommentInfo")))
                                task.CommentInfo = reader.GetString(reader.GetOrdinal("CommentInfo"));
                            else
                                task.CommentInfo = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("LineDesc")))
                                task.LineDesc = reader.GetString(reader.GetOrdinal("LineDesc"));
                            else
                                task.LineDesc = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("UserNameTest")))
                                task.UserNameTest = reader.GetString(reader.GetOrdinal("UserNameTest"));
                            else
                                task.UserNameTest = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("Duration")))
                                task.Duration = reader.GetString(reader.GetOrdinal("Duration"));
                            else
                                task.Duration = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("LongTaskName")))
                                task.LongTaskName = reader.GetString(reader.GetOrdinal("LongTaskName"));
                            else
                                task.LongTaskName = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("ExternalLink")))
                                task.ExternalLink = reader.GetString(reader.GetOrdinal("ExternalLink"));
                            else
                                task.ExternalLink = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("DisplayLink")))
                                task.DisplayLink = reader.GetString(reader.GetOrdinal("DisplayLink"));
                            else
                                task.DisplayLink = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                                task.FL1 = reader.GetString(reader.GetOrdinal("FL1"));
                            else
                                task.FL1 = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                                task.FL2 = reader.GetString(reader.GetOrdinal("FL2"));
                            else
                                task.FL2 = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                                task.FL3 = reader.GetString(reader.GetOrdinal("FL3"));
                            else
                                task.FL3 = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                                task.FL4 = reader.GetString(reader.GetOrdinal("FL4"));
                            else
                                task.FL4 = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("PL_Id")))
                                task.PLId = reader.GetInt32(reader.GetOrdinal("PL_Id"));
                            else
                                task.PLId = -1;

                            if (!reader.IsDBNull(reader.GetOrdinal("RouteDesc")))
                                task.RouteDesc = reader.GetString(reader.GetOrdinal("RouteDesc"));
                            else
                                task.RouteDesc = string.Empty;
                            if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Desc")))
                                task.TourDesc = reader.GetString(reader.GetOrdinal("Tour_Stop_Desc"));
                            else
                                task.TourDesc = string.Empty;
                            if (!reader.IsDBNull(reader.GetOrdinal("Tour_Stop_Id")))
                                task.TourId = reader.GetInt32(reader.GetOrdinal("Tour_Stop_Id"));
                            else
                                task.TourId = -1;
                            if (!reader.IsDBNull(reader.GetOrdinal("TaskOrder")))
                                task.TaskOrder = reader.GetInt32(reader.GetOrdinal("TaskOrder"));
                            else
                                task.TaskOrder = -1;

                            if (!reader.IsDBNull(reader.GetOrdinal("TeamDesc")))
                                task.TeamDesc = reader.GetString(reader.GetOrdinal("TeamDesc"));
                            else
                                task.TeamDesc = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("FixedFreq")))
                            {
                                string tempFixedFrequency = reader.GetString(reader.GetOrdinal("FixedFreq"));
                                switch (tempFixedFrequency)
                                {
                                    case "0":
                                        task.Fixed = "0";
                                        task.AutoPostpone = false;
                                        break;
                                    case "1":
                                        task.Fixed = "1";
                                        task.AutoPostpone = false;
                                        break;
                                    case "2":
                                        task.Fixed = "0";
                                        task.AutoPostpone = true;
                                        break;
                                }
                                //task.Fixed1 = reader.GetString(reader.GetOrdinal("FixedFreq"));
                            }

                            else
                            {
                                task.Fixed = string.Empty;
                                task.AutoPostpone = false;
                            }


                            if (!reader.IsDBNull(reader.GetOrdinal("ScheduleTime")))
                                task.ScheduleTime = reader.GetString(reader.GetOrdinal("ScheduleTime"));
                            else
                                task.ScheduleTime = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("ResultOn")))
                                task.ResultOn = reader.GetDateTime(reader.GetOrdinal("ResultOn"));

                            if (!reader.IsDBNull(reader.GetOrdinal("LateTime")))
                                task.LateTime = reader.GetString(reader.GetOrdinal("LateTime"));
                            else
                                task.LateTime = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("DueTime")))
                                task.DueTime = reader.GetString(reader.GetOrdinal("DueTime"));
                            else
                                task.DueTime = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskAction")))
                                task.TaskAction = reader.GetString(reader.GetOrdinal("TaskAction"));
                            else
                                task.TaskAction = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("Criteria")))
                                task.Criteria = reader.GetString(reader.GetOrdinal("Criteria"));
                            else
                                task.Criteria = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("Hazards")))
                                task.Hazards = reader.GetString(reader.GetOrdinal("Hazards"));
                            else
                                task.Hazards = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("Method")))
                                task.Method = reader.GetString(reader.GetOrdinal("Method"));
                            else
                                task.Method = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("PPE")))
                                task.PPE = reader.GetString(reader.GetOrdinal("PPE"));
                            else
                                task.PPE = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("Tools")))
                                task.Tools = reader.GetString(reader.GetOrdinal("Tools"));
                            else
                                task.Tools = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("Lubricant")))
                                task.Lubricant = reader.GetString(reader.GetOrdinal("Lubricant"));
                            else
                                task.Lubricant = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("QFactorType")))
                                task.QFactorType = reader.GetString(reader.GetOrdinal("QFactorType"));
                            else
                                task.QFactorType = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("PrimaryQFactor")))
                                task.PrimaryQFactor = reader.GetString(reader.GetOrdinal("PrimaryQFactor"));
                            else
                                task.PrimaryQFactor = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("NbrPeople")))
                                task.NbrPeople = reader.GetString(reader.GetOrdinal("NbrPeople"));
                            else
                                task.NbrPeople = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("NbrItems")))
                                task.NbrItems = reader.GetString(reader.GetOrdinal("NbrItems"));
                            else
                                task.NbrItems = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("HSEFlag")))
                            {
                                string aux = reader.GetString(reader.GetOrdinal("HSEFlag"));
                                if (aux == "1" || aux.ToLower() == "true")
                                    task.IsHSE = true;
                                else
                                    task.IsHSE = false;
                            }

                            else
                                task.IsHSE = false;

                            if (!reader.IsDBNull(reader.GetOrdinal("IsDefectLocked")))
                                task.IsDefectLooked = reader.GetBoolean(reader.GetOrdinal("IsDefectLocked"));

                            if (!reader.IsDBNull(reader.GetOrdinal("L_Reject")))
                                task.L_Reject = reader.GetString(reader.GetOrdinal("L_Reject"));
                            else
                                task.L_Reject = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("Target")))
                                task.Target = reader.GetString(reader.GetOrdinal("Target"));
                            else
                                task.Target = string.Empty;

                            if (!reader.IsDBNull(reader.GetOrdinal("U_Reject")))
                                task.U_Reject = reader.GetString(reader.GetOrdinal("U_Reject"));
                            else
                                task.U_Reject = string.Empty;
                            result.Add(task);
                        }
                        reader.Close();
                    }

                    conn.Close();
                }
            }

            return result;
        }

        public Task GetTask(string _connectionString, Int64 testId)
        {
            Task task = new Task();
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetTask", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@TestId", testId));

                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {

                        if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitId")))
                            task.SlaveUnitId = reader.GetInt32(reader.GetOrdinal("SlaveUnitId"));
                        else
                            task.SlaveUnitId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("TestId")))
                            task.TestId = reader.GetInt64(reader.GetOrdinal("TestId"));
                        else
                            task.TestId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("NbrDefects")))
                            task.NbrDefects = reader.GetInt32(reader.GetOrdinal("NbrDefects"));
                        else
                            task.NbrDefects = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                            task.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));
                        else
                            task.VarId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitDesc")))
                            task.SlaveUnitDesc = reader.GetString(reader.GetOrdinal("SlaveUnitDesc"));
                        else
                            task.SlaveUnitDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitDesc")))
                            task.MasterUnitDesc = reader.GetString(reader.GetOrdinal("MasterUnitDesc"));
                        else
                            task.MasterUnitDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("TaskId")))
                            task.TaskId = reader.GetString(reader.GetOrdinal("TaskId"));
                        else
                            task.TaskId = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("VarDesc")))
                            task.VarDesc = reader.GetString(reader.GetOrdinal("VarDesc"));
                        else
                            task.VarDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("TaskFreq")))
                            task.TaskFreq = reader.GetString(reader.GetOrdinal("TaskFreq"));
                        else
                            task.TaskFreq = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("TaskType")))
                            task.TaskType = reader.GetString(reader.GetOrdinal("TaskType"));
                        else
                            task.TaskType = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("CurrentResult")))
                            task.CurrentResult = reader.GetString(reader.GetOrdinal("CurrentResult"));
                        else
                            task.CurrentResult = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("CommentId")))
                            task.CommentId = reader.GetInt32(reader.GetOrdinal("CommentId"));
                        else
                            task.CommentId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("CommentInfo")))
                            task.CommentInfo = reader.GetString(reader.GetOrdinal("CommentInfo"));
                        else
                            task.CommentInfo = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("LineDesc")))
                            task.LineDesc = reader.GetString(reader.GetOrdinal("LineDesc"));
                        else
                            task.LineDesc = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("UserNameTest")))
                            task.UserNameTest = reader.GetString(reader.GetOrdinal("UserNameTest"));
                        else
                            task.UserNameTest = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Duration")))
                            task.Duration = reader.GetString(reader.GetOrdinal("Duration"));
                        else
                            task.Duration = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("LongTaskName")))
                            task.LongTaskName = reader.GetString(reader.GetOrdinal("LongTaskName"));
                        else
                            task.LongTaskName = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("ExternalLink")))
                            task.ExternalLink = reader.GetString(reader.GetOrdinal("ExternalLink"));
                        else
                            task.ExternalLink = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("DisplayLink")))
                            task.DisplayLink = reader.GetString(reader.GetOrdinal("DisplayLink"));
                        else
                            task.DisplayLink = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                            task.FL1 = reader.GetString(reader.GetOrdinal("FL1"));
                        else
                            task.FL1 = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                            task.FL2 = reader.GetString(reader.GetOrdinal("FL2"));
                        else
                            task.FL2 = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                            task.FL3 = reader.GetString(reader.GetOrdinal("FL3"));
                        else
                            task.FL3 = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                            task.FL4 = reader.GetString(reader.GetOrdinal("FL4"));
                        else
                            task.FL4 = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("PL_Id")))
                            task.PLId = reader.GetInt32(reader.GetOrdinal("PL_Id"));
                        else
                            task.PLId = -1;

                        if (!reader.IsDBNull(reader.GetOrdinal("FixedFreq")))
                        {
                            string tempFixedFrequency = reader.GetString(reader.GetOrdinal("FixedFreq"));
                            switch (tempFixedFrequency)
                            {
                                case "0":
                                    task.Fixed = "0";
                                    task.AutoPostpone = false;
                                    break;
                                case "1":
                                    task.Fixed = "1";
                                    task.AutoPostpone = false;
                                    break;
                                case "2":
                                    task.Fixed = "0";
                                    task.AutoPostpone = true;
                                    break;
                            }
                            //task.Fixed1 = reader.GetString(reader.GetOrdinal("FixedFreq"));
                        }

                        else
                        {
                            task.Fixed = string.Empty;
                            task.AutoPostpone = false;
                        }


                        if (!reader.IsDBNull(reader.GetOrdinal("ScheduleTime")))
                            task.ScheduleTime = reader.GetString(reader.GetOrdinal("ScheduleTime"));
                        else
                            task.ScheduleTime = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("LateTime")))
                            task.LateTime = reader.GetString(reader.GetOrdinal("LateTime"));
                        else
                            task.LateTime = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("DueTime")))
                            task.DueTime = reader.GetString(reader.GetOrdinal("DueTime"));
                        else
                            task.DueTime = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("TaskAction")))
                            task.TaskAction = reader.GetString(reader.GetOrdinal("TaskAction"));
                        else
                            task.TaskAction = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Criteria")))
                            task.Criteria = reader.GetString(reader.GetOrdinal("Criteria"));
                        else
                            task.Criteria = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Hazards")))
                            task.Hazards = reader.GetString(reader.GetOrdinal("Hazards"));
                        else
                            task.Hazards = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Method")))
                            task.Method = reader.GetString(reader.GetOrdinal("Method"));
                        else
                            task.Method = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("PPE")))
                            task.PPE = reader.GetString(reader.GetOrdinal("PPE"));
                        else
                            task.PPE = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Tools")))
                            task.Tools = reader.GetString(reader.GetOrdinal("Tools"));
                        else
                            task.Tools = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("Lubricant")))
                            task.Lubricant = reader.GetString(reader.GetOrdinal("Lubricant"));
                        else
                            task.Lubricant = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("QFactorType")))
                            task.QFactorType = reader.GetString(reader.GetOrdinal("QFactorType"));
                        else
                            task.QFactorType = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("PrimaryQFactor")))
                            task.PrimaryQFactor = reader.GetString(reader.GetOrdinal("PrimaryQFactor"));
                        else
                            task.PrimaryQFactor = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("NbrPeople")))
                            task.NbrPeople = reader.GetString(reader.GetOrdinal("NbrPeople"));
                        else
                            task.NbrPeople = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("NbrItems")))
                            task.NbrItems = reader.GetString(reader.GetOrdinal("NbrItems"));
                        else
                            task.NbrItems = string.Empty;

                        if (!reader.IsDBNull(reader.GetOrdinal("HSEFlag")))
                        {
                            string aux = reader.GetString(reader.GetOrdinal("HSEFlag"));
                            if (aux == "1" || aux.ToLower() == "true")
                                task.IsHSE = true;
                            else
                                task.IsHSE = false;
                        }
                        else
                            task.IsHSE = false;
                        try
                        {
                            if (!reader.IsDBNull(reader.GetOrdinal("IsDefectLocked")))
                                task.IsDefectLooked = Convert.ToBoolean(reader.GetInt32(reader.GetOrdinal("IsDefectLocked")));
                        }
                        catch
                        {
                            task.IsDefectLooked = false;
                        }


                    }
                    reader.Close();
                }
                conn.Close();
            }
            return task;

        }

        public string SaveTasks(string _connectionString, List<Task> tasks, int userId, string errorMSG)
        {

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                //is empty
                if (tasks.Count < 1)
                {
                    throw new Exception("There are no tasks edited");
                }

                conn.Open();
                foreach (var task in tasks)
                {
                    //if (task.IsDirty1 && task.Commit1)
                    if (task.EventSubtypeDesc.ToUpper() == "ECIL")
                    {
                        SqlCommand cmd = new SqlCommand("spLocal_eCIL_SaveTask", conn);
                        cmd.CommandType = CommandType.StoredProcedure;

                        //declare input parameters
                        SqlParameter Param_TestId = new SqlParameter("@TestId", SqlDbType.BigInt);
                        Param_TestId.Direction = ParameterDirection.Input;
                        Param_TestId.Value = Convert.ToInt64(task.testId);
                        cmd.Parameters.Add(Param_TestId);

                        SqlParameter Param_CurrentDueTime = new SqlParameter("@CurrentDueTime", SqlDbType.DateTime);
                        Param_CurrentDueTime.Direction = ParameterDirection.Input;
                        Param_CurrentDueTime.Value = task.ScheduleTime;
                        cmd.Parameters.Add(Param_CurrentDueTime);

                        SqlParameter Param_CurrentResult = new SqlParameter("@CurrentResult", SqlDbType.NVarChar, 50);
                        Param_CurrentResult.Direction = ParameterDirection.Input;
                        Param_CurrentResult.Value = task.currentResult;
                        cmd.Parameters.Add(Param_CurrentResult);

                        SqlParameter Param_UserId = new SqlParameter("@UserId", SqlDbType.Int);
                        Param_UserId.Direction = ParameterDirection.Input;
                        Param_UserId.Value = userId;
                        cmd.Parameters.Add(Param_UserId);

                        SqlParameter Param_CommentText = new SqlParameter("@CommentText", SqlDbType.NVarChar, 500);
                        Param_CommentText.Direction = ParameterDirection.Input;
                        Param_CommentText.Value = task.commentInfo;
                        cmd.Parameters.Add(Param_CommentText);

                        SqlParameter Param_IsInShift = new SqlParameter("@IsInShift", SqlDbType.Bit);
                        // Param_IsInShift.Direction = ParameterDirection.Input;
                        //Param_IsInShift.Value = task.IsInShift;
                        Param_IsInShift.Direction = ParameterDirection.Output;
                        Param_IsInShift.Value = null;
                        cmd.Parameters.Add(Param_IsInShift);

                        SqlParameter Param_ErrorMessage = new SqlParameter("@ErrorMessage", SqlDbType.NVarChar, 1000);
                        Param_ErrorMessage.Direction = ParameterDirection.Output;
                        Param_ErrorMessage.Value = String.Empty;
                        cmd.Parameters.Add(Param_ErrorMessage);

                        cmd.ExecuteNonQuery();

                        //if (Param_ErrorMessage.Value != DBNull.Value)
                        //{
                        //    return Param_ErrorMessage.Value.ToString();
                        //}
                        if (errorMSG != string.Empty)
                        {
                            return errorMSG;
                        }
                    }
                }
                conn.Close();
                conn.Dispose();
                return "OK";
            }

        }

        public Dictionary<int, string> GetUserTaskResultPrompts(string _connectionString, int LanguageId)
        {
            Dictionary<int, string> UserResultPrompts = new Dictionary<int, string>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetResultPrompts", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@LanguageId", LanguageId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        int TempPromptPosition = -1;
                        string TempUserPrompt = "";

                        if (!reader.IsDBNull(reader.GetOrdinal("PromptPosition")))
                            TempPromptPosition = reader.GetInt32(reader.GetOrdinal("PromptPosition"));
                        if (!reader.IsDBNull(reader.GetOrdinal("UserPrompt")))
                            TempUserPrompt = reader.GetString(reader.GetOrdinal("UserPrompt"));
                        if (TempPromptPosition != -1 && TempUserPrompt != "")
                            UserResultPrompts.Add(TempPromptPosition, TempUserPrompt);

                    }
                }
                conn.Close();
            }
            return UserResultPrompts;

        }

        public List<ServerTaskResultPrompts> GetServerTaskResultPrompts(string _connectionString)
        {
            var result = new List<ServerTaskResultPrompts>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetResultPrompts", conn);
                command.CommandType = CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        result.Add(new ServerTaskResultPrompts(reader.GetInt32(0), reader.GetString(1), reader.GetString(2)));
                    }
                    reader.Close();
                }
            }
            return result;

        }



        #endregion


        #region TasksMgmt Methods
        //Get the Plant Model for the lines received as parameter
        public List<LineTasksForPlantModel> GetLineTasksForPlantModel(string _connectionString, string LineIds)
        {
            List<LineTasksForPlantModel> result = new List<LineTasksForPlantModel>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetLineTasksForPlantModel", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@LineIds", LineIds));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        LineTasksForPlantModel temp = new LineTasksForPlantModel();

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
                        if (!reader.IsDBNull(reader.GetOrdinal("TaskOrder")))
                            temp.TaskOrder = reader.GetInt32(reader.GetOrdinal("TaskOrder"));
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
                conn.Close();
            }
            return result;

        }

        //Get the PPA Version and if the site is Aspected
        public bool GetPPAVersionAspected(string _connectionString)
        {
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                SqlParameter Param_PPA6AboveAspected = new SqlParameter("@PPA6AboveAspected", SqlDbType.Int);
                Param_PPA6AboveAspected.Direction = ParameterDirection.Output;
                Param_PPA6AboveAspected.Value = DBNull.Value;

                SqlCommand command = new SqlCommand("spLocal_eCIL_CheckPPAVersionAspected", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(Param_PPA6AboveAspected);
                command.ExecuteNonQuery();

                conn.Close();

                if (Param_PPA6AboveAspected.Value != DBNull.Value)
                    return Convert.ToBoolean(Param_PPA6AboveAspected.Value);

                return false;
            }
        }


        #endregion

    }

    public class TaskEdit : Task
    {
        #region Variables
        private string departmentDesc;
        private int departmentId;
        private string productionGroupDesc;
        private int productionGroupId;
        private string documentLinkPath;
        private string documentLinkTitle;
        private string scheduleScope;
        private string startDate;
        private string lineVersion;
        private string moduleFeatureVersion;
        private string testTime;
        private string vmId;
        private string taskLocation;
        private string keyId;
        private int shiftOffset;
        private bool active;
        private bool isChangedActive;
        private bool fixedFrequency;
        private bool isChangedFixedFrequency;
        private bool isChangedAutopostponed;
        private string frequency;
        private string frequencyType;
        private string window;
        private string status;
        private bool hseFlag;
        private string success;
        private int vmLocalId;
        private bool isChangedShiftOffset;
        private string keyFlag;
        #endregion;

        #region Properties
        public string ProductionGroupDesc { get => productionGroupDesc; set => productionGroupDesc = value; }
        public int ProductionGroupId { get => productionGroupId; set => productionGroupId = value; }
        public string DocumentLinkPath { get => documentLinkPath; set => documentLinkPath = value; }
        public string DocumentLinkTitle { get => documentLinkTitle; set => documentLinkTitle = value; }
        public string ScheduleScope { get => scheduleScope; set => scheduleScope = value; }
        public string StartDate { get => startDate; set => startDate = value; }
        public string LineVersion { get => lineVersion; set => lineVersion = value; }
        public string ModuleFeatureVersion { get => moduleFeatureVersion; set => moduleFeatureVersion = value; }
        public string TestTime { get => testTime; set => testTime = value; }
        public string VMId { get => vmId; set => vmId = value; }
        public string TaskLocation { get => taskLocation; set => taskLocation = value; }
        public string DepartmentDesc { get => departmentDesc; set => departmentDesc = value; }
        public int DepartmentId { get => departmentId; set => departmentId = value; }
        public string KeyId { get => keyId; set => keyId = value; }
        public bool FixedFrequency { get => fixedFrequency; set => fixedFrequency = value; }
        public bool IsChangedFixedFrequency { get => isChangedFixedFrequency; set => isChangedFixedFrequency = value; }
        public int ShiftOffset { get => shiftOffset; set => shiftOffset = value; }
        public bool Active { get => active; set => active = value; }
        public bool IsFixedFrequency { get => isChangedFixedFrequency; set => isChangedFixedFrequency = value; }
        public string Frequency { get => frequency; set => frequency = value; }
        public string FrequencyType { get => frequencyType; set => frequencyType = value; }
        public string Window { get => window; set => window = value; }
        public string Status { get => status; set => status = value; }
        public bool IsChangedActive { get => isChangedActive; set => isChangedActive = value; }
        public bool HseFlag { get => hseFlag; set => hseFlag = value; }
        public bool IsChangedAutopostponed { get => isChangedAutopostponed; set => isChangedAutopostponed = value; }
        public string succes_failure { get => success; set => success = value; }
        public int VMLocalId { get => vmLocalId; set => vmLocalId = value; }
        public bool IsChangedShiftOffset { get => isChangedShiftOffset; set => isChangedShiftOffset = value; }
        public string KeyFlag{ get => keyFlag; set => keyFlag = value; }
        #endregion

        #region Constructor
        public TaskEdit()
        {
            ProductionGroupDesc = string.Empty;
            ProductionGroupId = 0;
            DocumentLinkPath = string.Empty;
            DocumentLinkTitle = string.Empty;
            ScheduleScope = string.Empty;
            StartDate = string.Empty;
            LineVersion = string.Empty;
            ModuleFeatureVersion = string.Empty;
            TestTime = string.Empty;
            VMId = string.Empty;
            FixedFrequency = false;
            IsChangedFixedFrequency = false;
            ShiftOffset = 0;
            Active = false;
            IsFixedFrequency = false;
            Frequency = string.Empty;
            FrequencyType = string.Empty;
            Window = string.Empty;
            Status = string.Empty;
            TaskLocation = string.Empty;
            HseFlag = false;
            IsChangedAutopostponed = false;
            KeyFlag = string.Empty;
            succes_failure = string.Empty;
        }
        #endregion

        #region Methods
        public List<TaskEdit> GetTasksPlantModelEditList(string _connectionString, string DepartmentIds, string LineIds = null, string MasterIds = null, string SlaveIds = null, string GroupIds = null, string VariableIds = null)
        {
            List<TaskEdit> result = new List<TaskEdit>();
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_TasksManagement", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@DeptsList", DepartmentIds));
                command.Parameters.Add(new SqlParameter("@LinesList", LineIds));
                command.Parameters.Add(new SqlParameter("@MastersList", MasterIds));
                command.Parameters.Add(new SqlParameter("@SlavesList", SlaveIds));
                command.Parameters.Add(new SqlParameter("@GroupsList", GroupIds));
                command.Parameters.Add(new SqlParameter("@VarsList", VariableIds));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var temp = ConvertReaderToTaskEdit(reader);

                        result.Add(temp);
                    }
                    reader.Close();
                }
                conn.Close();
            }
            return result;

        }

        public List<TaskEdit> GetTasksByFlList(string _connectionString, string FlList, string VarList = "")
        {
            List<TaskEdit> result = new List<TaskEdit>();
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetTasksFromFL", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@FlList", FlList));
                command.Parameters.Add(new SqlParameter("@VarList", VarList));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var temp = ConvertReaderToTaskEdit(reader);
                        result.Add(temp);
                    }
                    reader.Close();
                }
                conn.Close();
            }
            return result;
        }
        #endregion

        public TaskEdit ConvertReaderToTaskEdit(SqlDataReader reader)
        {
            TaskEdit temp = new TaskEdit();

            if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                temp.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));
            if (!reader.IsDBNull(reader.GetOrdinal("TaskDesc")))
                temp.VarDesc = reader.GetString(reader.GetOrdinal("TaskDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("DepartmentDesc")))
                temp.DepartmentDesc = reader.GetString(reader.GetOrdinal("DepartmentDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("DepartmentId")))
                temp.DepartmentId = reader.GetInt32(reader.GetOrdinal("DepartmentId"));
            if (!reader.IsDBNull(reader.GetOrdinal("LineDesc")))
                temp.LineDesc = reader.GetString(reader.GetOrdinal("LineDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("LineId")))
                temp.PLId = reader.GetInt32(reader.GetOrdinal("LineId"));
            if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitDesc")))
                temp.MasterUnitDesc = reader.GetString(reader.GetOrdinal("MasterUnitDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitId")))
                temp.MasterUnitId = reader.GetInt32(reader.GetOrdinal("MasterUnitId"));
            if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitDesc")))
                temp.SlaveUnitDesc = reader.GetString(reader.GetOrdinal("SlaveUnitDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitId")))
                temp.SlaveUnitId = reader.GetInt32(reader.GetOrdinal("SlaveUnitId"));
            if (!reader.IsDBNull(reader.GetOrdinal("ProductionGroupDesc")))
                temp.productionGroupDesc = reader.GetString(reader.GetOrdinal("ProductionGroupDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("ProductionGroupId")))
                temp.productionGroupId = reader.GetInt32(reader.GetOrdinal("ProductionGroupId"));
            if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                temp.FL1 = reader.GetString(reader.GetOrdinal("FL1"));
            if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                temp.FL2 = reader.GetString(reader.GetOrdinal("FL2"));
            if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                temp.FL3 = reader.GetString(reader.GetOrdinal("FL3"));
            if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                temp.FL4 = reader.GetString(reader.GetOrdinal("FL4"));
            if (!reader.IsDBNull(reader.GetOrdinal("LongTaskName")))
                temp.LongTaskName = reader.GetString(reader.GetOrdinal("LongTaskName"));
            if (!reader.IsDBNull(reader.GetOrdinal("TaskId")))
                temp.TaskId = reader.GetString(reader.GetOrdinal("TaskId"));
            if (!reader.IsDBNull(reader.GetOrdinal("TaskAction")))
                temp.TaskAction = reader.GetString(reader.GetOrdinal("TaskAction"));
            if (!reader.IsDBNull(reader.GetOrdinal("KeyId")))
                temp.KeyId = reader.GetString(reader.GetOrdinal("KeyId"));
            if (!reader.IsDBNull(reader.GetOrdinal("TaskType")))
                temp.TaskType = reader.GetString(reader.GetOrdinal("TaskType"));
            if (!reader.IsDBNull(reader.GetOrdinal("NbrItems")))
                temp.NbrItems = reader.GetString(reader.GetOrdinal("NbrItems"));
            if (!reader.IsDBNull(reader.GetOrdinal("Duration")))
                temp.Duration = reader.GetString(reader.GetOrdinal("Duration"));
            if (!reader.IsDBNull(reader.GetOrdinal("NbrPeople")))
                temp.NbrPeople = reader.GetString(reader.GetOrdinal("NbrPeople"));
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
            if (!reader.IsDBNull(reader.GetOrdinal("DocumentLinkPath")))
                temp.documentLinkPath = reader.GetString(reader.GetOrdinal("DocumentLinkPath"));
            if (!reader.IsDBNull(reader.GetOrdinal("DocumentLinkTitle")))
                temp.documentLinkTitle = reader.GetString(reader.GetOrdinal("DocumentLinkTitle"));
            if (!reader.IsDBNull(reader.GetOrdinal("QFactorType")))
                temp.QFactorType = reader.GetString(reader.GetOrdinal("QFactorType"));
            if (!reader.IsDBNull(reader.GetOrdinal("PrimaryQFactor")))
                temp.PrimaryQFactor = reader.GetString(reader.GetOrdinal("PrimaryQFactor"));

            //read fixedfrequency and auo postponed values
            if (!reader.IsDBNull(reader.GetOrdinal("FixedFrequency")))
            {
                string tempFixedFrequency = reader.GetString(reader.GetOrdinal("FixedFrequency"));
                switch (tempFixedFrequency)
                {
                    case "0":
                        temp.FixedFrequency = false;
                        temp.AutoPostpone = false;
                        break;
                    case "1":
                        temp.FixedFrequency = true;
                        temp.AutoPostpone = false;
                        break;
                    case "2":
                        temp.FixedFrequency = false;
                        temp.AutoPostpone = true;
                        break;
                }
                //temp.FixedFrequency = reader.GetString(reader.GetOrdinal("FixedFrequency")) == "1" ? true : false;
            }

            if (!reader.IsDBNull(reader.GetOrdinal("TaskFrequency")))
            {
                string frequency = reader.GetString(reader.GetOrdinal("TaskFrequency"));
                temp.TaskFreq = frequency;
                temp.Active = frequency.Substring(0, 1) == "1" ? true : false;
                try
                {
                    int tempFreq = Convert.ToInt32(frequency.Substring(1, 3));
                    if (tempFreq == 0)
                    {
                        temp.Frequency = null;
                        temp.FrequencyType = "Shiftly";
                    }
                    else if (tempFreq == 1)
                    {
                        temp.Frequency = "1";
                        temp.FrequencyType = "Daily";
                    }
                    else if (tempFreq >= 2 && tempFreq <= 365)
                    {
                        temp.Frequency = tempFreq.ToString();
                        temp.FrequencyType = "Multi-Day";
                    }
                    else if (tempFreq >= 366 && tempFreq <= 999)
                    {
                        temp.Frequency = (tempFreq - 365).ToString();
                        temp.FrequencyType = "Minutes";
                    }

                    temp.Window = Convert.ToInt32(frequency.Substring(4, 3)).ToString();

                }
                catch
                {
                    temp.Frequency = null;
                    temp.FrequencyType = "";
                    temp.Window = "0";
                }
            }
            if (!reader.IsDBNull(reader.GetOrdinal("ScheduleScope")))
                temp.scheduleScope = reader.GetString(reader.GetOrdinal("ScheduleScope"));
            if (!reader.IsDBNull(reader.GetOrdinal("StartDate")))
                temp.startDate = reader.GetString(reader.GetOrdinal("StartDate"));
            if (!reader.IsDBNull(reader.GetOrdinal("LineVersion")))
                temp.lineVersion = reader.GetString(reader.GetOrdinal("LineVersion"));
            if (!reader.IsDBNull(reader.GetOrdinal("ModuleFeatureVersion")))
                temp.moduleFeatureVersion = reader.GetString(reader.GetOrdinal("ModuleFeatureVersion"));
            if (!reader.IsDBNull(reader.GetOrdinal("TestTime")))
                temp.testTime = reader.GetString(reader.GetOrdinal("TestTime"));
            if (!reader.IsDBNull(reader.GetOrdinal("VMId")))
                temp.vmId = reader.GetString(reader.GetOrdinal("VMId"));
            if (!reader.IsDBNull(reader.GetOrdinal("TaskLocation")))
                temp.taskLocation = reader.GetString(reader.GetOrdinal("TaskLocation"));
            if (!reader.IsDBNull(reader.GetOrdinal("HSEFlag")))
            {
                string aux = reader.GetString(reader.GetOrdinal("HSEFlag"));
                if (aux == "1" || aux.ToLower() == "true")
                    temp.IsHSE = true;
                else
                    temp.IsHSE = false;
            }

            if (!reader.IsDBNull(reader.GetOrdinal("ShiftOffset")))
            {
                int aux = 0;
                Int32.TryParse(reader.GetString(reader.GetOrdinal("ShiftOffset")), out aux);
                temp.ShiftOffset = aux;
            }

            return temp;
        }


        public List<TaskEdit> SaveMgmtTasks(string _connectionString, List<TaskEdit> tasks, int userId)
        {
            var resulttasks = new List<TaskEdit>();
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                if (tasks.Count > 0)
                {
                    foreach (var task in tasks)
                    {
                        if (task.Status == "Add")
                            resulttasks.Add(AddTask(_connectionString, task, userId));
                        if (task.Status == "Modify")
                            resulttasks.Add(UpdateTask(_connectionString, task, userId));
                        if (task.Status == "Obsolete")
                            resulttasks.Add(DeleteTask(_connectionString, task, userId));
                    }
                }
            }

            return resulttasks;
        }

        //Update the return type for this in front end	
        //public string SaveMgmtTasks(string _connectionString, List<TaskEdit> tasks, int userId)	
        //{	
        //    string message = null;	
        //    using (SqlConnection conn = new SqlConnection(_connectionString))	
        //    {	
        //        if (tasks.Count > 0)	
        //        {	
        //            foreach (var task in tasks)	
        //            {	
        //                if (task.Status == "Add")	
        //                {	
        //                    message = VerifySchedulingInfo(task);	
        //                    if (string.IsNullOrEmpty(message))	
        //                    {	
        //                        message = AddTask(_connectionString, task, userId);	
        //                    }	
        //                    else	
        //                        return message;	
        //                }	
        //                if (task.Status == "Modify")	
        //                {	
        //                    message = VerifySchedulingInfo(task);	
        //                    if (string.IsNullOrEmpty(message))	
        //                    {	
        //                        message = UpdateTask(_connectionString, task, userId);	
        //                    }	
        //                    else	
        //                        return message;	
        //                }	
        //                if (task.Status == "Obsolete")	
        //                {	
        //                    DeleteTask(_connectionString, task, userId);	
        //                    message = "Success";	
        //                }	
        //            }	
        //        }	
        //    }	
        //    return message;	
        //}

        public string VerifySchedulingInfo(TaskEdit myTask)
        {
            bool FrequencyExists;
            //bool WindowExsists;
            string errormessage = null;
            var utility = new Utilities();
            FrequencyExists = false;
            errormessage = utility.VerifyFrequency(Convert.ToInt32(myTask.Frequency));
            if (!(string.IsNullOrEmpty(errormessage)))
            {
                return errormessage;
            }
            else
            {
                errormessage = utility.VerifyFrequencyRange(Convert.ToInt32(myTask.Frequency), FrequencyType);
                if (!(string.IsNullOrEmpty(errormessage)))
                {
                    return errormessage;
                }
                else
                    FrequencyExists = true;
            }
            //WindowExsists = false;
            errormessage = utility.VerifyWindow(Convert.ToInt32(myTask.Window));
            if (!(string.IsNullOrEmpty(errormessage)))
            {
                return errormessage;
            }
            else if (FrequencyExists == true)
            {
                errormessage = utility.VerifyWindowRange(Convert.ToInt32(myTask.Window), Convert.ToInt32(myTask.Frequency), myTask.FrequencyType);
                if (!(string.IsNullOrEmpty(errormessage)))
                {
                    return errormessage;
                }
                //else
                //    WindowExsists = true;
            }
            errormessage = utility.VerifyShiftOffset(myTask.ShiftOffset);
            if (!(string.IsNullOrEmpty(errormessage)))
            {
                return errormessage;
            }
            else if (FrequencyExists == true && myTask.FrequencyType == "Minutes")
            {
                errormessage = utility.VerifyShiftOffsetRange(myTask.ShiftOffset, Convert.ToInt32(myTask.Frequency));
                if (!(string.IsNullOrEmpty(errormessage)))
                {
                    return errormessage;
                }
            }

            errormessage = utility.VerifyTestTime(myTask.TestTime, myTask.FrequencyType);
            if (!(string.IsNullOrEmpty(errormessage)))
            {
                return errormessage;
            }

            return errormessage;
        }

        public TaskEdit AddTask(string _connectionString, TaskEdit myTask, int userId)
        {
            //string message;
            var resultTask = new TaskEdit();
            resultTask.VarDesc = myTask.VarDesc;
            resultTask.VMLocalId = myTask.VMLocalId;

            // check if VarDesc has more than 50 characters
            if (myTask.VarDesc.Length > 50)
            {
                //return "The Task Description needs to have less than 50 characters";
                resultTask.succes_failure = "The Task Description needs to have less than 50 characters";
                return resultTask;
            }

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                SqlParameter Param_VarId = new SqlParameter("@VarID", SqlDbType.Int);
                Param_VarId.Direction = ParameterDirection.Output;
                Param_VarId.Value = String.Empty;

                SqlParameter Param_ErrorMessage = new SqlParameter("@ErrorMessage", SqlDbType.VarChar, 1000);
                Param_ErrorMessage.Direction = ParameterDirection.Output;
                Param_ErrorMessage.Value = String.Empty;

                try
                {
                    command.CommandText = "spLocal_eCIL_CreateVariable";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(Param_VarId);
                    command.Parameters.Add(Param_ErrorMessage);
                    command.Parameters.Add(new SqlParameter("@UserID", userId));
                    command.Parameters.Add(new SqlParameter("@DepartmentDesc", myTask.departmentDesc));
                    command.Parameters.Add(new SqlParameter("@ProdLineDesc", myTask.LineDesc));
                    command.Parameters.Add(new SqlParameter("@MasterUnitDesc", myTask.MasterUnitDesc));
                    command.Parameters.Add(new SqlParameter("@SlaveUnitDesc", myTask.SlaveUnitDesc));
                    command.Parameters.Add(new SqlParameter("@ProdGroupDesc", myTask.productionGroupDesc));
                    command.Parameters.Add(new SqlParameter("@VarDesc", myTask.VarDesc));
                    command.Parameters.Add(new SqlParameter("@FL3", myTask.FL3 ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@FL4", myTask.FL4 ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@DocumentLinkPath", myTask.documentLinkPath ?? (object)DBNull.Value));
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
                   // string message = Convert.ToString(Param_ErrorMessage.Value);
                   // throw new Exception(message != "" ? message : ex.Message);
                    throw new Exception(ex.Message);
                }

                conn.Close();
                resultTask.Status = "Add";

                if (((DBNull.Value.Equals(Param_ErrorMessage.Value)) || (string.IsNullOrEmpty(Param_ErrorMessage.Value.ToString()))))
                {
                    // the create variable SP does not return varid 
                    //message = "Success";
                    resultTask.succes_failure = "Success";
                    resultTask.KeyFlag = myTask.keyFlag;
                    resultTask.VarId = (Convert.ToInt32(Param_VarId.Value));
                    myTask.VarId = (Convert.ToInt32(Param_VarId.Value));
                    RefreshUDPs(_connectionString, myTask, myTask.VarId, true);
                }
                else
                {
                    //message = Convert.ToString(Param_ErrorMessage.Value);
                    //throw new Exception(message);
                    resultTask.succes_failure = Convert.ToString(Param_ErrorMessage.Value);
                    resultTask.KeyFlag = myTask.keyFlag;

                }
            }

            return resultTask;

        }

        public TaskEdit DeleteTask(string _connectionString, TaskEdit myTask, int userId)
        {
            var resultTask = new TaskEdit();
            resultTask.VMLocalId = myTask.VMLocalId;

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                command.Connection = conn;
                command.Transaction = transaction;

                SqlParameter Param_ErrorMessage = new SqlParameter("@ErroMessage", SqlDbType.VarChar, 1000);
                Param_ErrorMessage.Direction = ParameterDirection.Output;
                Param_ErrorMessage.Value = String.Empty; //DBNull.Value;

                try
                {
                    command.CommandText = "spLocal_eCIL_ObsoleteVariable";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@VarID", myTask.VarId));
                    command.Parameters.Add(new SqlParameter("@UserID", userId));
                    command.Parameters.Add(Param_ErrorMessage);
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
                    //throw new Exception(Convert.ToString(Param_ErrorMessage.Value));
                    throw new Exception(ex.Message);
                }

                conn.Close();

                resultTask.VarId = myTask.VarId;
                resultTask.VarDesc = myTask.VarDesc;
                resultTask.status = "Obsolete";
                if (((DBNull.Value.Equals(Param_ErrorMessage.Value)) || (string.IsNullOrEmpty(Param_ErrorMessage.Value.ToString()))))
                {
                    // the create variable SP does not return varid 
                    //message = "Success";
                    resultTask.succes_failure = "Success";
                    resultTask.KeyFlag = myTask.keyFlag;
                }
                else
                {
                    //message = Convert.ToString(Param_ErrorMessage.Value);
                    //throw new Exception(message);
                    resultTask.succes_failure = Convert.ToString(Param_ErrorMessage.Value);
                    resultTask.KeyFlag = myTask.keyFlag;
                }
                //if (!(string.IsNullOrEmpty(Param_ErrorMessage.Value.ToString())))
                //{

                //    throw new Exception(Convert.ToString(Param_ErrorMessage.Value));
                //}

            }
            return resultTask;
        }

        public TaskEdit UpdateTask(string _connectionString, TaskEdit myTask, int userid)
        {
            //string message;
            var resultTask = new TaskEdit();
            resultTask.VMLocalId = myTask.VMLocalId;
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
                    command.CommandText = "spLocal_eCIL_UpdateVariable";
                    command.CommandType = CommandType.StoredProcedure;
                    command.Parameters.Add(Param_ErrorMessage);
                    command.Parameters.Add(new SqlParameter("@VarID", myTask.VarId));
                    command.Parameters.Add(new SqlParameter("@VarDesc", myTask.VarDesc));
                    command.Parameters.Add(new SqlParameter("@ProdLineDesc", myTask.LineDesc));
                    command.Parameters.Add(new SqlParameter("@SlaveUnitDesc", myTask.SlaveUnitDesc));
                    command.Parameters.Add(new SqlParameter("@ProdGroupDesc", myTask.productionGroupDesc));
                    command.Parameters.Add(new SqlParameter("@DocumentLinkPath", myTask.documentLinkPath ?? (object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@UserID", userid));
                    command.Parameters.Add(new SqlParameter("@FL3", myTask.FL3));
                    command.Parameters.Add(new SqlParameter("@FL4", myTask.FL4));
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
                    //message = Convert.ToString(Param_ErrorMessage.Value);
                    //throw new Exception(message != "" ? message : ex.Message);
                    throw new Exception(ex.Message);
                }

                conn.Close();

                resultTask.VarId = myTask.VarId;
                resultTask.VarDesc = myTask.VarDesc;
                resultTask.Status = "Modify";
                if (((DBNull.Value.Equals(Param_ErrorMessage.Value)) || (string.IsNullOrEmpty(Param_ErrorMessage.Value.ToString()))))
                {

                    RefreshUDPs(_connectionString, myTask, myTask.VarId, false);
                    resultTask.succes_failure = "Success";
                    resultTask.KeyFlag = myTask.keyFlag;
                    //message = "Success";
                    //Call the RefreshUDPS method
                }
                else
                {
                    //message = Convert.ToString(Param_ErrorMessage.Value);
                    //throw new Exception(message);
                    resultTask.succes_failure = Convert.ToString(Param_ErrorMessage.Value);
                    resultTask.KeyFlag = myTask.keyFlag;
                }
            }

            //return message;
            return resultTask;
        }

        public void RefreshUDPs(string _connectionString, TaskEdit myTask, int varId, bool newTask)
        {
            var tempTask = new List<TaskEdit>();
            var exceltask = new ExcelTask();
            string TaskFreqUDP = string.Empty;
            string fixedFrequency = string.Empty;
            string isHSE = string.Empty;
            string primaryQFactor = string.Empty;
            int frequency;

            if (newTask)
            {
                if (!string.IsNullOrEmpty(myTask.startDate))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, START_DATE, myTask.startDate);
                }

                if (!string.IsNullOrEmpty(myTask.LongTaskName))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, LONG_TASK_NAME, myTask.LongTaskName);
                }

                if (!string.IsNullOrEmpty(myTask.TaskId))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_ID, myTask.TaskId);
                }

                if (!string.IsNullOrEmpty(myTask.TaskAction))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_ACTION, myTask.TaskAction);
                }

                if (!string.IsNullOrEmpty(myTask.TaskType))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_TYPE, myTask.TaskType);
                }

                if (!string.IsNullOrEmpty(myTask.NbrItems))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, NBR_ITEMS, myTask.NbrItems);
                }

                if (!string.IsNullOrEmpty(myTask.Duration))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, DURATION, myTask.Duration);
                }

                if (!string.IsNullOrEmpty(myTask.NbrPeople))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, NBR_PEOPLE, myTask.NbrPeople);
                }

                if (!string.IsNullOrEmpty(myTask.Criteria))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, CRITERIA, myTask.Criteria);
                }

                if (!string.IsNullOrEmpty(myTask.Hazards))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, HAZARDS, myTask.Hazards);
                }

                if (!string.IsNullOrEmpty(myTask.Method))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, METHOD, myTask.Method);
                }

                if (!string.IsNullOrEmpty(myTask.PPE))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, PPECONST, myTask.PPE);
                }

                if (!string.IsNullOrEmpty(myTask.Tools))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TOOLS, myTask.Tools);
                }

                if (!string.IsNullOrEmpty(myTask.Lubricant))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, LUBRICANT, myTask.Lubricant);
                }

                if (!string.IsNullOrEmpty(myTask.DocumentLinkTitle))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, DOCUMENT_LINK_TITLE, myTask.documentLinkTitle);
                }

                if (!string.IsNullOrEmpty(myTask.QFactorType))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, Q_FACTOR_TYPE, myTask.QFactorType);
                }

                if (!string.IsNullOrEmpty(myTask.PrimaryQFactor))
                {
                    if (myTask.PrimaryQFactor == "true" || myTask.PrimaryQFactor == "Yes")
                    {
                        primaryQFactor = "Yes";
                    }
                    else
                    {
                        primaryQFactor = "No";
                    }
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, PRIMARY_Q_FACTOR, primaryQFactor);
                }

                //HSE will be true or false, no situation when HSE can be empty
                //if (!string.IsNullOrEmpty(myTask.IsHSE1))
                //{
                if (myTask.IsHSE == true || myTask.IsHSE.ToString() == "1")
                {
                    isHSE = "1";
                }
                else
                {
                    isHSE = "0";
                }
                CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, IS_HSE, isHSE);
                // }


                string TaskFrequencyUDP = exceltask.FindTaskFrequency(Convert.ToInt32(myTask.Active), Convert.ToInt32(myTask.Window), Convert.ToInt32(myTask.Frequency), myTask.FrequencyType);

                if (!string.IsNullOrEmpty(TaskFrequencyUDP))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_FREQUENCY, TaskFrequencyUDP);

                    if (myTask.FrequencyType.ToUpper() == "MINUTES")
                    {

                        if ((myTask.FixedFrequency == true || myTask.FixedFrequency.ToString() == "1"))
                        {
                            fixedFrequency = "1";
                        }
                        else
                            fixedFrequency = "0";

                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, FIXED_FREQUENCY, fixedFrequency);
                    }

                    //if it is multi day, we need to see Auto Postpone value
                    else if (myTask.FrequencyType.ToUpper() == "MULTI-DAY")
                    {
                        //if task frequency for the task is 1 or true(comming from the UI), the final Fixed Frequency will be 1
                        if ((myTask.FixedFrequency == true || myTask.FixedFrequency.ToString() == "1") && myTask.AutoPostpone == false)
                        {
                            fixedFrequency = "1";

                        }
                        else if ((myTask.FixedFrequency == false || myTask.FixedFrequency.ToString() == "0") && myTask.AutoPostpone == false)
                        {
                            fixedFrequency = "0";

                        }
                        else if ((myTask.FixedFrequency == false || myTask.FixedFrequency.ToString() == "0") && myTask.AutoPostpone == true)
                        {

                            fixedFrequency = "2";
                        }


                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, FIXED_FREQUENCY, fixedFrequency);
                    }

                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, SHIFT_OFFSET, myTask.shiftOffset.ToString());

                }

                //Task Frequency is Active+Freq+Window - Check is this appended string will be passed by the middle layer
                //CreateUpdateUDP(_connectionString, myTask.LineDesc1, myTask.SlaveUnitDesc1, myTask.VarDesc1, TASK_FREQUENCY, myTask.TaskFreq1);
                //CreateUpdateUDP(_connectionString, myTask.LineDesc1, myTask.SlaveUnitDesc1, myTask.VarDesc1, FIXED_FREQUENCY, myTask.FixedFrequency.ToString());
                //CreateUpdateUDP(_connectionString, myTask.LineDesc1, myTask.SlaveUnitDesc1, myTask.VarDesc1, SHIFT_OFFSET, myTask.ShiftOffset.ToString());

                if ((!string.IsNullOrEmpty(myTask.TestTime)) && ((myTask.FrequencyType.ToUpper() == "DAILY") || (myTask.FrequencyType.ToUpper() == "MULTI-DAY")))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TEST_TIME, myTask.TestTime);
                }

                if (!string.IsNullOrEmpty(myTask.VMId))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, VM_ID, myTask.VMId);
                }

                if (!string.IsNullOrEmpty(myTask.TaskLocation))
                {
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_LOCATION, myTask.taskLocation);
                }

            }

            else
            {
                tempTask = GetTasksPlantModelEditList(_connectionString, null, null, null, null, null, varId.ToString());

                if (myTask.StartDate != tempTask[0].StartDate)
                {
                    if ((string.IsNullOrEmpty(myTask.StartDate)) && (!(string.IsNullOrEmpty(tempTask[0].StartDate))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, START_DATE);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, START_DATE, myTask.StartDate);
                }


                if (myTask.LongTaskName != tempTask[0].LongTaskName)
                {
                    if ((string.IsNullOrEmpty(myTask.LongTaskName)) && (!(string.IsNullOrEmpty(tempTask[0].LongTaskName))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, LONG_TASK_NAME);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, LONG_TASK_NAME, myTask.LongTaskName);
                }

                if (myTask.TaskId != tempTask[0].TaskId)
                {
                    if ((string.IsNullOrEmpty(myTask.TaskId)) && (!(string.IsNullOrEmpty(tempTask[0].TaskId))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_ID);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_ID, myTask.TaskId);
                }

                if (myTask.TaskAction != tempTask[0].TaskAction)
                {
                    if ((string.IsNullOrEmpty(myTask.TaskAction)) && (!(string.IsNullOrEmpty(tempTask[0].TaskAction))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_ACTION);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_ACTION, myTask.TaskAction);
                }

                if (myTask.TaskType != tempTask[0].TaskType)
                {
                    if ((string.IsNullOrEmpty(myTask.TaskType)) && (!(string.IsNullOrEmpty(tempTask[0].TaskType))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_TYPE);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_TYPE, myTask.TaskType);
                }

                if (myTask.NbrItems != tempTask[0].NbrItems)
                {
                    if ((string.IsNullOrEmpty(myTask.NbrItems)) && (!(string.IsNullOrEmpty(tempTask[0].NbrItems))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, NBR_ITEMS);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, NBR_ITEMS, myTask.NbrItems);
                }

                if (myTask.Duration != tempTask[0].Duration)
                {
                    if ((string.IsNullOrEmpty(myTask.Duration)) && (!(string.IsNullOrEmpty(tempTask[0].Duration))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, DURATION);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, DURATION, myTask.Duration);
                }

                if (myTask.NbrPeople != tempTask[0].NbrPeople)
                {
                    if ((string.IsNullOrEmpty(myTask.NbrPeople)) && (!(string.IsNullOrEmpty(tempTask[0].NbrPeople))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, NBR_PEOPLE);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, NBR_PEOPLE, myTask.NbrPeople);
                }

                if (myTask.Criteria != tempTask[0].Criteria)
                {
                    if ((string.IsNullOrEmpty(myTask.Criteria)) && (!(string.IsNullOrEmpty(tempTask[0].Criteria))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, CRITERIA);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, CRITERIA, myTask.Criteria);
                }

                if (myTask.Hazards != tempTask[0].Hazards)
                {
                    if ((string.IsNullOrEmpty(myTask.Hazards)) && (!(string.IsNullOrEmpty(tempTask[0].Hazards))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, HAZARDS);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, HAZARDS, myTask.Hazards);
                }

                if (myTask.Method != tempTask[0].Method)
                {
                    if ((string.IsNullOrEmpty(myTask.Method)) && (!(string.IsNullOrEmpty(tempTask[0].Method))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, METHOD);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, METHOD, myTask.Method);
                }

                if (myTask.PPE != tempTask[0].PPE)
                {
                    if ((string.IsNullOrEmpty(myTask.PPE)) && (!(string.IsNullOrEmpty(tempTask[0].PPE))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, PPE);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, PPECONST, myTask.PPE);
                }

                if (myTask.Tools != tempTask[0].Tools)
                {
                    if ((string.IsNullOrEmpty(myTask.Tools)) && (!(string.IsNullOrEmpty(tempTask[0].Tools))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TOOLS);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TOOLS, myTask.Tools);
                }


                if (myTask.Lubricant != tempTask[0].Lubricant)
                {
                    if ((string.IsNullOrEmpty(myTask.Lubricant)) && (!(string.IsNullOrEmpty(tempTask[0].Lubricant))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, LUBRICANT);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, LUBRICANT, myTask.Lubricant);
                }


                if (myTask.DocumentLinkTitle != tempTask[0].DocumentLinkTitle)
                {
                    if ((string.IsNullOrEmpty(myTask.DocumentLinkTitle)) && (!(string.IsNullOrEmpty(tempTask[0].DocumentLinkTitle))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, DOCUMENT_LINK_TITLE);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, DOCUMENT_LINK_TITLE, myTask.DocumentLinkTitle);
                }


                if (myTask.QFactorType != tempTask[0].QFactorType)
                {
                    if ((string.IsNullOrEmpty(myTask.QFactorType)) && (!(string.IsNullOrEmpty(tempTask[0].QFactorType))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, Q_FACTOR_TYPE);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, Q_FACTOR_TYPE, myTask.QFactorType);
                }

                if (myTask.PrimaryQFactor != tempTask[0].PrimaryQFactor)
                {
                    if ((string.IsNullOrEmpty(myTask.PrimaryQFactor)) && (!(string.IsNullOrEmpty(tempTask[0].PrimaryQFactor))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, PRIMARY_Q_FACTOR);
                    else
                    {
                        if (myTask.PrimaryQFactor == "true" || myTask.PrimaryQFactor == "Yes")
                        {
                            primaryQFactor = "Yes";
                        }
                        else
                        {
                            primaryQFactor = "No";
                        }
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, PRIMARY_Q_FACTOR, primaryQFactor);
                    }
                }


                if (myTask.IsHSE != tempTask[0].IsHSE)
                {
                    if ((string.IsNullOrEmpty(myTask.IsHSE.ToString())) && (!(string.IsNullOrEmpty(tempTask[0].IsHSE.ToString()))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, IS_HSE);
                    else
                    {
                        if (myTask.IsHSE == true || myTask.IsHSE.ToString() == "1")
                        {
                            isHSE = "1";
                        }
                        else
                        {
                            isHSE = "0";
                        }
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, IS_HSE, isHSE);
                    }
                }

                if (string.IsNullOrEmpty(myTask.Frequency))
                {
                    frequency = 0;
                }
                else
                {
                    frequency = Convert.ToInt32(myTask.Frequency);
                }


                TaskFreqUDP = exceltask.FindTaskFrequency(Convert.ToInt32(myTask.Active), Convert.ToInt32(myTask.Window), frequency, myTask.FrequencyType);

                if ((!string.IsNullOrEmpty(TaskFreqUDP)) && (myTask.FrequencyType.ToUpper() == "MULTI-DAY"))
                {
                    //if task frequency for the task is 1 or true(comming from the UI), the final Fixed Frequency will be 1
                    if ((myTask.FixedFrequency == true || myTask.FixedFrequency.ToString() == "1") && myTask.AutoPostpone == false)
                    {
                        fixedFrequency = "1";
                    }
                    else if ((myTask.FixedFrequency == false || myTask.FixedFrequency.ToString() == "0") && myTask.AutoPostpone == false)
                    {
                        fixedFrequency = "0";
                    }
                    else if ((myTask.FixedFrequency == false || myTask.FixedFrequency.ToString() == "0") && myTask.AutoPostpone == true)
                    {
                        fixedFrequency = "2";
                    }
                    CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, FIXED_FREQUENCY, fixedFrequency);
                }

                if ((TaskFreqUDP != tempTask[0].TaskFreq) || (myTask.FixedFrequency != tempTask[0].FixedFrequency) || (myTask.shiftOffset != tempTask[0].shiftOffset))
                {
                    if ((TaskFreqUDP == null) && (tempTask[0].TaskFreq != null))
                    {
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_FREQUENCY);
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, FIXED_FREQUENCY);
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, SHIFT_OFFSET);
                    }
                    else
                    {
                        if (TaskFreqUDP != tempTask[0].TaskFreq)
                        {
                            CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_FREQUENCY, TaskFreqUDP);
                        }

                        if ((myTask.FrequencyType.ToUpper() == "SHIFTLY") || (myTask.FrequencyType.ToUpper() == "DAILY"))
                        {
                            DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, FIXED_FREQUENCY);
                        }

                        if (myTask.FrequencyType.ToUpper() == "MINUTES")
                        {
                            if (myTask.FixedFrequency == true || myTask.FixedFrequency.ToString() == "1")
                            {
                                fixedFrequency = "1";
                            }
                            else
                                fixedFrequency = "0";

                            CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, FIXED_FREQUENCY, fixedFrequency);
                        }

                        if (myTask.FrequencyType.ToUpper() == "MULTI-DAY")
                        {
                            //if task frequency for the task is 1 or true(comming from the UI), the final Fixed Frequency will be 1
                            if ((myTask.FixedFrequency == true || myTask.FixedFrequency.ToString() == "1") && myTask.AutoPostpone == false)
                            {
                                fixedFrequency = "1";
                            }
                            else if ((myTask.FixedFrequency == false || myTask.FixedFrequency.ToString() == "0") && myTask.AutoPostpone == false)
                            {
                                fixedFrequency = "0";
                            }
                            else if ((myTask.FixedFrequency == false || myTask.FixedFrequency.ToString() == "0") && myTask.AutoPostpone == true)
                            {
                                fixedFrequency = "2";
                            }
                            CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, FIXED_FREQUENCY, fixedFrequency);
                        }

                        if (myTask.shiftOffset != tempTask[0].shiftOffset)
                        {
                            CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, SHIFT_OFFSET, myTask.shiftOffset.ToString());
                        }
                    }
                }


                if (myTask.TestTime != tempTask[0].TestTime)
                {
                    if ((string.IsNullOrEmpty(myTask.TestTime)) && (!(string.IsNullOrEmpty(tempTask[0].TestTime))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TEST_TIME);
                    else
                    {
                        if ((myTask.FrequencyType.ToUpper() == "MULTI-DAY") || (myTask.FrequencyType.ToUpper() == "DAILY"))
                        {
                            CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TEST_TIME, myTask.TestTime);
                        }
                    }
                }



                if (myTask.VMId != tempTask[0].VMId)
                {
                    if ((string.IsNullOrEmpty(myTask.VMId)) && (!(string.IsNullOrEmpty(tempTask[0].VMId))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, VM_ID);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, VM_ID, myTask.VMId);
                }

                if (myTask.TaskLocation != tempTask[0].TaskLocation)
                {
                    if ((string.IsNullOrEmpty(myTask.TaskLocation)) && (!(string.IsNullOrEmpty(tempTask[0].TaskLocation))))
                        DeleteUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_LOCATION);
                    else
                        CreateUpdateUDP(_connectionString, myTask.LineDesc, myTask.SlaveUnitDesc, myTask.VarDesc, TASK_LOCATION, myTask.TaskLocation);
                }

            }
        }

        public void CreateUpdateUDP(string _connectionString, string lineDesc, string slaveUnitDesc, string varDesc, string UDPName, string UDPValue)
        {
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                SqlCommand command = new SqlCommand("spLocal_STI_Cmn_CreateUDP_Variable", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@LineDesc", lineDesc));
                command.Parameters.Add(new SqlParameter("@UnitDesc", slaveUnitDesc));
                command.Parameters.Add(new SqlParameter("@VarDesc", varDesc));
                command.Parameters.Add(new SqlParameter("@Table_Field_Desc", UDPName));
                command.Parameters.Add(new SqlParameter("@Value", UDPValue));
                command.ExecuteNonQuery();

                conn.Close();
            }
        }

        public void DeleteUDP(string _connectionString, string lineDesc, string slaveUnitDesc, string varDesc, string UDPName)
        {
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                SqlCommand command = new SqlCommand("spLocal_STI_Cmn_DeleteUDP_Variable", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@LineDesc", lineDesc));
                command.Parameters.Add(new SqlParameter("@UnitDesc", slaveUnitDesc));
                command.Parameters.Add(new SqlParameter("@VarDesc", varDesc));
                command.Parameters.Add(new SqlParameter("@Table_Field_Desc", UDPName));
                command.ExecuteNonQuery();

                conn.Close();
            }
        }

    }
}
