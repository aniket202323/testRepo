using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
//using System.Web.Http;
using System.Data.OleDb;
using System.Text.RegularExpressions;
using System.Configuration;
using System.Data.SqlClient;
using System.Collections;
using System.IO;
using ExcelDataReader;
using Newtonsoft.Json.Converters;
using System.Web.UI.WebControls;

namespace eCIL_DataLayer
{
    public class ExcelTask
    {
        PlantModel plantModel;
        #region Variables

        private string fL1;
        private string fL2;
        private string fL3;
        private string fL4;
        private string eCIL_Criteria;
        private string eCIL_Duration;
        private string eCIL_FixedFreq;
        private string eCIL_Hazard;
        private string eCIL_LongTaskName;
        private string eCIL_TaskName;
        private string eCIL_Lubrication;
        private string eCIL_Method;
        private string eCIL_NbrItems;
        private string eCIL_NbrPeople;
        private string eCIL_PPE;
        private string eCIL_Task_Action;
        private int eCIL_Active;
        private int eCIL_Window;
        private int eCIL_Frequency;
        private string eCIL_TaskType;
        private string eCIL_TestTime;
        private string eCIL_Tools;
        private string eCIL_VMID;
        private string eCIL_TaskLocation;
        private string eCIL_ScheduleScope;
        private string eCIL_LastCompletionDate;
        private string eCIL_FirstEffectiveDate;
        private string eCIL_LineVersion;
        private string eCIL_ModuleFeatureVersion;
        private string eCIL_TaskId;
        private string eCIL_Module;
        private string eCIL_documentDesc1;
        private string eCIL_documentLink1;
        private string eCIL_documentDesc2;
        private string eCIL_documentLink2;
        private string eCIL_documentDesc3;
        private string eCIL_documentLink3;
        private string eCIL_documentDesc4;
        private string eCIL_documentLink4;
        private string eCIL_documentDesc5;
        private string eCIL_documentLink5;
        private int eCIL_HSEFlag;
        private string eCIL_FreqType;
        private int eCIL_ShiftOffset;
        private string status = string.Empty;
        private bool? eCIL_autopostpone;
        #endregion

        #region Properties

        public string FL1 { get => fL1; set => fL1 = value; }
        public string FL2 { get => fL2; set => fL2 = value; }
        public string FL3 { get => fL3; set => fL3 = value; }
        public string FL4 { get => fL4; set => fL4 = value; }
        public string ECIL_Criteria { get => eCIL_Criteria; set => eCIL_Criteria = value; }
        public string ECIL_Duration { get => eCIL_Duration; set => eCIL_Duration = value; }
        public string ECIL_FixedFreq { get => eCIL_FixedFreq; set => eCIL_FixedFreq = value; }
        public string ECIL_Hazard { get => eCIL_Hazard; set => eCIL_Hazard = value; }
        public string ECIL_LongTaskName { get => eCIL_LongTaskName; set => eCIL_LongTaskName = value; }
        public string ECIL_TaskName { get => eCIL_TaskName; set => eCIL_TaskName = value; }
        public string ECIL_Lubrication { get => eCIL_Lubrication; set => eCIL_Lubrication = value; }
        public string ECIL_Method { get => eCIL_Method; set => eCIL_Method = value; }
        public string ECIL_NbrItems { get => eCIL_NbrItems; set => eCIL_NbrItems = value; }
        public string ECIL_NbrPeople { get => eCIL_NbrPeople; set => eCIL_NbrPeople = value; }
        public string ECIL_PPE { get => eCIL_PPE; set => eCIL_PPE = value; }
        public string ECIL_Task_Action { get => eCIL_Task_Action; set => eCIL_Task_Action = value; }
        public int ECIL_Active { get => eCIL_Active; set => eCIL_Active = value; }
        public int ECIL_Window { get => eCIL_Window; set => eCIL_Window = value; }
        public int ECIL_Frequency { get => eCIL_Frequency; set => eCIL_Frequency = value; }
        public string ECIL_TaskType { get => eCIL_TaskType; set => eCIL_TaskType = value; }
        public string ECIL_TestTime { get => eCIL_TestTime; set => eCIL_TestTime = value; }
        public string ECIL_Tools { get => eCIL_Tools; set => eCIL_Tools = value; }
        public string ECIL_VMID { get => eCIL_VMID; set => eCIL_VMID = value; }
        public string ECIL_TaskLocation { get => eCIL_TaskLocation; set => eCIL_TaskLocation = value; }
        public string ECIL_ScheduleScope { get => eCIL_ScheduleScope; set => eCIL_ScheduleScope = value; }
        public string ECIL_LastCompletionDate { get => eCIL_LastCompletionDate; set => eCIL_LastCompletionDate = value; }
        public string ECIL_FirstEffectiveDate { get => eCIL_FirstEffectiveDate; set => eCIL_FirstEffectiveDate = value; }
        public string ECIL_LineVersion { get => eCIL_LineVersion; set => eCIL_LineVersion = value; }
        public string ECIL_ModuleFeatureVersion { get => eCIL_ModuleFeatureVersion; set => eCIL_ModuleFeatureVersion = value; }
        public string ECIL_TaskId { get => eCIL_TaskId; set => eCIL_TaskId = value; }
        public string ECIL_Module { get => eCIL_Module; set => eCIL_Module = value; }
        public string ECIL_DocumentDesc1 { get => eCIL_documentDesc1; set => eCIL_documentDesc1 = value; }
        public string ECIL_DocumentLink1 { get => eCIL_documentLink1; set => eCIL_documentLink1 = value; }
        public string ECIL_DocumentDesc2 { get => eCIL_documentDesc2; set => eCIL_documentDesc2 = value; }
        public string ECIL_DocumentLink2 { get => eCIL_documentLink2; set => eCIL_documentLink2 = value; }
        public string ECIL_DocumentDesc3 { get => eCIL_documentDesc3; set => eCIL_documentDesc3 = value; }
        public string ECIL_DocumentLink3 { get => eCIL_documentLink3; set => eCIL_documentLink3 = value; }
        public string ECIL_DocumentDesc4 { get => eCIL_documentDesc4; set => eCIL_documentDesc4 = value; }
        public string ECIL_DocumentLink4 { get => eCIL_documentLink4; set => eCIL_documentLink4 = value; }
        public string ECIL_DocumentDesc5 { get => eCIL_documentDesc5; set => eCIL_documentDesc5 = value; }
        public string ECIL_DocumentLink5 { get => eCIL_documentLink5; set => eCIL_documentLink5 = value; }
        public int ECIL_HSEFlag { get => eCIL_HSEFlag; set => eCIL_HSEFlag = value; }
        public string ECIL_FreqType { get => eCIL_FreqType; set => eCIL_FreqType = value; }
        public int ECIL_ShiftOffset { get => eCIL_ShiftOffset; set => eCIL_ShiftOffset = value; }
        public string Status { get => status; set => status = value; }
        public bool? ECIL_Autopostpone { get => eCIL_autopostpone; set => eCIL_autopostpone = value; }
        #endregion


        public class LineVersion
        {
            #region Variables
            private string lineDesc;
            private string currentVersion;
            private string newVersion;
            #endregion

            #region Properties
            public string LineDesc { get => lineDesc; set => lineDesc = value; }
            public string CurrentVersion { get => currentVersion; set => currentVersion = value; }
            public string NewVersion { get => newVersion; set => newVersion = value; }
            #endregion

        }

        public class Fl2Fl3ModuleDesc
        {
            #region Variables
            private string fl2;
            private string fl3;
            private string moduledesc;
            #endregion

            #region Properties
            public string FL2 { get => fl2; set => fl2 = value; }
            public string FL3 { get => fl3; set => fl3 = value; }
            public string ModuleDesc { get => moduledesc; set => moduledesc = value; }
            #endregion

            public Fl2Fl3ModuleDesc()
            {
                FL2 = string.Empty;
                FL3 = string.Empty;
                ModuleDesc = string.Empty;
            }


            public Fl2Fl3ModuleDesc(string fl2, string fl3, string moduledesc)
            {
                FL2 = fl2;
                FL3 = fl3;
                ModuleDesc = moduledesc;
            }

            public bool Compare(string fl2, string fl3, string moduledesc)
            {
                if ((FL2.Equals(fl2)) && FL3.Equals(fl3) && ModuleDesc.Equals(moduledesc))
                    return true;
                else
                    return false;

            }
        }



        #region Constant
        public const string SHIFTLY = "Shiftly";
        public const string DAILY = "Daily";
        public const string MULTI_DAY = "Multi-Day";
        public const string MINUTES = "Minutes";

        public const string ADD_TASK = "Add";
        public const string DELETE_TASK = "Obsolete";
        public const string UPDATE_TASK = "Modify";
        public const string ERROR_TASK = "Error";

        #endregion

        #region Methods
        public ExcelTask()
        {
            plantModel = new PlantModel();
        }
        public List<ExcelTask> ReadDatafFromExcelFile(string path, string sheet)
        {
            var result = new List<ExcelTask>();


            //string pathconn = ConfigurationManager.AppSettings["ExcelProvider"] + path + ConfigurationManager.AppSettings["ExcelProperties"];
            //OleDbConnection conn = new OleDbConnection(pathconn);
            //conn.Open();
            //OleDbCommand command = new OleDbCommand("select * from [" + sheet + "$]", conn);

            using (var stream = File.Open(path, FileMode.Open, FileAccess.Read))
            {

                using (var reader = ExcelReaderFactory.CreateReader(stream))
                {
                    bool firstRow = true;
                    while (reader.Read())
                    {   //the method will read all rows from excel
                        //we need to skip the first row = table header

                        if (!firstRow)
                        {
                            ExcelTask exceltask = new ExcelTask();



                            try
                            {
                                exceltask.FL1 = reader.GetString(0) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.FL1 = string.Empty;
                            }


                            try
                            {
                                exceltask.FL2 = reader.GetString(1) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.FL2 = string.Empty;
                            }


                            try
                            {
                                exceltask.FL3 = reader.GetString(2) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.FL3 = string.Empty;
                            }




                            try
                            {
                                exceltask.FL4 = reader.GetString(3) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.FL4 = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_Criteria = reader.GetString(4) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_Criteria = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_Duration = reader.GetString(5) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_Duration = string.Empty;
                            }


                            try
                            {

                                exceltask.ECIL_FixedFreq = reader.GetString(6) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_FixedFreq = string.Empty;
                            }





                            try
                            {
                                exceltask.ECIL_Hazard = reader.GetString(7) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_Hazard = string.Empty;
                            }

                            //eCIL Long Task Name

                            try
                            {
                                exceltask.ECIL_LongTaskName = reader.GetString(8) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_LongTaskName = string.Empty;

                            }



                            try
                            {
                                exceltask.ECIL_TaskName = reader.GetString(9) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_TaskName = string.Empty;

                            }



                            try
                            {
                                exceltask.ECIL_Lubrication = reader.GetString(10) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_Lubrication = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_Method = reader.GetString(11) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_Method = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_NbrItems = reader.GetString(12) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_NbrItems = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_NbrPeople = reader.GetString(13) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_NbrPeople = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_PPE = reader.GetString(14) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_PPE = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_Task_Action = reader.GetString(15) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_Task_Action = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_Active = Convert.ToInt32(reader.GetString(16));
                            }
                            catch 
                            {
                                exceltask.ECIL_Active = -1;
                            }


                            try
                            {
                                exceltask.ECIL_Window = Convert.ToInt32(reader.GetString(17));
                            }
                            catch 
                            {
                                exceltask.ECIL_Window = -1;
                            }

                            try
                            {
                                exceltask.ECIL_Frequency = !string.IsNullOrEmpty(reader.GetString(18)) ? Convert.ToInt32(reader.GetString(18)) : -1;
                            }
                            catch 
                            {
                                exceltask.ECIL_Frequency = -1;
                            }



                            try
                            {
                                exceltask.ECIL_TaskType = reader.GetString(19) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_TaskType = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_TestTime = reader.GetString(20) ?? string.Empty;

                            }
                            catch 
                            {
                                exceltask.ECIL_TestTime = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_Tools = reader.GetString(21) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_Tools = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_VMID = reader.GetString(22) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_VMID = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_TaskLocation = reader.GetString(23) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_TaskLocation = string.Empty;
                            }




                            try
                            {
                                exceltask.eCIL_ScheduleScope = reader.GetString(24) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_ScheduleScope = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_LastCompletionDate = reader.GetString(25) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_LastCompletionDate = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_FirstEffectiveDate = reader.GetString(26) ?? string.Empty;
                            }
                            catch 
                            {
                                //exceltask.ECIL_FirstEffectiveDate = string.Empty;
                                exceltask.ECIL_FirstEffectiveDate = "1/1/1900";
                            }



                            //-2 = string empty
                            //-1 = Issue on parsing to double 
                            //try
                            //{
                            //    string lineVersion = reader.GetString(27) ?? string.Empty;
                            //    if (lineVersion != string.Empty)
                            //        exceltask.ECIL_LineVersion = Double.Parse(lineVersion);
                            //    else
                            //        exceltask.ECIL_LineVersion = Double.Parse("-2");
                            //}
                            //catch 
                            //{
                            //    exceltask.ECIL_LineVersion = Double.Parse("-1");
                            //}

                            try
                            {
                                //exceltask.ECIL_LineVersion = reader.GetString(27) ?? string.Empty;
                                exceltask.ECIL_LineVersion = string.IsNullOrEmpty(reader.GetValue(27).ToString()) ? string.Empty : reader.GetValue(27).ToString();
                            }
                            catch 
                            {
                                exceltask.ECIL_LineVersion = string.Empty;
                            }



                            //-2 = string empty
                            //-1 = Issue on parsing to double 
                            //try
                            //{
                            //    string moduleVersion = reader.GetString(28) ?? string.Empty;
                            //    if (moduleVersion != string.Empty)
                            //        exceltask.ECIL_ModuleFeatureVersion = Double.Parse(moduleVersion);
                            //    else
                            //        exceltask.ECIL_ModuleFeatureVersion = Double.Parse("-2");
                            //}
                            //catch 
                            //{
                            //    exceltask.ECIL_ModuleFeatureVersion = Double.Parse("-1");
                            //}

                            try
                            {
                                //exceltask.ECIL_ModuleFeatureVersion = reader.GetString(28) ?? string.Empty;
                                exceltask.ECIL_ModuleFeatureVersion = string.IsNullOrEmpty(reader.GetValue(28).ToString()) ? string.Empty : reader.GetValue(28).ToString();
                            }
                            catch 
                            {
                                exceltask.ECIL_ModuleFeatureVersion = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_TaskId = reader.GetString(29) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_TaskId = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_Module = reader.GetString(30) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_Module = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_DocumentDesc1 = reader.GetString(31) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_DocumentDesc1 = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_DocumentLink1 = reader.GetString(32) ?? string.Empty;
                            }
                            catch
                            {
                                exceltask.ECIL_DocumentLink1 = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_DocumentDesc2 = reader.GetString(33) ?? string.Empty;
                            }
                            catch
                            {
                                exceltask.ECIL_DocumentDesc2 = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_DocumentLink2 = reader.GetString(34) ?? string.Empty;
                            }
                            catch
                            {
                                exceltask.ECIL_DocumentLink2 = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_DocumentDesc3 = reader.GetString(35) ?? string.Empty;
                            }
                            catch
                            {
                                exceltask.ECIL_DocumentDesc3 = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_DocumentLink3 = reader.GetString(36) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_DocumentLink3 = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_DocumentDesc4 = reader.GetString(37) ?? string.Empty;
                            }
                            catch
                            {
                                exceltask.ECIL_DocumentDesc4 = string.Empty;
                            }



                            try
                            {
                                exceltask.ECIL_DocumentLink4 = reader.GetString(38) ?? string.Empty;
                            }
                            catch
                            {
                                exceltask.ECIL_DocumentLink4 = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_DocumentDesc5 = reader.GetString(39) ?? string.Empty;
                            }
                            catch
                            {
                                exceltask.ECIL_DocumentDesc5 = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_DocumentLink5 = reader.GetString(40) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_DocumentLink5 = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_HSEFlag = Convert.ToInt32(reader.GetString(41));
                            }
                            catch 
                            {
                                exceltask.ECIL_HSEFlag = -1;
                            }

                            try
                            {
                                exceltask.ECIL_FreqType = reader.GetString(42) ?? string.Empty;
                            }
                            catch 
                            {
                                exceltask.ECIL_FreqType = string.Empty;
                            }


                            try
                            {
                                exceltask.ECIL_ShiftOffset = Convert.ToInt32(reader.GetString(43));
                            }
                            catch 
                            {
                                exceltask.ECIL_ShiftOffset = -1;
                            }

                            try
                            {
                                string tempAutopostpone = reader.GetString(44);
                                //we will mark the empty value with -1
                                if (string.IsNullOrEmpty(tempAutopostpone) && exceltask.ECIL_FreqType == MULTI_DAY)
                                    exceltask.ECIL_Autopostpone = null;

                                else if (string.IsNullOrEmpty(tempAutopostpone))
                                    exceltask.ECIL_Autopostpone = false;
                                else
                                    exceltask.ECIL_Autopostpone = Convert.ToBoolean(Convert.ToInt32(reader.GetString(44)));
                            }
                            catch 
                            {
                                //mark the value with null to throw to the UI an error message
                                exceltask.ECIL_Autopostpone = null;
                            }
                            exceltask.Status = "";
                            result.Add(exceltask);
                        }
                        firstRow = false;
                    }
                    reader.Close();
                }


                stream.Close();

            }

            return result;
        }

