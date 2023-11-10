using eCIL.Helper;
using eCIL.Filters;
using eCIL_DataLayer;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using System.Web.Http.Description;

namespace eCIL.Controllers
{
   

    public class CustomViewController : ApiController
    {

        private CustomView customView;
        private UserRepository _UserRepository;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public CustomViewController()
        {
            customView = new CustomView();
            _UserRepository = new UserRepository(); 


        }
        /// <summary>
        /// Get a list of custom views for a user - Minimum access 1 (Guest)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="screenDescription"></param>
        /// <returns></returns>
        // GET api/customview
        [HttpGet]
        [eCILAuthorization]
        public List<CustomView> Get(int userId, string screenDescription = "DataEntry")
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {

                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }

            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                List<CustomView> CustomViewsList = new List<CustomView>();

                CustomViewsList = customView.ReadCustomViews(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], userId, screenDescription);
                foreach (var customView in CustomViewsList)
                    if (customView.Data.StartsWith("page")) { 
                        if (screenDescription == "DataEntry")
                        {
                            try
                            {
                                customView.Data = Regex.Replace(ConvertOldStringFormatToNewStringFormatForTaskSelection(customView.Data).ToString().Replace(System.Environment.NewLine, String.Empty), @"\s+", String.Empty);
                            }catch(Exception ex)
                            {
                                log.Error(String.Format("User {0} - Error loading Custom View in Task Selection - " + ex.Message + " -- " + ex.StackTrace, userId));
                                customView.Data = "";
                            }
                        }
                           
                        if (screenDescription == "TasksManagement")
                        {
                            try
                            {
                                customView.Data = Regex.Replace(ConvertOldStringFormatToNewStringFormatForTaskMgmt(customView.Data).ToString().Replace(System.Environment.NewLine, String.Empty), @"\s+", String.Empty);
                            }catch(Exception ex)
                            {
                                log.Error(String.Format("User {0} - Error loading Custom View in Task Management - " + ex.Message + " -- " + ex.StackTrace, userId));
                                customView.Data = "";
                            }
                        }
                           
                        if (screenDescription == "VersionManagement")
                        {
                            try
                            {
                                customView.Data = Regex.Replace(ConvertOldStringFormatToNewStringFormatForTaskMgmt(customView.Data).ToString().Replace(System.Environment.NewLine, String.Empty), @"\s+", String.Empty);
                            }
                            catch(Exception ex)
                            {
                                log.Error(String.Format("User {0} - Error loading Custom View in Version Management - " + ex.Message + " -- " + ex.StackTrace, userId));
                                customView.Data = "";
                            }
                        }
                           
                        if (screenDescription == "TasksPlanningReport")
                        {
                            try
                            {
                                customView.Data = Regex.Replace(ConvertOldStringFormatToNewStringFormatForTaskPlanning(customView.Data).ToString().Replace(System.Environment.NewLine, String.Empty), @"\s+", String.Empty);
                            }catch(Exception ex)
                            {
                                log.Error(String.Format("User {0} - Error loading Custom View in Task Planing Report - " + ex.Message + " -- " + ex.StackTrace, userId));
                                customView.Data = "";
                            }
                        }
                           
                        if (screenDescription == "TasksConfigurationReport")
                        {
                            try
                            {
                                customView.Data = Regex.Replace(ConvertOldStringFormatToNewStringFormatForTaskConfiguration(customView.Data).ToString().Replace(System.Environment.NewLine, String.Empty), @"\s+", String.Empty);

                            }catch(Exception ex)
                            {
                                log.Error(String.Format("User {0} - Error loading Custom View in Task Configuration - " + ex.Message + " -- " + ex.StackTrace, userId));
                                customView.Data = "";
                            }
                        }
                           

                    }
                return CustomViewsList;
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest (Read)", userId));
                throw new HttpException(401, "Unauthorized access. You need minimum guest access on eCIL group to be able to get the custom view.");
            }
                
        }

        /// <summary>
        /// Save a custom view - Minimum access level 2(Operator)
        /// </summary>
        /// <param name="view"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        public string Put([FromBody] CustomView view)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 2)
            {
                try
                {
                    return customView.SaveCustomView(view, ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error editing custom view - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest (Read)", userId));
                throw new HttpException(401, "Unauthorized access. You need minimum guest access on eCIL group to be able to save a custom view.");
            }
        }

        /// <summary>
        /// Set site default view - Access level - 4 (Admin)
        /// </summary>
        /// <param name="UPId"></param>
        /// <param name="LanguageId"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/customview/setsitedefaultview")]
        public string SetSiteDefaultView(int UPId, int LanguageId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                    return customView.SetSiteDefaultView(UPId, LanguageId, ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error set site default view - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Admin(Level 4)", userId));
                throw new HttpException(401, "Unauthorized access. You need admin access on eCIL group to be able to set a view as site default view.");
            }
                
        }

        /// <summary>
        /// Set user default view - Minimum access level - 2 (Operator)
        /// </summary>
        /// <param name="UPId"></param>
        /// <param name="UserId"></param>
        /// <param name="LanguageId"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/customview/setuserdefaultview")]
        public string SetUserDefaultView(int UPId, int UserId, int LanguageId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 2)
            {
                try
                {
                    return customView.SetUserDefaultView(UPId, UserId, LanguageId, ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error set user default view - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }

            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator (Read/Write)", userId));
                throw new HttpException(401, "Unauthorized access. You need minimum operator access on eCIL group to be able to set a view as user default view.");
            }
                
        }

        /// <summary>
        /// Delete a custom view - Minium access level - 2(Operator)
        /// </summary>
        /// <param name="UPId"></param>
        /// <returns></returns>
        [HttpDelete]
        [eCILAuthorization]
        public string Delete(int UPId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 2)
            {
                try
                {
                    return customView.DeleteCustomView(UPId, ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error during deleting a custom view - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator (Read/Write)", userId));
                throw new HttpException(401, "Unauthorized access. You need minimum operator access on eCIL group to be able to set a view as site default view.");
            }
                
        }

        #region Utilities
        [ApiExplorerSettings(IgnoreApi = true)]
        public JObject ConvertOldStringFormatToNewStringFormatForTaskSelection(string layout)
        {
            string[] tableColumns = new string[0];

            tableColumns = new string[42] { "IsSelected", "TestId", "LineDesc", "MasterUnitDesc", "SlaveUnitDesc", "TaskId", "ColInfo", "ColDoc", "VarDesc", "Fixed", "ScheduleTime", "LateTime", "DueTime", "CurrentResult", "ColMove", "CommentInfo", "NbrDefects", "RouteDesc", "TaskOrder", "TeamDesc", "ItemNo", "FL1", "FL2", "FL3", "FL4", "TaskFreq", "TaskType", "Duration", "LongTaskName", "TaskAction", "Criteria", "Hazards", "Method", "PPE", "Tools", "Lubricant", "QFactorType", "PrimaryQFactor", "NbrPeople", "NbrItems", "IsDefectLooked", "IsHSE" };

            string groupParameters = Between(layout, "sort", "visible");
            string sortParameters = Between(layout, "sort", "visible");
            string visibleParameters = Between(layout, "visible", "width");
            string widthParameters = layout.Substring(layout.IndexOf("width"));

            string[] widthParametersResults = widthParameters.Split('|');
            string[] visibleParametersResult = visibleParameters.Replace("-", "").Split('|');
            string[] sortParametersResult = sortParameters.Split('|');
            string[] groupParametersResult = groupParameters.Split('|');

            Array.Resize(ref groupParametersResult, groupParametersResult.Length - 1);

            JArray result = new JArray();

            string isEditedField = @"{'visibleIndex':1,'dataField':'IsEdited','dataType':'boolean','visible':false}";
            result.Add(JObject.Parse(isEditedField));

            int groupIndex = 0;
            for (int i = 0; i < visibleParametersResult.Length && visibleParametersResult[i] != ""; i++)
            {
                int index = Array.IndexOf(visibleParametersResult, "t" + i.ToString());
                if (index > -1)
                {

                    string field = "";
                    string dataType = tableColumns[index] == "IsSelected" ? "boolean" : "string";
                    string sort = Array.Find(sortParametersResult, s => s.Equals("a" + index.ToString()) || s.Equals("d" + index.ToString()));
                    string group = Array.Find(groupParametersResult, s => s.Equals("a" + index.ToString()) || s.Equals("d" + index.ToString()));

                    field = "{'visibleIndex':" + (result.Count + 1).ToString() + ",'dataField':'" + tableColumns[index] + "','visible':true,";
                    field += "'dataType':'" + dataType + "',";

                    if (sort != null)
                    {
                        string sortOrder = sort.Substring(0, 1) == "a" ? "asc" : "desc";
                        field += "'sortOrder':'" + sortOrder + "',";
                    }

                    if (group != null)
                    {
                        field += "'groupIndex':" + groupIndex.ToString() + ",";
                        groupIndex += 1;
                    }

                    if (tableColumns[index] == "IsSelected" || tableColumns[index] == "ColInfo" || tableColumns[index] == "ColDoc")
                    {
                        field += "'width':'50px', 'alignment':'center',";
                    }

                    if (tableColumns[index] == "NbrDefects1" || tableColumns[index] == "CommentInfo1")
                    {
                        field += "'width':'70px',";
                    }

                    field += "}";

                    result.Add(JObject.Parse(field));
                }
            }

            for (int x = 0; x < visibleParametersResult.Length && visibleParametersResult[x] != ""; x++)
            {
                int index = result.Count + 1;
                string temp = visibleParametersResult[x].Substring(0, 1);
                string group = Array.Find(groupParametersResult, s => s.Equals("a" + x.ToString()) || s.Equals("d" + x.ToString()));

                if (temp == "f")
                {
                    string field = "{'visibleIndex':" + index.ToString() + ",'dataField':'" + tableColumns[x] + "','dataType':'string','visible':false,";

                    if (group != null)
                    {
                        field += "'groupIndex':" + groupIndex.ToString() + ",";
                        groupIndex += 1;
                    }

                    field += "}";

                    result.Add(JObject.Parse(field));
                }
            }

            string resultJsonStringFormat = @"{
                'allowedPageSizes':[10,20,40],
                'filterPanel':{'filterEnabled':true},
                'filterValue':null,
                'searchText':'',
                'pageIndex':0,
                'pageSize':20
            }";

            JObject resultObject = JObject.Parse(resultJsonStringFormat);
            resultObject.Property("allowedPageSizes").AddBeforeSelf(new JProperty("columns", result));
            return resultObject;
        }
        [ApiExplorerSettings(IgnoreApi = true)]
        public JObject ConvertOldStringFormatToNewStringFormatForTaskMgmt(string layout)
        {
            string[] tableColumns = new string[0];

            tableColumns = new string[56] { "Selection", "Action", "Status", "State", "DepartmentDesc", "LineDesc", "MasterUnitDesc", "SlaveUnitDesc", "ProductionGroupDesc", "FL1", "FL2", "FL3", "FL4", "VarDesc", "VMId", "TaskLocation", "TaskId", "TaskType", "TaskAction", "Active", "TaskFreq", "Frequency", "Window", "TestTime", "FixedFrequency", "ShiftOffset", "StartDate", "LongTaskName", "NbrItems", "Duration", "NbrPeople", "Criteria", "Hazards", "Method", "PPE", "Tools", "Lubricant", "DocumentLinkTitle", "DocumentLinkPath", "QFactorType", "PrimaryQFactor", "HSEFlag", "VarId", "KeyId", "LineVersion", "ModuleFeatureVersion", "ScheduleScope", "DepartmentId", "PLId", "MasterUnitId", "SlaveUnitId", "ProductionGroupId", "DisplayLink", "ExternalLink", "LateTime", "DueTime" };

            string groupParameters = Between(layout, "sort", "visible");
            string sortParameters = Between(layout, "sort", "visible");
            string visibleParameters = Between(layout, "visible", "width");
            string widthParameters = layout.Substring(layout.IndexOf("width"));

            string[] widthParametersResults = widthParameters.Split('|');
            string[] visibleParametersResult = visibleParameters.Replace("-", "").Split('|');
            string[] sortParametersResult = sortParameters.Split('|');
            string[] groupParametersResult = groupParameters.Split('|');

            Array.Resize(ref groupParametersResult, groupParametersResult.Length - 1);

            JArray result = new JArray();

            //int groupIndex = 0;
            for (int i = 0; i < visibleParametersResult.Length && visibleParametersResult[i] != ""; i++)
            {
                int index = Array.IndexOf(visibleParametersResult, "t" + i.ToString());
                if (index > -1)
                {
                    string field = "";
                    if (tableColumns[index] != "Selection" && tableColumns[index] != "Action")
                    {
                        string sort = Array.Find(sortParametersResult, s => s.Equals("a" + index.ToString()) || s.Equals("d" + index.ToString()));
                        string group = Array.Find(groupParametersResult, s => s.Equals("a" + index.ToString()) || s.Equals("d" + index.ToString()));

                        field = "{'visibleIndex':" + (result.Count + 1).ToString() + ",'dataField':'" + tableColumns[index] + "','visible':true,";

                        if (sort != null)
                        {
                            string sortOrder = sort.Substring(0, 1) == "a" ? "asc" : "desc";
                            field += "'sortOrder':'" + sortOrder + "',";
                        }

                        //if (group != null)
                        //{
                        //    field += "'groupIndex':" + groupIndex.ToString() + ",";
                        //    groupIndex += 1;
                        //}

                        field += "}";

                        result.Add(JObject.Parse(field));
                    }
                }
            }

            for (int x = 0; x < visibleParametersResult.Length && visibleParametersResult[x] != ""; x++)
            {
                int index = result.Count + 1;
                string temp = visibleParametersResult[x].Substring(0, 1);
                string group = Array.Find(groupParametersResult, s => s.Equals("a" + x.ToString()) || s.Equals("d" + x.ToString()));

                if (temp == "f" && tableColumns[x] != "Selection" && tableColumns[index] != "Action")
                {
                    string field = "{'visibleIndex':" + index.ToString() + ",'dataField':'" + tableColumns[x] + "','dataType':'string','visible':false,";

                    //if (group != null)
                    //{
                    //    field += "'groupIndex':" + groupIndex.ToString() + ",";
                    //    groupIndex += 1;
                    //}

                    field += "}";

                    result.Add(JObject.Parse(field));
                }
            }

            string resultJsonStringFormat = @"{
                'allowedPageSizes':[10,20,40],
                'filterPanel':{'filterEnabled':true},
                'filterValue':null,
                'searchText':'',
                'pageIndex':0,
                'pageSize':20
            }";

            JObject resultObject = JObject.Parse(resultJsonStringFormat);
            resultObject.Property("allowedPageSizes").AddBeforeSelf(new JProperty("columns", result));
            return resultObject;
        }
        [ApiExplorerSettings(IgnoreApi = true)]
        public JObject ConvertOldStringFormatToNewStringFormatForTaskPlanning(string layout)
        {
            string[] tableColumns = new string[0];

            tableColumns = new string[22] { "Team", "Route", "Department", "Line", "MasterUnit", "SlaveUnit", "TaskId", "Task", "ProjectedScheduleDate", "FL1", "FL2", "FL3", "FL4", "Duration", "LongTaskName", "Info", "ExternalLink", "TaskFrequency", "TaskType", "LateTime", "Lubricant", "VarId" };

            string groupParameters = Between(layout, "sort", "visible");
            string sortParameters = Between(layout, "sort", "visible");
            string visibleParameters = Between(layout, "visible", "width");

            string[] groupParametersResult = groupParameters.Split('|');
            string[] sortParametersResult = sortParameters.Split('|');
            string[] visibleParametersResult = visibleParameters.Replace("-", "").Split('|');

            Array.Resize(ref groupParametersResult, groupParametersResult.Length - 1);
            JArray result = new JArray();

            int groupIndex = 0;
            for (int i = 0; i < visibleParametersResult.Length && visibleParametersResult[i] != ""; i++)
            {
                int index = Array.IndexOf(visibleParametersResult, "t" + i.ToString());
                if (index > -1)
                {
                    string field = "";
                    string sort = Array.Find(sortParametersResult, s => s.Equals("a" + index.ToString()) || s.Equals("d" + index.ToString()));
                    string group = Array.Find(groupParametersResult, s => s.Equals("a" + index.ToString()) || s.Equals("d" + index.ToString()));

                    field = "{'visibleIndex':" + (result.Count + 1).ToString() + ",'dataField':'" + tableColumns[index] + "','visible':true,";

                    if (sort != null)
                    {
                        string sortOrder = sort.Substring(0, 1) == "a" ? "asc" : "desc";
                            field += "'sortOrder':'" + sortOrder + "',";
                    }

                    if (group != null)
                    {
                        field += "'groupIndex':" + groupIndex.ToString() + ",";
                        groupIndex += 1;
                    }

                    field += "}";

                    result.Add(JObject.Parse(field));
                }
            }

            for (int x = 0; x < visibleParametersResult.Length && visibleParametersResult[x] != ""; x++)
            {
                int index = result.Count + 1;
                string temp = visibleParametersResult[x].Substring(0, 1);
                string group = Array.Find(groupParametersResult, s => s.Equals("a" + x.ToString()) || s.Equals("d" + x.ToString()));

                if (temp == "f")
                {
                    string field = "{'visibleIndex':" + index.ToString() + ",'dataField':'" + tableColumns[x] + "','dataType':'string','visible':false,";

                    if (group != null)
                    {
                        field += "'groupIndex':" + groupIndex.ToString() + ",";
                        groupIndex += 1;
                    }

                    field += "}";

                    result.Add(JObject.Parse(field));
                }
            }

            string resultJsonStringFormat = @"{
                'allowedPageSizes':[10,20,40],
                'filterPanel':{'filterEnabled':true},
                'filterValue':null,
                'searchText':'',
                'pageIndex':0,
                'pageSize':20
            }";

            JObject resultObject = JObject.Parse(resultJsonStringFormat);
            resultObject.Property("allowedPageSizes").AddBeforeSelf(new JProperty("columns", result));
            return resultObject;
        }
        [ApiExplorerSettings(IgnoreApi = true)]
        public JObject ConvertOldStringFormatToNewStringFormatForTaskConfiguration(string layout)
        {
            string[] tableColumns = new string[0];

            tableColumns = new string[38] { "DepartmentDesc", "LineDesc", "MasterUnitDesc", "SlaveUnitDesc", "ProductionGroupDesc", "FL1", "FL2", "FL3", "FL4", "VarDesc", "VMId", "TaskLocation", "TaskId", "TaskType", "TaskAction", "Active", "FrequencyType", "Frequency", "Window", "TestTime", "FixedFrequency", "StartDate", "LongTaskName", "NbrItems", "Duration", "NbrPeople", "Criteria", "Hazards", "Method", "PPE", "Tools", "Lubricant", "DocumentLinkTitle1", "DocumentLinkPath1", "QFactorType", "PrimaryQFactor", "VarId", "CurrentResult" };

            string groupParameters = Between(layout, "sort", "visible");
            string sortParameters = Between(layout, "sort", "visible");
            string visibleParameters = Between(layout, "visible", "width");

            string[] groupParametersResult = groupParameters.Split('|');
            string[] sortParametersResult = sortParameters.Split('|');
            string[] visibleParametersResult = visibleParameters.Replace("-", "").Split('|');

            Array.Resize(ref groupParametersResult, groupParametersResult.Length - 1);
            JArray result = new JArray();
            
            for (int i = 0; i < visibleParametersResult.Length && visibleParametersResult[i] != ""; i++)
            {
                int index = Array.IndexOf(visibleParametersResult, "t" + i.ToString());
                if (index > -1)
                {
                    string field = "";
                    if (tableColumns[index] != "CurrentResult1")
                    {
                        string sort = Array.Find(sortParametersResult, s => s.Equals("a" + index.ToString()) || s.Equals("d" + index.ToString()));
                        //string group = Array.Find(groupParametersResult, s => s.Equals("a" + index.ToString()) || s.Equals("d" + index.ToString()));

                        field = "{'visibleIndex':" + (result.Count + 1).ToString() + ",'dataField':'" + tableColumns[index] + "','visible':true,";

                        if (sort != null)
                        {
                            string sortOrder = sort.Substring(0, 1) == "a" ? "asc" : "desc";
                            field += "'sortOrder':'" + sortOrder + "',";
                        }

                        //if (group != null)
                        //{
                        //    field += "'groupIndex':" + groupIndex.ToString() + ",";
                        //    groupIndex += 1;
                        //}

                        field += "}";

                        result.Add(JObject.Parse(field));
                    }
                }
            }

            for (int x = 0; x < visibleParametersResult.Length && visibleParametersResult[x] != ""; x++)
            {
                int index = result.Count + 1;
                string temp = visibleParametersResult[x].Substring(0, 1);
                //string group = Array.Find(groupParametersResult, s => s.Equals("a" + x.ToString()) || s.Equals("d" + x.ToString()));

                if (temp == "f" && tableColumns[x] != "CurrentResult1")
                {
                    string field = "{'visibleIndex':" + index.ToString() + ",'dataField':'" + tableColumns[x] + "','dataType':'string','visible':false,";

                    //if (group != null)
                    //{
                    //    field += "'groupIndex':" + groupIndex.ToString() + ",";
                    //    groupIndex += 1;
                    //}

                    field += "}";

                    result.Add(JObject.Parse(field));
                }
            }

            string resultJsonStringFormat = @"{
                'allowedPageSizes':[10,20,40],
                'filterPanel':{'filterEnabled':true},
                'filterValue':null,
                'searchText':'',
                'pageIndex':0,
                'pageSize':20
            }";

            JObject resultObject = JObject.Parse(resultJsonStringFormat);
            resultObject.Property("allowedPageSizes").AddBeforeSelf(new JProperty("columns", result));
            return resultObject;
        }
        [ApiExplorerSettings(IgnoreApi = true)]
        public string Between(string STR, string FirstString, string LastString)
        {
            string FinalString;
            int Pos1 = STR.IndexOf(FirstString) + FirstString.Length;
            Pos1 += STR.Substring(Pos1, STR.Length - Pos1).IndexOf("|") + 1;
            int Pos2 = STR.IndexOf(LastString) - 1;
            if (Pos2 - Pos1 < 0)
                return string.Empty;
            FinalString = STR.Substring(Pos1, Pos2 - Pos1);
            return FinalString;
        }

        #endregion
    }
}
