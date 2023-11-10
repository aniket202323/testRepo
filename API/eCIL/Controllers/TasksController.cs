using eCIL.Helper;
using eCIL.Filters;
using eCIL.Models;
using eCIL_DataLayer;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using System.Web.UI.WebControls;
using System.Xml.Linq;
using static eCIL_DataLayer.Task;

namespace eCIL.Controllers
{

    public class TasksController : ApiController
    {
        private Task task;
        private TaskEdit taskEdit;
        private TaskDetails taskDetails;
        private UserRepository _UserRepository;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public TasksController()
        {
            task = new Task();
            taskEdit = new TaskEdit();
            taskDetails = new TaskDetails();
            _UserRepository = new UserRepository();
        }

        /// <summary>
        /// Get all tasks for a plant model - Minimum access level = 1(Guest)
        /// </summary>
        /// <param name="routes"></param>
        /// <param name="taskType"></param>
        /// <param name="taskResult"></param>
        /// <returns></returns>
        //Get the tasks for a list of routes
        // Ex: /api/tasks?routes=12,14&taskType=DOwntime&taskResult=Defect
        [HttpGet]
        [eCILAuthorization]
        public List<Task> Get(string routes, string taskType = null, string taskResult = null)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return task.GetTasksList(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], taskType, taskResult, null, "", "", "", "", "", routes);
                }
                catch (Exception ex)
                {
                    log.Error("Error Geting tasks - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get tasks");
            }
                
        }

        /// <summary>
        /// Get tasks for a team - Minimum access level = 1(Guest)
        /// </summary>
        /// <param name="teams"></param>
        /// <param name="taskType"></param>
        /// <param name="taskResult"></param>
        /// <returns></returns>
        //Get tasks for a list of teams
        //Ex: /api/tasks/teams=12?taskType=DOwntime&taskResult=Defect
        [HttpGet]
        [eCILAuthorization]
        public List<Task> GetTeamTasks(string teams, string taskType = null, string taskResult = null)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return task.GetTasksList(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], taskType, taskResult, null, "", "", "", "", teams, "");
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Team Tasks - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get tasks");
            }
                
        }

        /// <summary>
        /// Get Tasks for a production line - Minimul access level - 1(Guest)
        /// </summary>
        /// <param name="lineId"></param>
        /// <param name="masterId"></param>
        /// <param name="slavesId"></param>
        /// <param name="taskType"></param>
        /// <param name="taskResult"></param>
        /// <returns></returns>
        //Get tasks for a list of a line
        //Ex: /api/tasks/line=183?taskType=Downtime&taskResult=Defect
        [HttpGet]
        [eCILAuthorization]
        public List<Task> GetProductionLineTasks(string lineId, string masterId = null, string slavesId = null, string taskType = null, string taskResult = null)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                
            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    if (masterId != null)
                    {
                        if (slavesId != null)
                        {
                            try
                            {
                                return task.GetTasksList(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], taskType, taskResult, null, "", lineId, masterId, slavesId, "", "");
                            }catch(Exception ex)
                            {
                                log.Error(String.Format("Error during get production line tasks based on Master Id {0},Slave Id: {1} - UserId: " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace, masterId, slavesId));
                                return null;
                            }
                        }
                           
                        else
                        {
                            try
                            {
                                return task.GetTasksList(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], taskType, taskResult, null, "", lineId, masterId, "", "", "");
                            }catch(Exception ex)
                            {
                                log.Error(String.Format("Error during get production line tasks based on Master Id {0} - UserId: " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace, masterId));
                                return null;
                            }
                        }
                            
                    }
                    else
                    {
                        try
                        {
                            return task.GetTasksList(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], taskType, taskResult, null, "", lineId, "", "", "", "");
                        }catch(Exception ex)
                        {
                            log.Error(String.Format("Error during get production line tasks based on Line Id {0} - UserId: " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace, lineId));
                            return null;
                        }
                    }
                       
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get tasks");
            }
                
            
        }

        /// <summary>
        /// Get task Details based on testId
        /// </summary>
        /// <param name="testId"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/tasks/gettaskdetails")]
        public TaskDetails GetTaskDetails(Int64 testId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }

            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return taskDetails.GetTaskDetails(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], testId);
                }
                catch(Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get tasks");
            }
        }


        /// <summary>
        /// Get User Results Prompts for tasks - Minimum access level 1(Guest)
        /// </summary>
        /// <param name="UserLanguageId"></param>
        /// <returns></returns>
        //Get user result prompts for tasks
        //Ex: /api/tasks/userresultprompts?userlangaugeid=2
        [HttpGet]
        [eCILAuthorization]
        public Dictionary<int, string> GetUserResultPrompts(int UserLanguageId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                
            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return task.GetUserTaskResultPrompts(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], UserLanguageId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get User result prompts for tasks value - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get user results prompts");
            }
                
            
        }

        /// <summary>
        /// Get Server Results Prompts for tasks - Minimum access level 1(Guest)
        /// </summary>
        /// <returns></returns>
        //Get server result prompts for tasks
        //Ex: /api/tasks/serverresultprompts
        [HttpGet]
        [eCILAuthorization]
        public List<Task.ServerTaskResultPrompts> GetServerResultPrompts()
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
            

            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return task.GetServerTaskResultPrompts(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get server result prompts for tasks - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get server results prompts");
            }
                
        }

       
        /// <summary>
        /// Save a list of tasks - Minium access level - 2(Operator)
        /// </summary>
        /// <param name="tasks"></param>
        /// <returns></returns>
        // PUT api/tasks
        [HttpPut]
        [eCILAuthorization]
        public string Put([FromBody]List<Task> tasks)
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
                    return task.SaveTasks(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tasks, userId, "");
                }
                catch (Exception ex)
                {
                    log.Error("Error Editing tasks - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator(Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to save a task");
            }
                
        }

        #region TasksMgmt Methods
        // GET api/tasks/getlinetasksforplantmodel
        /// <summary>
        /// Get Line Taks based on Plant Model - Minimum access level 3(Line Manager)
        /// </summary>
        /// <param name="LineIds"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/tasks/getlinetasksforplantmodel")]
        public List<LineTasksForPlantModel> GetLineTasksForPlantModel(string LineIds)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 3)
            {
                try
                {
                    return task.GetLineTasksForPlantModel(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], LineIds);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Line Tasks for plant model - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get line task");
            }
                
        }

        /// <summary>
        /// Get PPA Version Accepted - Minimum access level 3(Line Manager)
        /// </summary>
        /// <returns></returns>
        // GET api/tasks/getppaversionaspected
        [HttpGet]
        [eCILAuthorization]
        [Route("api/tasks/getppaversionaspected")]
        public bool GetPPAVersionAspected()
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {

                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 3)
            {
                try
                {
                    return task.GetPPAVersionAspected(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get PPA Version Expected - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get line task");
            }
                
        }

        /// <summary>
        /// Get all tasks by Plant Model for Task Management - Minium access level - 3 (Line Manager)
        /// </summary>
        /// <param name="deptIds"></param>
        /// <param name="lineIds"></param>
        /// <param name="masterIds"></param>
        /// <param name="slaveIds"></param>
        /// <param name="groupIds"></param>
        /// <param name="variableIds"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/tasks/gettasksbyplantmodel")]
        public List<TaskEdit> GetTasksByPlantModel(string deptIds, string lineIds = null, string masterIds = null, string slaveIds = null, string groupIds = null, string variableIds = null)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if (_UserRepository.CheckJwtToken(jwtToken) >= 3)
            {
                try
                {
                    return taskEdit.GetTasksPlantModelEditList(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], deptIds, lineIds, masterIds, slaveIds, groupIds, variableIds);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Task by plant Model for Task Management - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get task by plantModel");
            }
                
        }

        /// <summary>
        /// Return Tasks list by Functional location on Task Management - Min access level - 3(Line Manager)
        /// </summary>
        /// <param name="FlList"></param>
        /// <param name="VarList"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/tasks/gettasksbyfllist")]
        public List<TaskEdit> GetTasksByFlList(string FlList, string VarList = "")
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 3)
            {
                try
                {
                    return taskEdit.GetTasksByFlList(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], FlList, VarList);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Task By FL List - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get task by FL list");
            }
                
        }

        /// <summary>
        /// Add a single task - Access level - 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="task"></param>
        /// <returns></returns>
        [HttpPost]
        [eCILAuthorization]
        [Route("api/tasks/add")]
        public void AddTask(int userId, [FromBody]TaskEdit task)
        {

            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                    taskEdit.AddTask(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], task, userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Adding Task - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to add a task");
            }
                
        }


        /// <summary>
        /// Update a task - access level 4 (Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="task"></param>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/tasks/update")]
        public void UpdateTask(int userId, [FromBody]TaskEdit task)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                    taskEdit.UpdateTask(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], task, userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Updating task - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin(Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to update a task");
            }
                
        }

        /// <summary>
        /// Obsolete a single task - Access level - 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="task"></param>
        /// <returns></returns>
        [HttpDelete]
        [eCILAuthorization]
        [Route("api/tasks/delete")]
        public void Delete(int userId, [FromBody]TaskEdit task)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                    taskEdit.DeleteTask(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], task, userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Deleting a task - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to obsolete(delete) a task");
            }
                
        }

        /// <summary>
        /// Save Management Tasks - Access Level 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="tasks"></param>
        /// <returns></returns>
        [HttpPost]
        [eCILAuthorization]
        [Route("api/tasks/savemgmttasks")]
        public List<TaskEdit> SaveMgmtTasks(int userId, [FromBody]List<TaskEdit> tasks)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                   return taskEdit.SaveMgmtTasks(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tasks, userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error saving tasks in task management - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to save all tasks from administration part");
            }
                
        }
        #endregion

        [HttpPut]
        [eCILAuthorization]
        [Route("api/tasks/settaskvalue")]
        public async System.Threading.Tasks.Task<SingleUpdateResponse> SetTaskValue([FromBody]TestValueRecord test)
        {
            SingleUpdateResponse response = new SingleUpdateResponse("Tasks");
            response.id = test.testValueRecordId;

            try
            { 
                IEnumerable<String> values;
                String url = "";
                url = "https://" + System.Configuration.ConfigurationManager.AppSettings["ProficyServer"] + 
                    "/activities-service/variables/v1/testValueRecords/" + test.testValueRecordId;


                using (HttpClient client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue(
                        Request.Headers.Authorization.Scheme,
                        Request.Headers.Authorization.Parameter);

                    client.DefaultRequestHeaders.ExpectContinue = false;

                    HttpResponseMessage resp = client.PutAsync(url,
                        new StringContent(
                            Newtonsoft.Json.JsonConvert.SerializeObject(test),
                            Encoding.UTF32, "application/json"
                            )
                        ).Result;


                    if(resp.StatusCode != HttpStatusCode.OK)
                    {
                        throw new Exception("Error " + resp.StatusCode + " returned by Proficy");
                    }

                    response.Succesfull = true;

                }
            }
            catch(NullReferenceException nullEx)
            {
                response.Message = "Internal server error! Something went wrong!";
            }
            catch (Exception ex)
            {
                response.Message = ex.Message;
            }

            return response;
        }

        [HttpPut]
        [eCILAuthorization]
        [Route("api/tasks/settasksvalues")]
        public BulkUpdateResponse SetTasksValues([FromBody] List<TestValueRecord> tests)
        {

            String result = "Update succesfull";
            BulkUpdateResponse response = new BulkUpdateResponse("Tasks");

            List<System.Threading.Tasks.Task<SingleUpdateResponse>> tasks = new List<System.Threading.Tasks.Task<SingleUpdateResponse>>();

            foreach (TestValueRecord test in tests)
            {
                try
                {
                    System.Threading.Tasks.Task<SingleUpdateResponse> t = SetTaskValue(test);
                    tasks.Add(t);
                }
                catch (Exception e)
                {
                    result = e.Message;
                }
            }

            System.Threading.Tasks.Task.WaitAll(tasks.ToArray());

            foreach (System.Threading.Tasks.Task<SingleUpdateResponse> task in tasks)
            {
                if(task.Result.Succesfull)
                {
                    response.SuccesfullUpdates.Add(task.Result.id);
                }
                else
                {
                    response.FailedUpdates.Add(task.Result.id);
                }
            }

            return response;
        }
    }
}