        public List<ValidatedTask> RawDataFileValidation(string path, string sheet, bool linelevelComparision, bool modulelevelComparision)
        {
            var result = new List<ExcelTask>();
            var validatedtask = new List<ValidatedTask>();
            var VMIds = new Hashtable();
            var ModuleFL3s = new Hashtable();
            var ModuleVersions = new Hashtable();

            //Boolean WindowExists;
            Boolean FrequencyExists;
            Boolean FrequencyTypeExists;
            //Boolean ShiftOffsetExists;
            Boolean Errormessage = false;

            result = ReadDatafFromExcelFile(path, sheet);

            for (int i = 0; i < result.Count; i++)
            {
                ValidatedTask validateTask = new ValidatedTask();
                var ultility = new Utilities();


                if (linelevelComparision == true)
                {


                    if (!((result[0].ECIL_LineVersion).Equals((result[i].ECIL_LineVersion))))
                    {
                        validateTask.ECILLineVersion = "Invalid File. Multiple line versions for the same line.";
                        Errormessage = true;
                    }


                    if ((DBNull.Value.Equals(result[i].FL2)) || (string.IsNullOrEmpty(result[i].FL2)))
                    {
                        validateTask.FL2 = "Invalid File.FL2 information is required for Line-Level comparison.";
                        Errormessage = true;
                    }
                }

                if (modulelevelComparision == true)
                {
                    if (!(result[0].ECIL_Module).Equals((result[i].ECIL_Module)))
                    {
                        validateTask.ECILModule = "Invalid File. Multiple modules are not allowed for module level comparison.";
                        Errormessage = true;
                    }
                }

                if ((string.IsNullOrEmpty(result[i].FL3)))
                {
                    validateTask.FL3 = "Invalid File. Incorrect format of FL3. Cannot be empty.";
                    Errormessage = true;
                }

                if (ModuleFL3s.ContainsKey(result[i].ECIL_Module))
                {
                    if (!(ModuleFL3s[result[i].ECIL_Module].Equals(result[i].FL3)))
                    {
                        validateTask.FL3 = "Invalid File. Multiple FL3s for the same module.";
                        Errormessage = true;
                    }
                    else
                    {
                        ModuleFL3s.Add(result[i].ECIL_Module, result[i].FL3);
                    }
                }

                //Commented below If condition as the module feature version can be a empty string
                //if (result[i].ECIL_ModuleFeatureVersion != Double.Parse("-2"))
                //{
                if (ModuleVersions.ContainsKey(result[i].ECIL_Module))
                {
                    if (!(ModuleVersions[result[i].ECIL_Module].Equals(result[i].ECIL_ModuleFeatureVersion)))
                    {
                        validateTask.ECILModuleFeatureVersion = "Invalid File. Multiple Module Feature Versions for the same module.";
                        Errormessage = true;
                    }
                }
                else
                    ModuleVersions.Add(result[i].ECIL_Module, result[i].ECIL_ModuleFeatureVersion);

                // }

                //Commented below validation as the Line Version and Module Version can be alphanumeric
                //Validate LineVersion
                //if ((result[i].ECIL_LineVersion == Double.Parse("-1")))
                //{
                //    validateTask.ECILLineVersion = "Invalid file. Incorrect format of Line Version. Should be numeric.";
                //    Errormessage = true;
                //}

                //if (result[i].ECIL_ModuleFeatureVersion == Double.Parse("-1"))
                //{
                //    validateTask.ECILModuleFeatureVersion = "Invalid file. Incorrect format of Module Feature Version. Should be numeric.";
                //    Errormessage = true;
                //}


                if ((string.IsNullOrEmpty(result[i].ECIL_VMID)))
                {
                    validateTask.ECILVMID = "Invalid File. Incorrect format of VM Id. Cannot be empty.";
                    Errormessage = true;
                }

                if (!(string.IsNullOrEmpty(result[i].ECIL_Duration)))
                {
                    try
                    {
                        Double.Parse(result[i].ECIL_Duration);
                    }
                    catch
                    {
                        validateTask.ECILDuration = "Invalid File. Incorrect format of Duration. Must be numeric.";
                        Errormessage = true;
                    }
                }

                //if (!(string.IsNullOrEmpty(result[i].ECIL_FixedFreq)))
                //{
                //    string pattern = @"^[01]$";
                //    Regex re = new Regex(pattern);

                //    if (!(re.IsMatch(result[i].ECIL_FixedFreq)))
                //    {
                //        validateTask.ECILFixedFreq = "Invalid File. Incorrect format of Fixed Frequency.Must be 0 or 1(false or true).";
                //        Errormessage = true;
                //    }
                //}

                //if (!(string.IsNullOrEmpty(result[i].ECIL_FixedFreq)))
                //{
                //    string pattern = @"^[01]$";
                //    Regex re = new Regex(pattern);

                //    if (!(re.IsMatch(result[i].ECIL_FixedFreq)))
                //    {
                //        validateTask.ECILFixedFreq = "Invalid File. Incorrect format of Fixed Frequency.Must be 0 or 1(false or true).";
                //        Errormessage = true;
                //    }
                //}

                if (string.IsNullOrEmpty(result[i].ECIL_TaskName))
                {
                    validateTask.ECILTaskName = "Invalid File. Incorrect format of Task Name. Cannot be empty.";
                    Errormessage = true;
                }
                else if ((result[i].ECIL_TaskName).Length > 50)
                {
                    validateTask.ECILTaskName = "Invalid File. Incorrect format of Task Name. Cannot be longer than 50 characters.";
                    Errormessage = true;
                }

                if (!(string.IsNullOrEmpty(result[i].ECIL_NbrItems)))
                {

                    Regex re = new Regex("[0-9]");
                    if (!(re.IsMatch(result[i].ECIL_NbrItems)))
                    {
                        validateTask.ECILNbrItems = "Invalid File. Incorrect format of Nbr items. Must be numeric.";
                        Errormessage = true;
                    }
                }

                if (!(string.IsNullOrEmpty(result[i].ECIL_NbrPeople)))
                {

                    Regex re = new Regex("^[0-9 ]+$");
                    if (!(re.IsMatch(result[i].ECIL_NbrPeople)))
                    {
                        validateTask.ECILNbrItems = "Invalid File. Incorrect format of Nbr People. Must be numeric.";
                        Errormessage = true;
                    }
                }

                if (string.IsNullOrEmpty(result[i].ECIL_Task_Action))
                {
                    validateTask.ECILTaskAction = "Invalid File. Incorrect format of Task Action. Cannot be empty.";
                    Errormessage = true;
                }
                else
                {
                    string pattern = "^[CILcil]";
                    Regex re = new Regex(pattern);
                    if (!(re.IsMatch(result[i].ECIL_Task_Action)))
                    {
                        validateTask.ECILTaskAction = "Invalid File. Incorrect format of Task Action.Must be C, I, L or any combination.";
                        Errormessage = true;
                    }
                }

                FrequencyTypeExists = false;
                if (!(string.IsNullOrEmpty(result[i].ECIL_FreqType)))
                {
                    if ((result[i].ECIL_FreqType == SHIFTLY) || (result[i].ECIL_FreqType == DAILY) || (result[i].ECIL_FreqType == MULTI_DAY) || (result[i].ECIL_FreqType == MINUTES))
                        FrequencyTypeExists = true;
                    else
                    {
                        validateTask.ECILFreqType = "Invalid File. Frequency type must be '" + SHIFTLY + "'," + DAILY + "','" + MULTI_DAY + "', or '" + MINUTES + "'";
                        Errormessage = true;
                    }
                }
                else
                {
                    validateTask.ECILFreqType = "Invalid File. Incorrect format of Frequency Type. Cannot be empty.";
                    Errormessage = true;
                }


                FrequencyExists = false;
                validateTask.ECILFrequency = ultility.VerifyFrequency(result[i].ECIL_Frequency);
                if (!(string.IsNullOrEmpty(validateTask.ECILFrequency)))
                {
                    Errormessage = true;
                }
                else if (FrequencyTypeExists == true)
                {
                    validateTask.ECILFrequency = ultility.VerifyFrequencyRange(result[i].ECIL_Frequency, result[i].ECIL_FreqType);
                    if (!(string.IsNullOrEmpty(validateTask.ECILFrequency)))
                    {
                        Errormessage = true;
                    }
                    else
                        FrequencyExists = true;
                }



                //WindowExists = false;
                validateTask.ECILWindow = ultility.VerifyWindow(result[i].ECIL_Window);
                if (!(string.IsNullOrEmpty(validateTask.ECILWindow)))
                {
                    Errormessage = true;
                }
                else if (FrequencyExists == true && FrequencyTypeExists == true)
                {
                    validateTask.ECILWindow = ultility.VerifyWindowRange(result[i].ECIL_Window, result[i].ECIL_Frequency, result[i].ECIL_FreqType);
                    if (!(string.IsNullOrEmpty(validateTask.ECILWindow)))
                    {
                        Errormessage = true;
                    }
                    //else
                    //    WindowExists = true;
                }

                if (!(string.IsNullOrEmpty(result[i].ECIL_FixedFreq)))
                {
                    string pattern = @"^[01]$";
                    Regex re = new Regex(pattern);

                    if (!(re.IsMatch(result[i].ECIL_FixedFreq)))
                    {
                        validateTask.ECILFixedFreq = "Invalid File. Incorrect format of Fixed Frequency.Must be 0 or 1(false or true).";
                        Errormessage = true;
                    }
                }

                if (FrequencyTypeExists == true && ((result[i].ECIL_FreqType == MULTI_DAY) || (result[i].ECIL_FreqType == MINUTES)))
                {
                    if (string.IsNullOrEmpty(result[i].ECIL_FixedFreq))
                    {
                        validateTask.ECILFixedFreq = "Invalid File. Incorrect format of Fixed Frequency.Cannot be empty. Must be 0 or 1(false or true) for Multi-day and Minutes tasks.";
                        Errormessage = true;
                    }
                }




                //ShiftOffsetExists = false;
                validateTask.ECILShiftOffset = ultility.VerifyShiftOffset(result[i].ECIL_ShiftOffset);
                if (!(string.IsNullOrEmpty(validateTask.ECILShiftOffset)))
                {
                    Errormessage = true;
                }
                else if (FrequencyExists == true && FrequencyTypeExists == true && result[i].eCIL_FreqType == "Minutes")
                {
                    validateTask.ECILShiftOffset = ultility.VerifyShiftOffsetRange(result[i].ECIL_ShiftOffset, result[i].ECIL_Frequency);
                    if (!(string.IsNullOrEmpty(validateTask.ECILShiftOffset)))
                    {
                        Errormessage = true;
                    }
                    //else
                    //    ShiftOffsetExists = true;
                }


                if (string.IsNullOrEmpty(result[i].ECIL_TaskType))
                {
                    validateTask.ECILTaskType = "Invalid File. Incorrect format of Task Type. Cannot be empty.";
                    Errormessage = true;
                }
                else
                {
                    string pattern = "^[draDRA]";
                    Regex re = new Regex(pattern);
                    if (!(re.IsMatch(result[i].ECIL_TaskType)))
                    {
                        validateTask.ECILTaskType = "Invalid File. Incorrect format of Task Type. Must be D, R or A.";
                        Errormessage = true;
                    }
                }

                if (!(string.IsNullOrEmpty(result[i].ECIL_TestTime)))
                {
                    TimeSpan timeResult;
                    Regex re = new Regex("^[0-2][0-9]:[0-5][0-9]$");


                    if (TimeSpan.TryParse(result[i].ECIL_TestTime, out timeResult))
                    {
                        if (!(re.IsMatch(result[i].ECIL_TestTime)))
                        {
                            validateTask.ECILTestTime1 = "Invalid File. Incorrect format of Test Time. Must be HH:MM.";
                            Errormessage = true;
                        }
                    }
                    else
                    {
                        validateTask.ECILTestTime1 = "Invalid File. Incorrect format of Test Time. Must be HH:MM.";
                        Errormessage = true;
                    }

                }

                if (VMIds.Contains(result[i].ECIL_VMID))
                {
                    validateTask.ECILVMID = "Invalid File. VMId is duplicated for one or more task(s).";
                    Errormessage = true;
                }
                else
                {
                    VMIds.Add((result[i].ECIL_VMID), (result[i].ECIL_VMID));
                }



                if (!(string.IsNullOrEmpty(result[i].ECIL_TaskLocation)))
                {
                    string pattern = ("^[gGlL]$");
                    Regex re = new Regex(pattern);
                    if (!(re.IsMatch(result[i].ECIL_TaskLocation)))
                    {
                        validateTask.ECILTaskLocation = "Invalid File. Incorrect format of Task Location.Must be G or L.";
                        Errormessage = true;
                    }
                }

                if (!(string.IsNullOrEmpty(result[i].ECIL_FirstEffectiveDate)))
                {
                    string pattern = ("^20[0-9][0-9]-[0-1][0-9]-[0-3][0-9]$");
                    Regex re = new Regex(pattern);
                    DateTime firsteffectivedateresult;
                    if (DateTime.TryParse(result[i].ECIL_FirstEffectiveDate, out firsteffectivedateresult))
                    {
                        if ((!(re.IsMatch(result[i].ECIL_FirstEffectiveDate))))
                        {
                            validateTask.ECILFirstEffectiveDate = "Invalid File. Incorrect format of First Effective Date. Must be YYYY-MM-DD.";
                            Errormessage = true;
                        }
                    }
                    else
                    {
                        validateTask.ECILFirstEffectiveDate = "Invalid File. Incorrect format of First Effective Date. Must be YYYY-MM-DD.";
                        Errormessage = true;
                    }

                }

                // Commented the below as Task Id is a non-mandatory field as per User Story 6532
               // if (string.IsNullOrEmpty(result[i].ECIL_TaskId))
               // {
               //     validateTask.ECILTaskId = "Invalid File. Incorrect format of Task Id. Cannot be empty.";
               //     Errormessage = true;
               // }

                if ((result[i].eCIL_Module).Length > 50)
                {
                    validateTask.ECILModule = "Invalid File. Incorrect format of Module. Cannot be longer than 50 characters.";
                    Errormessage = true;
                }


                if (!(string.IsNullOrEmpty(result[i].ECIL_HSEFlag.ToString())))
                {
                    string pattern = @"^[01]$";
                    Regex re = new Regex(pattern);
                    if (!(re.IsMatch(result[i].ECIL_HSEFlag.ToString())))
                    {
                        validateTask.ECILHSEFlag = "Invalid File. Incorrect format of Is HSE. Must be 0 or 1(false or true).";
                        Errormessage = true;
                    }

                }

                if (!(string.IsNullOrEmpty(result[i].ECIL_Active.ToString())))
                {
                    string pattern = @"^[01]$";
                    Regex re = new Regex(pattern);
                    if (!(re.IsMatch(result[i].ECIL_Active.ToString())))
                    {
                        validateTask.ECILActive = "Invalid File. Incorrect format of Active. Must be 0 or 1(false or true).";
                        Errormessage = true;
                    }

                }

                //validate fixedFrequency with autopostpone

                if (result[i].ECIL_FixedFreq == "0" && !(result[i].ECIL_Autopostpone == false || result[i].ECIL_Autopostpone == true) && result[i].ECIL_FreqType == MULTI_DAY)
                {
                    validateTask.ECILAutopostpone = "Invalid File. Incorrect value of Autopostpone. It needs to be 0 or 1.";
                    Errormessage = true;
                }
                if (result[i].ECIL_FixedFreq == "1" && result[i].ECIL_Autopostpone != false && result[i].ECIL_FreqType == MULTI_DAY)
                {
                    validateTask.ECILAutopostpone = "Invalid File. Incorrect value of Autopostpone. It needs to be empty or 0";
                    Errormessage = true;
                }

                if (result[i].ECIL_Autopostpone != false && result[i].ECIL_FreqType != MULTI_DAY)
                {
                    validateTask.ECILAutopostpone = "Invalid File. Autopostpone can be applied only for Multi-Day task";
                    Errormessage = true;
                }

                if (result[i].ECIL_Autopostpone != false && result[i].ECIL_Autopostpone != true)
                {
                    validateTask.ECILAutopostpone = "Invalid File. Incorrect format of Autopostpone. Must be 0 or 1(false or true).";
                    Errormessage = true;
                }
                validatedtask.Add(validateTask);
            }

            if (Errormessage == false)
                return null;
            else
                return validatedtask;

        }

        public List<PlantModel.LineVersion> GetLineVersionStatistics(string _connectionString, string path, string sheet, bool linelevelcomparision, int lineId)
        {
            var result = new List<PlantModel.LineVersion>();
            var temp = new PlantModel.LineVersion();
            var exceltasklist = new List<ExcelTask>();
            var plantmodeldata = new List<PlantModel.PlantModelData>();

            //get the exceltasks from excel file
            exceltasklist = ReadDatafFromExcelFile(path, sheet);


            //get the line statistics info in GBDB
            plantmodeldata = GetLineHierarchyInfo(_connectionString, lineId);

            //check if the file is empty or the response from GBDB is empty
            //if not , we get the old line version from the GBDB and the new line version from excel file
            if (exceltasklist.Count() > 0 && plantmodeldata.Count() > 0)
            {
                temp.LineDesc = plantmodeldata[0].LineDesc;
                temp.CurrentVersion = plantmodeldata[0].LineVersion;
                // Commented below as LineVersion is a string value
                //if (exceltasklist[0].ECIL_LineVersion == Double.Parse("-2"))
                //    temp.NewVersion = string.Empty;
                //else
                //    temp.NewVersion = Convert.ToString(exceltasklist[0].ECIL_LineVersion);
                temp.NewVersion = exceltasklist[0].ECIL_LineVersion;
                temp.ModuleVersion = new List<PlantModel.ModuleVersion>();
                //get ModuleVersion for this line
                var excelTasksHash = new Hashtable();

                //get the feature version for modules
                foreach (var task in exceltasklist)
                {
                    PlantModel.ModuleVersion module = new PlantModel.ModuleVersion();
                    if (!excelTasksHash.ContainsKey(string.Format("{0}-{1}-{2}", task.FL2, task.FL3, task.ECIL_Module)))
                    {
                        module.LineDesc = "";
                        module.ModuleDesc = task.ECIL_Module;
                        // Commented below as Module Feature version is a string value
                        //if (task.ECIL_ModuleFeatureVersion == Double.Parse("-2"))
                        //    module.NewVersion = string.Empty;
                        //else
                        //    module.NewVersion = Convert.ToString(task.ECIL_ModuleFeatureVersion);
                        module.NewVersion = task.ECIL_ModuleFeatureVersion;
                        module.CurrentVersion = "";
                        temp.ModuleVersion.Add(module);
                        excelTasksHash.Add(string.Format("{0}-{1}-{2}", task.FL2, task.FL3, task.ECIL_Module), task.ECIL_ModuleFeatureVersion);

                    }
                }

                //compare with what it is in GBDB
                foreach (var aux in plantmodeldata)
                {
                    //our task is not a new task and has details in GBDB
                    if (excelTasksHash.ContainsKey(string.Format("{0}-{1}-{2}", aux.FL2, aux.FL3, aux.SlaveUnitDesc)))
                    {
                        foreach (var module in temp.ModuleVersion)
                            if (module.ModuleDesc == aux.SlaveUnitDesc)
                            {
                                module.LineDesc = aux.LineDesc;
                                module.CurrentVersion = aux.ModuleFeatureVersion;
                            }
                    }
                }

                result.Add(temp);
            }

            return result;
        }


        public List<PlantModel.ModuleVersion> GetModuleVersionStatistics(string _connectionString, string path, string sheet, bool modulelevelcomparision, int puId)
        {
            var result = new List<PlantModel.ModuleVersion>();
            var temp = new PlantModel.ModuleVersion();

            var exceltasklist = new List<ExcelTask>();
            var plantmodeldata = new List<PlantModel.PlantModelData>();
            exceltasklist = ReadDatafFromExcelFile(path, sheet);

            plantmodeldata = GetModuleHierarchyInfo(_connectionString, puId);

            var RawDataModules = new Hashtable();
            if (exceltasklist.Count() > 0)
            {
                foreach (var exceltask in exceltasklist)
                    if (!(RawDataModules.ContainsKey(exceltask.ECIL_Module)))
                        RawDataModules.Add(exceltask.ECIL_Module, exceltask.ECIL_ModuleFeatureVersion);
            }

            foreach (DictionaryEntry de in RawDataModules)
            {
                temp.LineDesc = plantmodeldata[0].LineDesc;
                temp.ModuleDesc = de.Key.ToString();
                temp.NewVersion = de.Value.ToString();

                if (plantmodeldata.Count() > 0)
                    temp.CurrentVersion = plantmodeldata[0].ModuleFeatureVersion;
                else
                    temp.CurrentVersion = string.Empty;

                result.Add(temp);
            }

            return result;
        }
        #endregion


        #region "Read Data from Database"

        public List<PlantModel.ProficyDataSource> ReadProficyData(string _connectionString, bool lineLevelComparision, bool moduleLevelComparision, string plId, string puId)
        {
            var result = new List<PlantModel.ProficyDataSource>();
            try
            {
                if (moduleLevelComparision == true)
                    result = GetTasksListFromModule(_connectionString, puId);
                else if (lineLevelComparision == true)
                    result = GetTaskListFromProductionLine(_connectionString, plId);

            }
            catch (Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }

            return result;

        }

        public List<PlantModel.ProficyDataSource> GetTaskListFromProductionLine(string _connectionString, string plId)
        {
            var proficyDataSource = new List<PlantModel.ProficyDataSource>();
            try
            {
                proficyDataSource = GetTasksListFromPlantModelSelection(_connectionString, null, plId, null, null, null, null);
            }
            catch (Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }
            return proficyDataSource;

            //Questions
            //Add Primary key VMID
            //Throw Exception
        }

        public List<PlantModel.ProficyDataSource> GetTasksListFromModule(string _connectionString, string puId)
        {
            var proficyDataSource = new List<PlantModel.ProficyDataSource>();
            try
            {
                proficyDataSource = GetTasksListFromPlantModelSelection(_connectionString, null, null, null, puId, null, null);
            }
            catch (Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }

            return proficyDataSource;

            //Questions
            //Add Primary key VMID
            //Throw exception "Non-Unique VM IDs were detected on the module")
        }

        public List<PlantModel.ProficyDataSource> GetTasksListFromPlantModelSelection(string _connectionString, string deptIDs, string lineIDs, string masterIDs, string slaveIDs, string groupIDs, string variableIDs)
        {

            var result = new List<PlantModel.ProficyDataSource>();

            //string errormessage;
            try
            {
                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_VersionManagement", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@DeptsList", deptIDs));
                    command.Parameters.Add(new SqlParameter("@LinesList", lineIDs));
                    command.Parameters.Add(new SqlParameter("@MastersList", masterIDs));
                    command.Parameters.Add(new SqlParameter("@SlavesList", slaveIDs));
                    command.Parameters.Add(new SqlParameter("@GroupsList", groupIDs));
                    command.Parameters.Add(new SqlParameter("@VarsList", variableIDs));
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var temp = new PlantModel.ProficyDataSource();

                            if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                                temp.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("DepartmentDesc")))
                                temp.DepartmentDesc = reader.GetString(reader.GetOrdinal("DepartmentDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("DepartmentId")))
                                temp.DeptId = reader.GetInt32(reader.GetOrdinal("DepartmentId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("LineDesc")))
                                temp.LineDesc = reader.GetString(reader.GetOrdinal("LineDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("LineId")))
                                temp.LineId = reader.GetInt32(reader.GetOrdinal("LineId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitDesc")))
                                temp.MasterUnitDesc = reader.GetString(reader.GetOrdinal("MasterUnitDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitDesc")))
                                temp.SlaveUnitDesc = reader.GetString(reader.GetOrdinal("SlaveUnitDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitId")))
                                temp.SlaveUnitId = reader.GetInt32(reader.GetOrdinal("SlaveUnitId"));
                            if (!reader.IsDBNull(reader.GetOrdinal("ProductionGroupDesc")))
                                temp.ProductionGroupDesc = reader.GetString(reader.GetOrdinal("ProductionGroupDesc"));
                            if (!reader.IsDBNull(reader.GetOrdinal("ProductionGroupId")))
                                temp.ProductionGroupId = reader.GetInt32(reader.GetOrdinal("ProductionGroupId"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskDesc")))
                                temp.TaskDesc = reader.GetString(reader.GetOrdinal("TaskDesc"));

                            if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                                temp.FL1 = reader.GetString(reader.GetOrdinal("FL1"));

                            if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                                temp.FL2 = reader.GetString(reader.GetOrdinal("FL2"));

                            if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                                temp.FL3 = reader.GetString(reader.GetOrdinal("FL3"));

                            if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                                temp.FL4 = reader.GetString(reader.GetOrdinal("FL4"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Criteria")))
                                temp.Criteria = reader.GetString(reader.GetOrdinal("Criteria"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Duration")))
                                temp.Duration = reader.GetString(reader.GetOrdinal("Duration"));

                            if (!reader.IsDBNull(reader.GetOrdinal("FixedFrequency")))
                            {
                                string tempFixedFrequency = reader.GetString(reader.GetOrdinal("FixedFrequency"));
                                switch (tempFixedFrequency)
                                {
                                    case "0":
                                        temp.FixedFrequency = "0";
                                        temp.Autopostpone = "0";
                                        break;
                                    case "1":
                                        temp.FixedFrequency = "1";
                                        temp.Autopostpone = "-1";
                                        break;
                                    case "2":
                                        temp.FixedFrequency = "0";
                                        temp.Autopostpone = "1";
                                        break;
                                }
                                //temp.FixedFrequency = reader.GetString(reader.GetOrdinal("FixedFrequency"));
                            }


                            if (!reader.IsDBNull(reader.GetOrdinal("Hazards")))
                                temp.Hazards = reader.GetString(reader.GetOrdinal("Hazards"));

                            if (!reader.IsDBNull(reader.GetOrdinal("LongTaskName")))
                                temp.LongTaskName = reader.GetString(reader.GetOrdinal("LongTaskName"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Lubricant")))
                                temp.Lubricant = reader.GetString(reader.GetOrdinal("Lubricant"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Method")))
                                temp.Method = reader.GetString(reader.GetOrdinal("Method"));

                            if (!reader.IsDBNull(reader.GetOrdinal("NbrItems")))
                                temp.NbrItems = reader.GetString(reader.GetOrdinal("NbrItems"));

                            if (!reader.IsDBNull(reader.GetOrdinal("NbrPeople")))
                                temp.NbrPeople = reader.GetString(reader.GetOrdinal("NbrPeople"));

                            if (!reader.IsDBNull(reader.GetOrdinal("PPE")))
                                temp.PPE = reader.GetString(reader.GetOrdinal("PPE"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskAction")))
                                temp.TaskAction = reader.GetString(reader.GetOrdinal("TaskAction"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskFrequency")))
                                temp.TaskFrequency = reader.GetString(reader.GetOrdinal("TaskFrequency"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskType")))
                                temp.TaskType = reader.GetString(reader.GetOrdinal("TaskType"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TestTime")))
                                temp.TestTime = reader.GetString(reader.GetOrdinal("TestTime"));

                            if (!reader.IsDBNull(reader.GetOrdinal("Tools")))
                                temp.Tools = reader.GetString(reader.GetOrdinal("Tools"));

                            if (!reader.IsDBNull(reader.GetOrdinal("VMID")))
                                temp.VMId = reader.GetString(reader.GetOrdinal("VMID"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskId")))
                                temp.TaskId = reader.GetString(reader.GetOrdinal("TaskId"));

                            if (!reader.IsDBNull(reader.GetOrdinal("TaskLocation")))
                                temp.TaskLocation = reader.GetString(reader.GetOrdinal("TaskLocation"));

                            if (!reader.IsDBNull(reader.GetOrdinal("ScheduleScope")))
                                temp.ScheduleScope = reader.GetString(reader.GetOrdinal("ScheduleScope"));

                            if (!reader.IsDBNull(reader.GetOrdinal("StartDate")))
                                temp.StartDate = reader.GetString(reader.GetOrdinal("StartDate"));

                            if (!reader.IsDBNull(reader.GetOrdinal("LineVersion")))
                                temp.LineVersion = reader.GetString(reader.GetOrdinal("LineVersion"));

                            if (!reader.IsDBNull(reader.GetOrdinal("ModuleFeatureVersion")))
                                temp.ModulefeatueVersion = reader.GetString(reader.GetOrdinal("ModuleFeatureVersion"));

                            if (!reader.IsDBNull(reader.GetOrdinal("DocumentLinkPath")))
                                temp.DocumentLinkPath = reader.GetString(reader.GetOrdinal("DocumentLinkPath"));

                            if (!reader.IsDBNull(reader.GetOrdinal("DocumentLinkTitle")))
                                temp.DocumentLinkTitle = reader.GetString(reader.GetOrdinal("DocumentLinkTitle"));

                            if (!reader.IsDBNull(reader.GetOrdinal("QFactorType")))
                                temp.QfactorType = reader.GetString(reader.GetOrdinal("QFactorType"));

                            if (!reader.IsDBNull(reader.GetOrdinal("PrimaryQFactor")))
                                temp.PrimaryQFactor = reader.GetString(reader.GetOrdinal("PrimaryQFactor"));

                            if (!reader.IsDBNull(reader.GetOrdinal("HSEFlag")))
                            {
                                string aux = reader.GetString(reader.GetOrdinal("HSEFlag"));
                                if (aux == "1" || aux.ToLower() == "true")
                                    temp.HSEFlag = true;
                                else
                                    temp.HSEFlag = false;
                            }


                            if (!reader.IsDBNull(reader.GetOrdinal("ShiftOffset")))
                                temp.ShiftOffset = reader.GetInt32(reader.GetOrdinal("ShiftOffset"));


                            result.Add(temp);

                        }
                        reader.Close();
                        //Questions
                        // Add columns Status and error
                        // Define Primary key VarId
                        //Catch exception
                    }
                }
            }
            catch (Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }


            return result;
        }

        public List<PlantModel.PlantModelData> GetLineHierarchyInfo(string _connectionstring, int lineId)
        {
            var result = new List<PlantModel.PlantModelData>();

            using (SqlConnection conn = new SqlConnection(_connectionstring))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetLineHierarchyInfo", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@PLId", lineId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {

                        var temp = new PlantModel.PlantModelData();

                        if (!reader.IsDBNull(reader.GetOrdinal("DepartmentDesc")))
                            temp.DepartmentDesc = reader.GetString(reader.GetOrdinal("DepartmentDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("LineDesc")))
                            temp.LineDesc = reader.GetString(reader.GetOrdinal("LineDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("LineId")))
                            temp.LineId = reader.GetInt32(reader.GetOrdinal("LineId"));

                        if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitDesc")))
                            temp.MasterUnitDesc = reader.GetString(reader.GetOrdinal("MasterUnitDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitDesc")))
                            temp.SlaveUnitDesc = reader.GetString(reader.GetOrdinal("SlaveUnitDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("ProductionGroupDesc")))
                            temp.ProductionGroupDesc = reader.GetString(reader.GetOrdinal("ProductionGroupDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                            temp.FL1 = reader.GetString(reader.GetOrdinal("FL1"));

                        if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                            temp.FL2 = reader.GetString(reader.GetOrdinal("FL2"));

                        if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                            temp.FL3 = reader.GetString(reader.GetOrdinal("FL3"));

                        if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                            temp.FL4 = reader.GetString(reader.GetOrdinal("FL4"));

                        if (!reader.IsDBNull(reader.GetOrdinal("ModuleFeatureVersion")))
                            temp.ModuleFeatureVersion = reader.GetString(reader.GetOrdinal("ModuleFeatureVersion"));

                        if (!reader.IsDBNull(reader.GetOrdinal("LineVersion")))
                            temp.LineVersion = reader.GetString(reader.GetOrdinal("LineVersion"));

                        result.Add(temp);

                    }
                    reader.Close();
                }

            }
            return result;
        }

        public List<PlantModel.PlantModelData> GetModuleHierarchyInfo(string _connectionstring, int slaveUnitId)
        {
            var result = new List<PlantModel.PlantModelData>();

            using (SqlConnection conn = new SqlConnection(_connectionstring))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetModuleHierarchyInfo", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@SlaveUnitId", slaveUnitId));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {

                        var temp = new PlantModel.PlantModelData();

                        if (!reader.IsDBNull(reader.GetOrdinal("DepartmentDesc")))
                            temp.DepartmentDesc = reader.GetString(reader.GetOrdinal("DepartmentDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("LineDesc")))
                            temp.LineDesc = reader.GetString(reader.GetOrdinal("LineDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("LineId")))
                            temp.LineId = reader.GetInt32(reader.GetOrdinal("LineId"));

                        if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitDesc")))
                            temp.MasterUnitDesc = reader.GetString(reader.GetOrdinal("MasterUnitDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("SlaveUnitDesc")))
                            temp.SlaveUnitDesc = reader.GetString(reader.GetOrdinal("SlaveUnitDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("ProductionGroupDesc")))
                            temp.ProductionGroupDesc = reader.GetString(reader.GetOrdinal("ProductionGroupDesc"));

                        if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                            temp.FL1 = reader.GetString(reader.GetOrdinal("FL1"));

                        if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                            temp.FL2 = reader.GetString(reader.GetOrdinal("FL2"));

                        if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                            temp.FL3 = reader.GetString(reader.GetOrdinal("FL3"));

                        if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                            temp.FL4 = reader.GetString(reader.GetOrdinal("FL4"));

                        if (!reader.IsDBNull(reader.GetOrdinal("ModuleFeatureVersion")))
                            temp.ModuleFeatureVersion = reader.GetString(reader.GetOrdinal("ModuleFeatureVersion"));

                        if (!reader.IsDBNull(reader.GetOrdinal("LineVersion")))
                            temp.LineVersion = reader.GetString(reader.GetOrdinal("LineVersion"));

                        result.Add(temp);

                    }
                    reader.Close();
                }

            }
            return result;
        }

        //public List<string> AddNewModulestoPlantModelDataSource(List<PlantModel.PlantModelData> plantmodeldata, List<ExcelTask> exceltask)
        //{
        //    List<string> message = new List<string>();
        //    string UniqueFL2FL3Key;
        //    var plantModelFL2FL3 = new Hashtable();
        //    var plantModelDataNewModule = new List<PlantModel.PlantModelData>();
        //    var DataRow = new PlantModel.PlantModelData();

        //    for (int i = 0; i < plantmodeldata.Count(); i++)
        //    {
        //        UniqueFL2FL3Key = string.Format("{0}-{1}-{2}", plantmodeldata[i].FL2, plantmodeldata[i].FL3, plantmodeldata[i].SlaveUnitDesc);
        //        if (!(plantModelFL2FL3.Contains(UniqueFL2FL3Key)))
        //            plantModelFL2FL3.Add(UniqueFL2FL3Key, UniqueFL2FL3Key);
        //    }
        //    for (int j = 0; j < exceltask.Count(); j++)
        //    {
        //        if (!(plantModelFL2FL3.Contains(string.Format("{0}-{1}-{2}", exceltask[j].FL2, exceltask[j].FL3, exceltask[j].ECIL_Module))))
        //            DataRow.DepartmentDesc = plantmodeldata[0].DepartmentDesc;
        //        DataRow.LineDesc = plantmodeldata[0].LineDesc;

        //        DataRow.LineId = plantmodeldata[0].LineId;
        //        DataRow.FL1 = plantmodeldata[0].FL1;
        //        DataRow.FL3 = exceltask[j].FL3;
        //        DataRow.SlaveUnitDesc = exceltask[j].ECIL_Module;
        //        plantModelDataNewModule.Add(DataRow);
        //        // Check what do we do with this new modules list to add, new API to add them ?
        //    }

        //    if ((plantModelDataNewModule.Count()) == 0) // >
        //        message.Add("ManualMasterSelection");
        //    else
        //        message.Add("Success");

        //    return message;


        //}

        public List<PlantModel.PlantModelData> AddNewModulestoPlantModelDataSource(List<PlantModel.PlantModelData> plantmodeldata, List<ExcelTask> exceltask)
        {
            List<string> message = new List<string>();
            string UniqueFL2FL3Key;
            string RawDataFL2FL3Key;
            var plantModelFL2FL3 = new Hashtable();
            var plantModelDataNewModule = new List<PlantModel.PlantModelData>();
            var DataRow = new PlantModel.PlantModelData();

            for (int i = 0; i < plantmodeldata.Count(); i++)
            {
                UniqueFL2FL3Key = string.Format("{0}-{1}-{2}", plantmodeldata[i].FL2, plantmodeldata[i].FL3, plantmodeldata[i].SlaveUnitDesc);
                if (!(plantModelFL2FL3.Contains(UniqueFL2FL3Key)))
                    plantModelFL2FL3.Add(UniqueFL2FL3Key, UniqueFL2FL3Key);
            }
            for (int j = 0; j < exceltask.Count(); j++)
            {
                RawDataFL2FL3Key = string.Format("{0}-{1}-{2}", exceltask[j].FL2, exceltask[j].FL3, exceltask[j].ECIL_Module);
                if (!(plantModelFL2FL3.Contains(RawDataFL2FL3Key)))
                {
                    plantModelFL2FL3.Add(RawDataFL2FL3Key, RawDataFL2FL3Key);
                    DataRow.DepartmentDesc = plantmodeldata[0].DepartmentDesc;
                    DataRow.LineDesc = plantmodeldata[0].LineDesc;

                    DataRow.LineId = plantmodeldata[0].LineId;
                    DataRow.FL1 = plantmodeldata[0].FL1;
                    DataRow.FL3 = exceltask[j].FL3;
                    DataRow.SlaveUnitDesc = exceltask[j].ECIL_Module;
                    plantModelDataNewModule.Add(DataRow);
                    // Check what do we do with this new modules list to add, new API to add them ?
                }
            }

            //if ((plantModelDataNewModule.Count()) == 0) // >
            //    message.Add("ManualMasterSelection");
            //else
            //    message.Add("Success");

            return plantModelDataNewModule;


        }


        public string CompareRawDataAndProficy(string _connectionString, bool moduleLevelComparision, string path, string sheet, int plId, int puId)
        {
            string errormessage = string.Empty;
            var rawDatataskslist = new List<ExcelTask>();
            var plantmodeldata = new List<PlantModel.PlantModelData>();
            //Revert Azure Bug Fix 588
            //var result = new List<PlantModel.ProficyDataSource>();
            ////Added for checking wether VM Id already exist or not
            //result = GetTaskListFromProductionLine(_connectionString, plId.ToString());
            string RawDataFL3;
            string RawDataModuleDesc;
            string ProficyFL3;
            string ProficyModuleDesc;


            if (moduleLevelComparision == true)
            {
                rawDatataskslist = ReadDatafFromExcelFile(path, sheet);
                plantmodeldata = GetModuleHierarchyInfo(_connectionString, puId);
                if (rawDatataskslist.Count > 0)
                {
                    if (plantmodeldata.Count > 0)
                    {
                        RawDataFL3 = rawDatataskslist[0].FL3;
                        RawDataModuleDesc = rawDatataskslist[0].ECIL_Module;
                        ProficyFL3 = plantmodeldata[0].FL3;
                        ProficyModuleDesc = plantmodeldata[0].SlaveUnitDesc;

                        if ((!(RawDataFL3.Equals(ProficyFL3))) || (!(RawDataModuleDesc.Equals(ProficyModuleDesc))))
                        {
                            errormessage = "No match found in Proficy for the Module-Level comparison. (Module Description and FL3 must be identical).";
                            return errormessage;
                        }
                    }
                    else
                    {
                        errormessage = "No match found in Proficy for the Module-Level comparison. (Module Description and FL3 must be identical).";
                        return errormessage;
                    }
                }


                //Revert Azure Bug Fix 588
                //for (int i = 0; i < rawDatataskslist.Count; i++)
                //{
                //    for (int j = 0; j < result.Count; j++)
                //    {

                //        if (rawDatataskslist[i].ECIL_VMID.Equals(result[j].VMId))
                //        {
                //            errormessage = "Non-Unique VM IDs were detected on the line in Proficy";
                //            return errormessage;
                //        }
                //    }
                //}

            }

            if (string.IsNullOrEmpty(errormessage))
                return null;
            else
                return errormessage;

        }


        public List<TaskEdit> TaskToUpdate(string _connectionString, string path, string sheet, bool lineLevelComparision, bool moduleLevelComparision, int plId, int puId)
        {
            var proficyDataSource = new List<PlantModel.ProficyDataSource>();
            var rawDatataskslist = new List<ExcelTask>();
            var exceltask = new ExcelTask();
            var TasksToUpdateList = new List<TaskEdit>();

            rawDatataskslist = ReadDatafFromExcelFile(path, sheet);
            proficyDataSource = ReadProficyData(_connectionString, lineLevelComparision, moduleLevelComparision, plId.ToString(), puId.ToString());


            for (int i = 0; i < rawDatataskslist.Count(); i++)
            {
                for (int j = 0; j < proficyDataSource.Count(); j++)
                {
                    var TempObj1 = new TaskEdit();
                    //Task found in Proficy , so mark task as Update status
                    if (rawDatataskslist[i].ECIL_VMID == proficyDataSource[j].VMId)
                    {
                        proficyDataSource[j].Status = UPDATE_TASK;
                        rawDatataskslist[i].Status = UPDATE_TASK;
                        TempObj1 = UpdateProficyFromRawData(proficyDataSource[j], rawDatataskslist[i]);

                        //if we identified some changes in raw data file, we will add to the list that will show to the user
                        if (TempObj1.Status == UPDATE_TASK)
                            TasksToUpdateList.Add(TempObj1);
                    }

                }
                //Task was not found in Proficy , so mark task as Add status
                if (rawDatataskslist[i].Status != UPDATE_TASK)
                {
                    var TempObj2 = new TaskEdit();
                    rawDatataskslist[i].Status = ADD_TASK;
                    TempObj2 = FillTaskObjectFromRawData(_connectionString, rawDatataskslist[i], lineLevelComparision, moduleLevelComparision, ADD_TASK, plId, puId);
                    TasksToUpdateList.Add(TempObj2);
                }
            }

            for (int i = 0; i < proficyDataSource.Count(); i++)
            {
                // Task present in Proficy but now in raw data file, so mark task as Obselete status
                if (proficyDataSource[i].Status != UPDATE_TASK)
                {
                    var TempObj3 = new TaskEdit();
                    proficyDataSource[i].Status = DELETE_TASK;
                    TempObj3 = FillTaskObjectFromProficyData(proficyDataSource[i], DELETE_TASK);
                    TasksToUpdateList.Add(TempObj3);
                }

            }
            return TasksToUpdateList;

        }


        public TaskEdit UpdateProficyFromRawData(PlantModel.ProficyDataSource proficyDataSourceObj, ExcelTask RawDataTaskObj)
        {
            var updatedTaskObj = new TaskEdit();

            // check this one - how to add the property for status and errormessage
            // if ((proficyDataSourceObj.SlaveUnitDesc != RawDataTaskObj.eCIL_Module1) && (proficyDataSourceObj.FL3 != RawDataTaskObj.FL3)) 
            //proficyDataSourceObj.errormessage = "A task cannot be transfered from one module to another.";

            updatedTaskObj.VarId = proficyDataSourceObj.VarId;
            updatedTaskObj.DepartmentId = proficyDataSourceObj.DeptId;
            updatedTaskObj.DepartmentDesc = proficyDataSourceObj.DepartmentDesc;
            updatedTaskObj.PLId = proficyDataSourceObj.LineId;
            updatedTaskObj.LineDesc = proficyDataSourceObj.LineDesc;
            updatedTaskObj.MasterUnitId = proficyDataSourceObj.MasterUnitId;
            updatedTaskObj.MasterUnitDesc = proficyDataSourceObj.MasterUnitDesc;
            updatedTaskObj.ProductionGroupId = proficyDataSourceObj.ProductionGroupId;
            updatedTaskObj.ProductionGroupDesc = proficyDataSourceObj.ProductionGroupDesc;
            updatedTaskObj.PrimaryQFactor = proficyDataSourceObj.PrimaryQFactor;
            updatedTaskObj.QFactorType = proficyDataSourceObj.QfactorType;

            updatedTaskObj.VarDesc = RawDataTaskObj.ECIL_TaskName;

            updatedTaskObj.FL1 = RawDataTaskObj.FL1;
            updatedTaskObj.FL2 = RawDataTaskObj.FL2;

            //FL3 Updates
            if (proficyDataSourceObj.FL3 != RawDataTaskObj.FL3)
            {
                updatedTaskObj.FL3 = "U:" + RawDataTaskObj.FL3;
                updatedTaskObj.Status = UPDATE_TASK;
            }
            else
            {
                updatedTaskObj.FL3 = proficyDataSourceObj.FL3;
            }

            //FL4 Upadtes
            if (proficyDataSourceObj.FL4 != RawDataTaskObj.FL4)
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.FL4))
                {
                    updatedTaskObj.ProductionGroupDesc = "eCIL";
                    updatedTaskObj.Status = UPDATE_TASK;
                }
                else
                {
                    updatedTaskObj.FL4 = "U:" + RawDataTaskObj.FL4;
                    updatedTaskObj.ProductionGroupDesc = "U:" + RawDataTaskObj.FL4;
                    updatedTaskObj.Status = UPDATE_TASK;
                }

            }
            else if (string.IsNullOrEmpty(RawDataTaskObj.FL4))
            {
                if (updatedTaskObj.ProductionGroupDesc == string.Empty)
                {
                    updatedTaskObj.ProductionGroupDesc = "U:" + "eCIL";
                    updatedTaskObj.Status = UPDATE_TASK;
                }
            }
            else
            {
                updatedTaskObj.FL4 = proficyDataSourceObj.FL4;
            }

            //check the task name
            if (proficyDataSourceObj.TaskDesc != RawDataTaskObj.ECIL_TaskName)
            {
                updatedTaskObj.VarDesc = "U:" + RawDataTaskObj.ECIL_TaskName;
                updatedTaskObj.Status = UPDATE_TASK;
            }
            else
            {
                updatedTaskObj.VarDesc = proficyDataSourceObj.TaskDesc;
            }
            //Check if user is trying to move a task from a Module to another one using VM

            if (proficyDataSourceObj.SlaveUnitDesc != RawDataTaskObj.ECIL_Module & proficyDataSourceObj.ModulefeatueVersion != RawDataTaskObj.ECIL_Module)
            {
                updatedTaskObj.SlaveUnitDesc = "U:" + RawDataTaskObj.ECIL_Module;
                updatedTaskObj.succes_failure = "A task cannot be transfered from one module to another.";
                updatedTaskObj.Status = UPDATE_TASK;
            }
            else
            {
                updatedTaskObj.SlaveUnitDesc = proficyDataSourceObj.SlaveUnitDesc;
            }

            if (proficyDataSourceObj.StartDate != RawDataTaskObj.ECIL_FirstEffectiveDate)
            {
                updatedTaskObj.StartDate = "U:" + RawDataTaskObj.ECIL_FirstEffectiveDate;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.StartDate = proficyDataSourceObj.StartDate;

            if (proficyDataSourceObj.LongTaskName != RawDataTaskObj.ECIL_LongTaskName)
            {
                updatedTaskObj.LongTaskName = "U:" + RawDataTaskObj.ECIL_LongTaskName;
                updatedTaskObj.Status = UPDATE_TASK;
            }
            else
                updatedTaskObj.LongTaskName = proficyDataSourceObj.LongTaskName;

            if (proficyDataSourceObj.TaskId != RawDataTaskObj.ECIL_TaskId)
            {
                updatedTaskObj.TaskId = "U:" + RawDataTaskObj.ECIL_TaskId;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.TaskId = proficyDataSourceObj.TaskId;

            if (proficyDataSourceObj.TaskAction != RawDataTaskObj.ECIL_Task_Action)
            {
                updatedTaskObj.TaskAction = "U:" + RawDataTaskObj.ECIL_Task_Action;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.TaskAction = proficyDataSourceObj.TaskAction;

            string tasktype = FormatTaskType(RawDataTaskObj.ECIL_TaskType);
            if (proficyDataSourceObj.TaskType != tasktype)
            {
                updatedTaskObj.TaskType = "U:" + tasktype;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.TaskType = proficyDataSourceObj.TaskType;

            if (proficyDataSourceObj.NbrItems != RawDataTaskObj.ECIL_NbrItems)
            {
                updatedTaskObj.NbrItems = "U:" + RawDataTaskObj.ECIL_NbrItems;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.NbrItems = proficyDataSourceObj.NbrItems;

            if (proficyDataSourceObj.Duration != RawDataTaskObj.ECIL_Duration)
            {
                updatedTaskObj.Duration = "U:" + RawDataTaskObj.ECIL_Duration;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.Duration = proficyDataSourceObj.Duration;

            if (proficyDataSourceObj.NbrPeople != RawDataTaskObj.ECIL_NbrPeople)
            {
                updatedTaskObj.NbrPeople = "U:" + RawDataTaskObj.ECIL_NbrPeople;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.NbrPeople = proficyDataSourceObj.NbrPeople;

            if (proficyDataSourceObj.Criteria != RawDataTaskObj.ECIL_Criteria)
            {
                updatedTaskObj.Criteria = "U:" + RawDataTaskObj.ECIL_Criteria;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.Criteria = proficyDataSourceObj.Criteria;

            if (proficyDataSourceObj.Hazards != RawDataTaskObj.ECIL_Hazard)
            {
                updatedTaskObj.Hazards = "U:" + RawDataTaskObj.ECIL_Hazard;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.Hazards = proficyDataSourceObj.Hazards;

            if (proficyDataSourceObj.Method != RawDataTaskObj.ECIL_Method)
            {
                updatedTaskObj.Method = "U:" + RawDataTaskObj.ECIL_Method;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.Method = proficyDataSourceObj.Method;

            if (proficyDataSourceObj.PPE != RawDataTaskObj.ECIL_PPE)
            {
                updatedTaskObj.PPE = "U:" + RawDataTaskObj.ECIL_PPE;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.PPE = proficyDataSourceObj.PPE;

            if (proficyDataSourceObj.Tools != RawDataTaskObj.ECIL_Tools)
            {
                updatedTaskObj.Tools = "U:" + RawDataTaskObj.ECIL_Tools;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.Tools = proficyDataSourceObj.Tools;

            if (proficyDataSourceObj.Lubricant != RawDataTaskObj.ECIL_Lubrication)
            {
                updatedTaskObj.Lubricant = "U:" + RawDataTaskObj.ECIL_Lubrication;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.Lubricant = proficyDataSourceObj.Lubricant;


            if (proficyDataSourceObj.DocumentLinkTitle != RawDataTaskObj.ECIL_DocumentDesc1)
            {
                updatedTaskObj.DocumentLinkTitle = "U:" + RawDataTaskObj.ECIL_DocumentDesc1;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.DocumentLinkTitle = proficyDataSourceObj.DocumentLinkTitle;

            if (proficyDataSourceObj.DocumentLinkPath != RawDataTaskObj.ECIL_DocumentLink1)
            {
                updatedTaskObj.DocumentLinkPath = "U:" + RawDataTaskObj.ECIL_DocumentLink1;
                updatedTaskObj.Status = UPDATE_TASK;
            }

            else
                updatedTaskObj.DocumentLinkPath = proficyDataSourceObj.DocumentLinkPath;

            Boolean HSEFlag = RawDataTaskObj.ECIL_HSEFlag == 1 ? true : false;
            if (proficyDataSourceObj.HSEFlag != HSEFlag)
            {
                updatedTaskObj.IsHSE = HSEFlag;
                updatedTaskObj.HseFlag = HSEFlag;
                updatedTaskObj.IsChangedHSE = true;
                updatedTaskObj.Status = UPDATE_TASK;

            }

            else
            {
                //IsHSE1 it is used to compare the data and to save the data in GBDB
                //HSEFlag - Data binded in UI
                updatedTaskObj.IsHSE = proficyDataSourceObj.HSEFlag;
                updatedTaskObj.HseFlag = Convert.ToBoolean(proficyDataSourceObj.HSEFlag);
            }



            string TaskFrequency = FindTaskFrequency(RawDataTaskObj.ECIL_Active, RawDataTaskObj.ECIL_Window, RawDataTaskObj.ECIL_Frequency, RawDataTaskObj.ECIL_FreqType);
            // task frequency logic
            // temporary fix for scenario when from old eCIL Taskfrequency is NULL.
            if (proficyDataSourceObj.TaskFrequency.Equals(string.Empty))
            {
                // set the value for active as false. This will force the user to schedule the task and make it active.
                proficyDataSourceObj.TaskFrequency = "0000000";
            }
            if (proficyDataSourceObj.TaskFrequency != TaskFrequency)
            {
                updatedTaskObj.TaskFreq = "U:" + TaskFrequency;
                updatedTaskObj.Status = UPDATE_TASK;
                if (proficyDataSourceObj.TaskFrequency.Substring(0, 1) != Convert.ToString(RawDataTaskObj.ECIL_Active))
                {
                    updatedTaskObj.Active = Convert.ToString(RawDataTaskObj.ECIL_Active) == "1" ? true : false;
                    updatedTaskObj.IsChangedActive = true;
                }
                else
                {
                    updatedTaskObj.Active = Convert.ToString(RawDataTaskObj.ECIL_Active) == "1" ? true : false;
                    updatedTaskObj.IsChangedActive = false;
                }
                try
                {
                    int tempFreq = Convert.ToInt32(proficyDataSourceObj.TaskFrequency.Substring(1, 3));
                    int rawDataFreq = Convert.ToInt32(TaskFrequency.Substring(1, 3));
                    if (tempFreq != rawDataFreq)
                    {
                        if (rawDataFreq == 0)
                        {
                            updatedTaskObj.Frequency = "U:" + string.Empty;
                            updatedTaskObj.FrequencyType = "U:" + "Shiftly";

                        }
                        else if (rawDataFreq == 1)
                        {
                            updatedTaskObj.Frequency = "U:" + "1";
                            updatedTaskObj.FrequencyType = "U:" + "Daily";
                        }
                        else if (rawDataFreq >= 2 && rawDataFreq <= 365)
                        {
                            updatedTaskObj.Frequency = "U:" + rawDataFreq.ToString();
                            updatedTaskObj.FrequencyType = "U:" + "Multi-Day";
                        }
                        else if (rawDataFreq >= 366 && rawDataFreq <= 999)
                        {
                            updatedTaskObj.Frequency = "U:" + (rawDataFreq - 365).ToString();
                            updatedTaskObj.FrequencyType = "U:" + "Minutes";
                        }
                    }
                    else
                    {
                        if (tempFreq == 0)
                        {
                            updatedTaskObj.Frequency = string.Empty;
                            updatedTaskObj.FrequencyType = "Shiftly";

                        }
                        else if (tempFreq == 1)
                        {
                            updatedTaskObj.Frequency = "1";
                            updatedTaskObj.FrequencyType = "Daily";
                        }
                        else if (tempFreq >= 2 && tempFreq <= 365)
                        {
                            updatedTaskObj.Frequency = tempFreq.ToString();
                            updatedTaskObj.FrequencyType = "Multi-Day";
                        }
                        else if (tempFreq >= 366 && tempFreq <= 999)
                        {
                            updatedTaskObj.Frequency = (tempFreq - 365).ToString();
                            updatedTaskObj.FrequencyType = "Minutes";
                        }
                    }

                    if (Convert.ToInt32(proficyDataSourceObj.TaskFrequency.Substring(4, 3)).ToString() != Convert.ToString(RawDataTaskObj.ECIL_Window))
                    {
                        updatedTaskObj.Window = "U:" + Convert.ToString(RawDataTaskObj.ECIL_Window);
                    }
                    else
                    {
                        updatedTaskObj.Window = Convert.ToInt32(proficyDataSourceObj.TaskFrequency.Substring(4, 3)).ToString();
                    }


                }
                catch
                {
                    updatedTaskObj.Frequency = "U:" + string.Empty;
                    updatedTaskObj.FrequencyType = "U:" + string.Empty;
                    updatedTaskObj.Window = "U:" + "0";
                }
            }

            else
            {
                updatedTaskObj.TaskFreq = proficyDataSourceObj.TaskFrequency;
                updatedTaskObj.Active = proficyDataSourceObj.TaskFrequency.Substring(0, 1) == "1" ? true : false;
                try
                {
                    int tempFreq = Convert.ToInt32(proficyDataSourceObj.TaskFrequency.Substring(1, 3));
                    if (tempFreq == 0)
                    {
                        updatedTaskObj.Frequency = string.Empty;
                        updatedTaskObj.FrequencyType = "Shiftly";
                    }
                    else if (tempFreq == 1)
                    {
                        updatedTaskObj.Frequency = "1";
                        updatedTaskObj.FrequencyType = "Daily";
                    }
                    else if (tempFreq >= 2 && tempFreq <= 365)
                    {
                        updatedTaskObj.Frequency = tempFreq.ToString();
                        updatedTaskObj.FrequencyType = "Multi-Day";
                    }
                    else if (tempFreq >= 366 && tempFreq <= 999)
                    {
                        updatedTaskObj.Frequency = (tempFreq - 365).ToString();
                        updatedTaskObj.FrequencyType = "Minutes";
                    }

                    updatedTaskObj.Window = Convert.ToInt32(proficyDataSourceObj.TaskFrequency.Substring(4, 3)).ToString();

                }
                catch
                {
                    updatedTaskObj.Frequency = string.Empty;
                    updatedTaskObj.FrequencyType = string.Empty;
                    updatedTaskObj.Window = "0";
                }
            }

            //Schedular changes - based on Autopostpone value, FIxed Frequency can have value equals with 0, 1 or 2
            string tempFixedFrequency = string.Empty;

            if ((RawDataTaskObj.ECIL_FixedFreq == "0" || RawDataTaskObj.ECIL_FixedFreq == "false") && RawDataTaskObj.ECIL_Autopostpone == false)
                tempFixedFrequency = "0";

            else if ((RawDataTaskObj.ECIL_FixedFreq == "1" || RawDataTaskObj.ECIL_FixedFreq == "true") && RawDataTaskObj.ECIL_Autopostpone == false)
                tempFixedFrequency = "1";

            else if ((RawDataTaskObj.ECIL_FixedFreq == "0" || RawDataTaskObj.ECIL_FixedFreq == "false") && RawDataTaskObj.ECIL_Autopostpone == true)
                tempFixedFrequency = "2";

            if (proficyDataSourceObj.FixedFrequency != tempFixedFrequency)
            {

                updatedTaskObj.FixedFrequency = Convert.ToBoolean(Convert.ToInt32(RawDataTaskObj.ECIL_FixedFreq));
                updatedTaskObj.AutoPostpone = Convert.ToBoolean(Convert.ToInt32(RawDataTaskObj.ECIL_Autopostpone));
                //if (!(proficyDataSourceObj.FixedFrequency != "" && updatedTaskObj.FixedFrequency != false))
                //{
                //    updatedTaskObj.Status = UPDATE_TASK;
                //    updatedTaskObj.IsChangedFixedFrequency = true;
                //    updatedTaskObj.IsChangedAutopostponed = true;
                //}
                if ((proficyDataSourceObj.FixedFrequency == "") && (updatedTaskObj.FixedFrequency == false) && ((RawDataTaskObj.ECIL_FreqType == SHIFTLY) || (RawDataTaskObj.ECIL_FreqType == DAILY)))
                {
                    updatedTaskObj.IsChangedFixedFrequency = false;
                    updatedTaskObj.IsChangedAutopostponed = false;
                }
                else
                {
                    updatedTaskObj.Status = UPDATE_TASK;
                    updatedTaskObj.IsChangedFixedFrequency = true;
                    updatedTaskObj.IsChangedAutopostponed = true;

                }
            }
            else
                updatedTaskObj.FixedFrequency = proficyDataSourceObj.FixedFrequency == "1" ? true : false;


            if (proficyDataSourceObj.ShiftOffset != RawDataTaskObj.ECIL_ShiftOffset)
            {
                //updatedTaskObj.ShiftOffset1 = "U:" + RawDataTaskObj.eCIL_ShiftOffset1.ToString();
                updatedTaskObj.ShiftOffset = RawDataTaskObj.ECIL_ShiftOffset;
                updatedTaskObj.IsChangedShiftOffset = true;
                updatedTaskObj.Status = UPDATE_TASK;
            }
            else
                updatedTaskObj.ShiftOffset = proficyDataSourceObj.ShiftOffset;


            if (proficyDataSourceObj.TestTime != RawDataTaskObj.ECIL_TestTime)
            {
                updatedTaskObj.Status = UPDATE_TASK;
                updatedTaskObj.TestTime = "U:" + RawDataTaskObj.ECIL_TestTime;
            }

            else
                updatedTaskObj.TestTime = proficyDataSourceObj.TestTime;

            if (proficyDataSourceObj.VMId != RawDataTaskObj.ECIL_VMID)
            {
                updatedTaskObj.Status = UPDATE_TASK;
                updatedTaskObj.VMId = "U:" + RawDataTaskObj.ECIL_VMID;
            }

            else
                updatedTaskObj.VMId = proficyDataSourceObj.VMId;


            if (proficyDataSourceObj.TaskLocation != RawDataTaskObj.ECIL_TaskLocation)
            {
                updatedTaskObj.Status = UPDATE_TASK;
                updatedTaskObj.TaskLocation = "U:" + RawDataTaskObj.ECIL_TaskLocation;
            }

            else
                updatedTaskObj.TaskLocation = proficyDataSourceObj.TaskLocation;


            if (proficyDataSourceObj.ScheduleScope != RawDataTaskObj.ECIL_ScheduleScope)
            {
                updatedTaskObj.Status = UPDATE_TASK;
                updatedTaskObj.ScheduleScope = "U:" + RawDataTaskObj.ECIL_ScheduleScope;
            }

            else
                updatedTaskObj.ScheduleScope = proficyDataSourceObj.ScheduleScope;


            // Commented below as Line Version and Module feature version properties of RawdataTaskObj is Null
            //color coding doesn't affect Line Version & Module Feature Version
            //updatedTaskObj.LineVersion = Convert.ToString(RawDataTaskObj.ECIL_LineVersion);
            //updatedTaskObj.ModuleFeatureVersion = Convert.ToString(RawDataTaskObj.ECIL_ModuleFeatureVersion);

            updatedTaskObj.LineVersion = RawDataTaskObj.ECIL_LineVersion;
            updatedTaskObj.ModuleFeatureVersion = RawDataTaskObj.ECIL_ModuleFeatureVersion;


            return updatedTaskObj;
        }

        public TaskEdit FillTaskObjectFromRawData(String _connectionString, ExcelTask RawDataTaskObj, bool lineLevelCOmparision, bool moduleLevelComparision, string status, int plId, int puId)
        {

            var updatedTaskObj = new TaskEdit();

            var tempObj = new PlantModel.PlantModelData();
            tempObj = SetPlantModelInfo(_connectionString, RawDataTaskObj, lineLevelCOmparision, moduleLevelComparision, plId, puId);


            //updatedTaskObj.VarId1 = tempObj.VarId; - dont have Var if for tempObj
            //updatedTaskObj.DepartmentId1 = tempObj.DeptId;
            updatedTaskObj.DepartmentDesc = tempObj.DepartmentDesc;
            updatedTaskObj.LineDesc = tempObj.LineDesc;
            //updatedTaskObj.LineId = tempObj.LineId; - dont have line id for updatedTaskObj
            updatedTaskObj.MasterUnitDesc = tempObj.MasterUnitDesc;
            updatedTaskObj.MasterUnitId = tempObj.MasterUnitId;
            updatedTaskObj.SlaveUnitId = tempObj.SlaveUnitId;
            updatedTaskObj.SlaveUnitDesc = tempObj.SlaveUnitDesc;
            updatedTaskObj.ProductionGroupDesc = tempObj.ProductionGroupDesc;
            //updatedTaskObj.ProductionGroupId1 = tempObj.ProductionGroupId; - ProductionGroupId does not exsists in tempObj
            updatedTaskObj.VarDesc = RawDataTaskObj.ECIL_TaskName; // check this
            updatedTaskObj.FL1 = tempObj.FL1;
            updatedTaskObj.FL2 = tempObj.FL2;
            updatedTaskObj.FL3 = tempObj.FL3;
            updatedTaskObj.FL4 = tempObj.FL4;
            // updatedTaskObj.QFactorType1 = we dont have QFactorType1 and primaryQfactor from raw data file 


            if (!((RawDataTaskObj.ECIL_FirstEffectiveDate).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_FirstEffectiveDate))
                    updatedTaskObj.StartDate = string.Empty;
                else
                    updatedTaskObj.StartDate = RawDataTaskObj.ECIL_FirstEffectiveDate;
            }
            else
                updatedTaskObj.StartDate = string.Empty; ;

            if (!((RawDataTaskObj.ECIL_LongTaskName).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_LongTaskName))
                    updatedTaskObj.LongTaskName = string.Empty;
                else
                    updatedTaskObj.LongTaskName = RawDataTaskObj.ECIL_LongTaskName;
            }
            else
                updatedTaskObj.LongTaskName = string.Empty;


            if (!((RawDataTaskObj.ECIL_TaskId).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.eCIL_TaskId))
                    updatedTaskObj.TaskId = string.Empty;
                else
                    updatedTaskObj.TaskId = RawDataTaskObj.ECIL_TaskId;
            }
            else
                updatedTaskObj.TaskId = string.Empty;


            if (!((RawDataTaskObj.ECIL_Task_Action).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_Task_Action))
                    updatedTaskObj.TaskAction = string.Empty;
                else
                    updatedTaskObj.TaskAction = RawDataTaskObj.ECIL_Task_Action;
            }
            else
                updatedTaskObj.TaskAction = string.Empty;


            if (!((RawDataTaskObj.ECIL_TaskType).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_TaskType))
                    updatedTaskObj.TaskType = string.Empty;
                else
                    updatedTaskObj.TaskType = FormatTaskType(RawDataTaskObj.ECIL_TaskType);
            }
            else
                updatedTaskObj.TaskType = string.Empty;


            if (!((RawDataTaskObj.ECIL_NbrItems).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_NbrItems))
                    updatedTaskObj.NbrItems = string.Empty;
                else
                    updatedTaskObj.NbrItems = RawDataTaskObj.ECIL_NbrItems;
            }
            else
                updatedTaskObj.NbrItems = string.Empty;


            if (!((RawDataTaskObj.ECIL_Duration).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_Duration))
                    updatedTaskObj.Duration = string.Empty;
                else
                    updatedTaskObj.Duration = RawDataTaskObj.ECIL_Duration;
            }
            else
                updatedTaskObj.Duration = string.Empty;


            if (!((RawDataTaskObj.ECIL_NbrPeople).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_NbrPeople))
                    updatedTaskObj.NbrPeople = string.Empty;
                else
                    updatedTaskObj.NbrPeople = RawDataTaskObj.ECIL_NbrPeople;
            }
            else
                updatedTaskObj.NbrPeople = string.Empty;


            if (!((RawDataTaskObj.ECIL_Criteria).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_Criteria))
                    updatedTaskObj.Criteria = string.Empty;
                else
                    updatedTaskObj.Criteria = RawDataTaskObj.ECIL_Criteria;
            }
            else
                updatedTaskObj.Criteria = string.Empty;


            if (!((RawDataTaskObj.ECIL_Hazard).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_Hazard))
                    updatedTaskObj.Hazards = string.Empty;
                else
                    updatedTaskObj.Hazards = RawDataTaskObj.ECIL_Hazard;
            }
            else
                updatedTaskObj.Hazards = string.Empty;


            if (!((RawDataTaskObj.ECIL_Method).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_Method))
                    updatedTaskObj.Method = string.Empty;
                else
                    updatedTaskObj.Method = RawDataTaskObj.ECIL_Method;
            }
            else
                updatedTaskObj.Method = string.Empty;


            if (!((RawDataTaskObj.ECIL_PPE).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_PPE))
                    updatedTaskObj.PPE = string.Empty;
                else
                    updatedTaskObj.PPE = RawDataTaskObj.ECIL_PPE;
            }
            else
                updatedTaskObj.PPE = string.Empty;


            if (!((RawDataTaskObj.ECIL_Tools).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_Tools))
                    updatedTaskObj.Tools = string.Empty;
                else
                    updatedTaskObj.Tools = RawDataTaskObj.ECIL_Tools;
            }
            else
                updatedTaskObj.Tools = string.Empty;


            if (!((RawDataTaskObj.ECIL_Lubrication).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_Lubrication))
                    updatedTaskObj.Lubricant = string.Empty;
                else
                    updatedTaskObj.Lubricant = RawDataTaskObj.ECIL_Lubrication;
            }
            else
                updatedTaskObj.Lubricant = string.Empty;


            if (!((RawDataTaskObj.ECIL_DocumentDesc1).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_DocumentDesc1))
                    updatedTaskObj.DocumentLinkTitle = string.Empty;
                else
                    updatedTaskObj.DocumentLinkTitle = RawDataTaskObj.ECIL_DocumentDesc1;
            }
            else
                updatedTaskObj.DocumentLinkTitle = string.Empty;


            if (!((RawDataTaskObj.ECIL_HSEFlag).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_HSEFlag.ToString()))
                    updatedTaskObj.IsHSE = false;
                else
                    updatedTaskObj.IsHSE = Convert.ToBoolean(RawDataTaskObj.ECIL_HSEFlag);
            }
            else
                updatedTaskObj.IsHSE = false;

            updatedTaskObj.Frequency = Convert.ToString(RawDataTaskObj.ECIL_Frequency);
            updatedTaskObj.Window = Convert.ToString(RawDataTaskObj.ECIL_Window);

            string TaskFrequency;
            if (!(string.IsNullOrEmpty(RawDataTaskObj.eCIL_FreqType)))
            {
                TaskFrequency = FindTaskFrequency(RawDataTaskObj.ECIL_Active, RawDataTaskObj.ECIL_Window, RawDataTaskObj.ECIL_Frequency, RawDataTaskObj.ECIL_FreqType);
                if (RawDataTaskObj.ECIL_FreqType == MINUTES)
                {
                    updatedTaskObj.ShiftOffset = RawDataTaskObj.ECIL_ShiftOffset;
                }

            }
            else
                TaskFrequency = FindTaskFrequency(RawDataTaskObj.ECIL_Active, RawDataTaskObj.ECIL_Window, RawDataTaskObj.ECIL_Frequency, null);

            if (!((TaskFrequency).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(TaskFrequency))
                    updatedTaskObj.TaskFreq = string.Empty;
                else
                    updatedTaskObj.TaskFreq = TaskFrequency;
            }
            else
                updatedTaskObj.TaskFreq = string.Empty;

            if (!((RawDataTaskObj.ECIL_FreqType).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_FreqType))
                    updatedTaskObj.FrequencyType = string.Empty;
                else
                    updatedTaskObj.FrequencyType = RawDataTaskObj.ECIL_FreqType;
            }
            else
                updatedTaskObj.FrequencyType = string.Empty;

            if (!((RawDataTaskObj.ECIL_Active).Equals(DBNull.Value)))
            {
                if (!(string.IsNullOrEmpty(RawDataTaskObj.ECIL_FixedFreq.ToString())))
                {
                    if ((RawDataTaskObj.ECIL_Active).Equals(1))
                        updatedTaskObj.Active = true;
                    else
                        updatedTaskObj.Active = false;
                }
            }

            if (!((RawDataTaskObj.ECIL_FixedFreq).Equals(DBNull.Value)))
            {
                if (!(string.IsNullOrEmpty(RawDataTaskObj.ECIL_FixedFreq.ToString())))
                {
                    if (RawDataTaskObj.ECIL_FixedFreq.Equals("1"))
                        updatedTaskObj.FixedFrequency = true;
                    else
                        updatedTaskObj.FixedFrequency = false;
                }
            }


            //Scheduler changes 
            if (!((RawDataTaskObj.ECIL_Autopostpone).Equals(DBNull.Value)))
            {
                updatedTaskObj.AutoPostpone = Convert.ToBoolean(RawDataTaskObj.ECIL_Autopostpone);
            }


            if (!(RawDataTaskObj.ECIL_TestTime.Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_TestTime))
                    updatedTaskObj.TestTime = string.Empty;
                else
                    updatedTaskObj.TestTime = RawDataTaskObj.ECIL_TestTime;
            }
            else
                updatedTaskObj.TestTime = RawDataTaskObj.ECIL_TestTime;


            if (!((RawDataTaskObj.ECIL_VMID).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_VMID))
                    updatedTaskObj.VMId = string.Empty;
                else
                    updatedTaskObj.VMId = RawDataTaskObj.ECIL_VMID;
            }
            else
                updatedTaskObj.VMId = RawDataTaskObj.ECIL_VMID;


            if (!((RawDataTaskObj.ECIL_TaskLocation).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_TaskLocation))
                    updatedTaskObj.TaskLocation = string.Empty;
                else
                    updatedTaskObj.TaskLocation = RawDataTaskObj.ECIL_TaskLocation;
            }
            else
                updatedTaskObj.TaskLocation = RawDataTaskObj.ECIL_TaskLocation;



            if (!((RawDataTaskObj.ECIL_DocumentLink1).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_DocumentLink1))
                    updatedTaskObj.DocumentLinkPath = string.Empty;
                else
                    updatedTaskObj.DocumentLinkPath = RawDataTaskObj.ECIL_DocumentLink1;
            }
            else
                updatedTaskObj.DocumentLinkPath = string.Empty;

            if (!((RawDataTaskObj.ECIL_HSEFlag).Equals(DBNull.Value)))
            {
                if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_HSEFlag.ToString()))
                    updatedTaskObj.IsHSE = false;
                else
                    updatedTaskObj.IsHSE = Convert.ToBoolean(RawDataTaskObj.ECIL_HSEFlag);
            }
            else
                updatedTaskObj.IsHSE = false;

            updatedTaskObj.Status = ADD_TASK;

            return updatedTaskObj;
        }

        public TaskEdit FillTaskObjectFromProficyData(PlantModel.ProficyDataSource proficyDataSourceObj, string status)
        {

            var updatedTaskObj = new TaskEdit();

            updatedTaskObj.VarId = proficyDataSourceObj.VarId;
            updatedTaskObj.DepartmentId = proficyDataSourceObj.DeptId;
            updatedTaskObj.DepartmentDesc = proficyDataSourceObj.DepartmentDesc;
            updatedTaskObj.PLId = proficyDataSourceObj.LineId;
            updatedTaskObj.LineDesc = proficyDataSourceObj.LineDesc;
            updatedTaskObj.MasterUnitId = proficyDataSourceObj.MasterUnitId;
            updatedTaskObj.MasterUnitDesc = proficyDataSourceObj.MasterUnitDesc;
            updatedTaskObj.ProductionGroupId = proficyDataSourceObj.ProductionGroupId;
            updatedTaskObj.ProductionGroupDesc = proficyDataSourceObj.ProductionGroupDesc;
            updatedTaskObj.PrimaryQFactor = proficyDataSourceObj.PrimaryQFactor;
            updatedTaskObj.QFactorType = proficyDataSourceObj.QfactorType;


            updatedTaskObj.VarDesc = proficyDataSourceObj.TaskDesc;
            updatedTaskObj.SlaveUnitDesc = proficyDataSourceObj.SlaveUnitDesc;
            updatedTaskObj.FL1 = proficyDataSourceObj.FL1;
            updatedTaskObj.FL2 = proficyDataSourceObj.FL2;
            updatedTaskObj.FL3 = proficyDataSourceObj.FL3;
            updatedTaskObj.FL4 = proficyDataSourceObj.FL4;


            if (!((proficyDataSourceObj.StartDate).Equals(DBNull.Value)))
                updatedTaskObj.StartDate = proficyDataSourceObj.StartDate;
            else
                updatedTaskObj.StartDate = string.Empty;


            if (!((proficyDataSourceObj.LongTaskName).Equals(DBNull.Value)))
                updatedTaskObj.LongTaskName = proficyDataSourceObj.LongTaskName;
            else
                updatedTaskObj.LongTaskName = string.Empty;


            if (!((proficyDataSourceObj.TaskId).Equals(DBNull.Value)))
                updatedTaskObj.TaskId = proficyDataSourceObj.TaskId;
            else
                updatedTaskObj.TaskId = string.Empty;


            if (!((proficyDataSourceObj.TaskAction).Equals(DBNull.Value)))
                updatedTaskObj.TaskAction = proficyDataSourceObj.TaskAction;
            else
                updatedTaskObj.TaskAction = string.Empty;


            if (!((proficyDataSourceObj.TaskType).Equals(DBNull.Value)))
                updatedTaskObj.TaskType = proficyDataSourceObj.TaskType;
            else
                updatedTaskObj.TaskType = string.Empty;


            if (!((proficyDataSourceObj.NbrItems).Equals(DBNull.Value)))
                updatedTaskObj.NbrItems = proficyDataSourceObj.NbrItems;
            else
                updatedTaskObj.NbrItems = string.Empty;


            if (!((proficyDataSourceObj.NbrPeople).Equals(DBNull.Value)))
                updatedTaskObj.NbrPeople = proficyDataSourceObj.NbrPeople;
            else
                updatedTaskObj.NbrPeople = string.Empty;


            if (!((proficyDataSourceObj.Duration).Equals(DBNull.Value)))
                updatedTaskObj.Duration = proficyDataSourceObj.Duration;
            else
                updatedTaskObj.Duration = string.Empty;

            if (!((proficyDataSourceObj.Criteria).Equals(DBNull.Value)))
                updatedTaskObj.Criteria = proficyDataSourceObj.Criteria;
            else
                updatedTaskObj.Criteria = string.Empty;

            if (!((proficyDataSourceObj.Hazards).Equals(DBNull.Value)))
                updatedTaskObj.Hazards = proficyDataSourceObj.Hazards;
            else
                updatedTaskObj.Hazards = string.Empty;

            if (!((proficyDataSourceObj.Method).Equals(DBNull.Value)))
                updatedTaskObj.Method = proficyDataSourceObj.Method;
            else
                updatedTaskObj.Method = string.Empty;

            if (!((proficyDataSourceObj.PPE).Equals(DBNull.Value)))
                updatedTaskObj.PPE = proficyDataSourceObj.PPE;
            else
                updatedTaskObj.PPE = string.Empty;

            if (!((proficyDataSourceObj.Tools).Equals(DBNull.Value)))
                updatedTaskObj.Tools = proficyDataSourceObj.Tools;
            else
                updatedTaskObj.Tools = string.Empty;


            if (!((proficyDataSourceObj.Lubricant).Equals(DBNull.Value)))
                updatedTaskObj.Lubricant = proficyDataSourceObj.Lubricant;
            else
                updatedTaskObj.Lubricant = string.Empty;


            if (!((proficyDataSourceObj.DocumentLinkTitle).Equals(DBNull.Value)))
                updatedTaskObj.DocumentLinkTitle = proficyDataSourceObj.DocumentLinkTitle;
            else
                updatedTaskObj.DocumentLinkTitle = string.Empty;


            if (!((proficyDataSourceObj.DocumentLinkPath).Equals(DBNull.Value)))
                updatedTaskObj.DocumentLinkPath = proficyDataSourceObj.DocumentLinkTitle;
            else
                updatedTaskObj.DocumentLinkPath = string.Empty;


            if (!((proficyDataSourceObj.HSEFlag).Equals(DBNull.Value)))
                updatedTaskObj.IsHSE = proficyDataSourceObj.HSEFlag;
            else
                updatedTaskObj.IsHSE = false;


            if (!((proficyDataSourceObj.FixedFrequency).Equals(DBNull.Value)))
            {
                switch (proficyDataSourceObj.FixedFrequency)
                {
                    case "0":
                        updatedTaskObj.FixedFrequency = false;
                        updatedTaskObj.AutoPostpone = false;
                        break;

                    case "1":
                        updatedTaskObj.FixedFrequency = true;
                        updatedTaskObj.AutoPostpone = false;
                        break;

                    case "2":
                        updatedTaskObj.FixedFrequency = false;
                        updatedTaskObj.AutoPostpone = true;
                        break;
                }
            }

            if (!((proficyDataSourceObj.TaskFrequency).Equals(DBNull.Value)))
            {
                updatedTaskObj.TaskFreq = proficyDataSourceObj.TaskFrequency;
                try
                {
                    updatedTaskObj.Active = proficyDataSourceObj.TaskFrequency.Substring(0, 1) == "1" ? true : false;
                }
                catch 
                {
                    updatedTaskObj.Active = false;
                }
                try
                {
                    int tempFreq = Convert.ToInt32(proficyDataSourceObj.TaskFrequency.Substring(1, 3));
                    if (tempFreq == 0)
                    {
                        updatedTaskObj.Frequency = string.Empty;
                        updatedTaskObj.FrequencyType = "Shiftly";
                    }
                    else if (tempFreq == 1)
                    {
                        updatedTaskObj.Frequency = "1";
                        updatedTaskObj.FrequencyType = "Daily";
                    }
                    else if (tempFreq >= 2 && tempFreq <= 365)
                    {
                        updatedTaskObj.Frequency = tempFreq.ToString();
                        updatedTaskObj.FrequencyType = "Multi-Day";
                    }
                    else if (tempFreq >= 366 && tempFreq <= 999)
                    {
                        updatedTaskObj.Frequency = (tempFreq - 365).ToString();
                        updatedTaskObj.FrequencyType = "Minutes";
                    }
                }
                catch
                {
                    updatedTaskObj.Frequency = string.Empty;
                    updatedTaskObj.FrequencyType = "Undefined";
                }
                try
                {
                    updatedTaskObj.Window = Convert.ToInt32(proficyDataSourceObj.TaskFrequency.Substring(4, 3)).ToString();
                }
                catch
                {
                    updatedTaskObj.Window = Convert.ToString(0);
                }
            }

            else
            {
                updatedTaskObj.TaskFreq = string.Empty;
                updatedTaskObj.Frequency = string.Empty;
                updatedTaskObj.FrequencyType = string.Empty;
                updatedTaskObj.Window = "0";
            }



            if (!((proficyDataSourceObj.ShiftOffset).Equals(DBNull.Value)))
                updatedTaskObj.ShiftOffset = proficyDataSourceObj.ShiftOffset;
            else
                updatedTaskObj.ShiftOffset = 0;


            if (!((proficyDataSourceObj.TestTime).Equals(DBNull.Value)))
                updatedTaskObj.TestTime = proficyDataSourceObj.TestTime;
            else
                updatedTaskObj.TestTime = string.Empty;


            if (!((proficyDataSourceObj.VMId).Equals(DBNull.Value)))
                updatedTaskObj.VMId = proficyDataSourceObj.VMId;
            else
                updatedTaskObj.VMId = string.Empty;


            if (!((proficyDataSourceObj.TaskLocation).Equals(DBNull.Value)))
                updatedTaskObj.TaskLocation = proficyDataSourceObj.TaskLocation;
            else
                updatedTaskObj.TaskLocation = string.Empty;


            if (!((proficyDataSourceObj.DocumentLinkPath).Equals(DBNull.Value)))
                updatedTaskObj.DocumentLinkPath = proficyDataSourceObj.DocumentLinkPath;
            else
                updatedTaskObj.DocumentLinkPath = string.Empty;


            if (!((proficyDataSourceObj.ScheduleScope).Equals(DBNull.Value)))
                updatedTaskObj.ScheduleScope = proficyDataSourceObj.ScheduleScope;
            else
                updatedTaskObj.ScheduleScope = string.Empty;

            if (!((proficyDataSourceObj.LineVersion).Equals(DBNull.Value)))
                updatedTaskObj.LineVersion = proficyDataSourceObj.LineVersion;
            else
                updatedTaskObj.LineVersion = string.Empty;


            if (!((proficyDataSourceObj.ModulefeatueVersion).Equals(DBNull.Value)))
                updatedTaskObj.ModuleFeatureVersion = proficyDataSourceObj.ModulefeatueVersion;
            else
                updatedTaskObj.ModuleFeatureVersion = string.Empty;


            updatedTaskObj.Status = DELETE_TASK;

            return updatedTaskObj;

        }

        public PlantModel.PlantModelData SetPlantModelInfo(string _connectionString, ExcelTask RawDataTaskObj, bool lineLevelComparision, bool moduleLevelComparision, int plId, int puId)
        {

            var FL2s = new Hashtable();
            var ResultTaskObj = new PlantModel.PlantModelData();
            var CurrentTaskObj = new PlantModel.PlantModelData();
            var CurrentTaskObj2 = new PlantModel.PlantModelData();
            var plantModelDataList = new List<PlantModel.PlantModelData>();
            //string rawDataObjFL2;
            string plantmodelFL2FL3;
            string plantmodelFL3FL4 = "";
            string FilterFLs = "";
            bool FL4Required;

            if (lineLevelComparision == true)
            {
                plantModelDataList = GetLineHierarchyInfo(_connectionString, plId);
                foreach (var plantModelDataObj in plantModelDataList)
                {
                    if ((plantModelDataObj.FL2.Equals(RawDataTaskObj.FL2)))
                    {
                        CurrentTaskObj = plantModelDataObj;
                    }
                }

                if (string.IsNullOrEmpty(CurrentTaskObj.FL2))
                    //check how to handle this error message
                    CurrentTaskObj.ErrorMessage = "There is no FL2 configured on any Master Unit of this line in Proficy.";

                FilterFLs = string.Format("FL2 = '{0}' AND FL3 = '{1}'", RawDataTaskObj.FL2, RawDataTaskObj.FL3);
                foreach (var plantmodeldataObj in plantModelDataList)
                {
                    plantmodelFL2FL3 = string.Format("FL2 = '{0}' AND FL3 = '{1}'", plantmodeldataObj.FL2, plantmodeldataObj.FL3);
                    if (plantmodelFL2FL3.Equals(FilterFLs))
                        CurrentTaskObj = plantmodeldataObj;
                }

            }
            else if (moduleLevelComparision == true)
            {
                plantModelDataList = GetModuleHierarchyInfo(_connectionString, puId);
                FilterFLs = string.Format("FL3 = '{0}'", RawDataTaskObj.FL3);
                foreach (var plantmodeldataObj in plantModelDataList)
                {
                    plantmodelFL2FL3 = string.Format("FL3 = '{0}'", plantmodeldataObj.FL3);
                    if (plantmodelFL2FL3.Equals(FilterFLs))
                        CurrentTaskObj = plantmodeldataObj;
                }
            }

            ResultTaskObj.DepartmentDesc = CurrentTaskObj.DepartmentDesc;
            ResultTaskObj.LineDesc = CurrentTaskObj.LineDesc;
            ResultTaskObj.LineId = CurrentTaskObj.LineId;
            ResultTaskObj.MasterUnitDesc = CurrentTaskObj.MasterUnitDesc;
            ResultTaskObj.MasterUnitId = CurrentTaskObj.MasterUnitId;
            ResultTaskObj.FL1 = CurrentTaskObj.FL1;
            ResultTaskObj.FL2 = CurrentTaskObj.FL2;
            ResultTaskObj.FL3 = RawDataTaskObj.FL3;

            if (string.IsNullOrEmpty(RawDataTaskObj.FL3))
                CurrentTaskObj.ErrorMessage = "FL3 missing in Raw Data file.";
            else if (string.IsNullOrEmpty(RawDataTaskObj.ECIL_Module))
                CurrentTaskObj.ErrorMessage = "Module name is missing in Raw Data file.";
            else
            {
                if (string.IsNullOrEmpty(CurrentTaskObj.SlaveUnitDesc))
                    ResultTaskObj.SlaveUnitDesc = RawDataTaskObj.ECIL_Module;
                // check what do we do if the Slave Unit desc is different, how do we flag it U : 
                else if (CurrentTaskObj.SlaveUnitDesc != RawDataTaskObj.ECIL_Module)
                    ResultTaskObj.SlaveUnitDesc = "U:" + RawDataTaskObj.ECIL_Module;
                else
                {
                    ResultTaskObj.SlaveUnitDesc = CurrentTaskObj.SlaveUnitDesc;
                    ResultTaskObj.SlaveUnitId = CurrentTaskObj.SlaveUnitId;
                }
            }

            FL4Required = (!((DBNull.Value.Equals(RawDataTaskObj.FL4)) || (string.IsNullOrEmpty(RawDataTaskObj.FL4))));

            if (FL4Required)
            {

                if (lineLevelComparision == true)
                    FilterFLs = string.Format("FL2 = '{0}' AND FL3 = '{1}' AND FL4 = '{2}'", RawDataTaskObj.FL2, RawDataTaskObj.FL3, RawDataTaskObj.FL4);
                else if (moduleLevelComparision == true)
                    FilterFLs = string.Format("FL3 = '{0}' AND FL4 = '{1}'", RawDataTaskObj.FL3, RawDataTaskObj.FL4);

            }
            else
            {
                if (lineLevelComparision == true)
                    FilterFLs = string.Format("FL2 = '{0}' AND FL3 = '{1}' AND FL4 = '{2}'", RawDataTaskObj.FL2, RawDataTaskObj.FL3, "eCIL");
                else if (moduleLevelComparision == true)
                    FilterFLs = string.Format("FL3 = '{0}' AND FL4 = '{1}'", RawDataTaskObj.FL3, "eCIL");
            }




            foreach (var plantmodeldataobj in plantModelDataList)
            {
                if (FL4Required)
                {

                    if (lineLevelComparision == true)
                        plantmodelFL3FL4 = string.Format("FL2 = '{0}' AND FL3 = '{1}' AND FL4 = '{2}'", plantmodeldataobj.FL2, plantmodeldataobj.FL3, plantmodeldataobj.FL4);
                    else if (moduleLevelComparision == true)
                        plantmodelFL3FL4 = string.Format("FL3 = '{0}' AND FL4 = '{1}'", plantmodeldataobj.FL3, plantmodeldataobj.FL4);

                }
                //else
                //{
                //    if (lineLevelComparision == true)
                //        plantmodelFL3FL4 = string.Format("FL2 = '{0}' AND FL3 = '{1}' AND FL4 = '{2}'", plantmodeldataobj.FL2, plantmodeldataobj.FL3, "eCIL");
                //    else if (moduleLevelComparision == true)
                //        plantmodelFL3FL4 = string.Format("FL3 = '{0}' AND FL4 = '{1}'", RawDataTaskObj.FL3, "eCIL");
                //}
                else
                {
                    if (lineLevelComparision == true)
                        plantmodelFL3FL4 = string.Format("FL2 = '{0}' AND FL3 = '{1}' AND FL4 = '{2}'", plantmodeldataobj.FL2, plantmodeldataobj.FL3, plantmodeldataobj.ProductionGroupDesc);
                    else if (moduleLevelComparision == true)
                        plantmodelFL3FL4 = string.Format("FL3 = '{0}' AND FL4 = '{1}'", plantmodeldataobj.FL3, plantmodeldataobj.ProductionGroupDesc);
                }

                if (plantmodelFL3FL4.Equals(FilterFLs) && !string.IsNullOrEmpty(plantmodelFL3FL4))
                    CurrentTaskObj2 = plantmodeldataobj;

            }

            if (string.IsNullOrEmpty(CurrentTaskObj2.FL4))
            {
                if (FL4Required)
                {
                    ResultTaskObj.FL4 = RawDataTaskObj.FL4;
                    ResultTaskObj.ProductionGroupDesc = RawDataTaskObj.FL4;
                }
                else
                {
                    // how to display in front end
                    ResultTaskObj.ProductionGroupDesc = "eCIL";
                }
            }
            else
            {
                if (FL4Required)
                {
                    ResultTaskObj.FL4 = CurrentTaskObj2.FL4;
                    ResultTaskObj.ProductionGroupDesc = CurrentTaskObj2.ProductionGroupDesc;
                }
                else
                {
                    ResultTaskObj.ProductionGroupDesc = "eCIL";
                }

            }

            return ResultTaskObj;

        }

        public string FindTaskFrequency(int active, int window, int frequency, string freqType)
        {
            string UDP;
            string FrequencyValue;
            string WindowValue;

            Regex re = new Regex("^[0-9 ]+$");

            if ((string.IsNullOrEmpty(frequency.ToString())))
                UDP = string.Empty;
            else if (!(re.IsMatch(frequency.ToString())))
                UDP = string.Empty;
            else
            {
                if (active == 1)
                    UDP = "1";
                else
                    UDP = "0";
            }

            if ((!(string.IsNullOrEmpty(freqType))))
            {
                switch (freqType)
                {
                    case MINUTES:
                        frequency = (frequency + 365);
                        break;
                    case DAILY:
                        frequency = 1;
                        break;
                    case SHIFTLY:
                        frequency = 0;
                        break;
                }
            }


            FrequencyValue = frequency.ToString();
            if (FrequencyValue.Length <= 3)
                FrequencyValue = FrequencyValue.PadLeft(3, '0');
            UDP = UDP + FrequencyValue;

            if (!(string.IsNullOrEmpty(window.ToString())))
            {
                WindowValue = window.ToString();
                if (WindowValue.Length <= 3)
                    WindowValue = WindowValue.PadLeft(3, '0');
            }
            else
                WindowValue = "000";
            UDP = UDP + WindowValue;

            return UDP;
        }

        public string FormatTaskType(string tasktype)
        {
            string value = string.Empty;

            switch (tasktype)
            {
                case "A":
                    value = "Anytime";
                    break;
                case "D":
                    value = "Downtime";
                    break;
                case "R":
                    value = "Running";
                    break;
                default:
                    value = tasktype;
                    break;
            }

            return value;

        }

        #endregion 

    }
}
