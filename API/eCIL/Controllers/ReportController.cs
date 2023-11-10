using eCIL.Filters;
using eCIL_DataLayer;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Http;
using System;
using eCIL_DataLayer.Reports;
using static eCIL_DataLayer.Reports.EmagReport;
using static eCIL_DataLayer.Reports.TasksPlanningReport;
using static eCIL_DataLayer.Reports.MultipleAssignmentsReport;
using static eCIL_DataLayer.Reports.UnassignedTasksReport;
using eCIL.Helper;

namespace eCIL.Controllers 
{

    public class ReportController : ApiController
    {
        private ComplianceReport compliance;
        private ComplianceReportPrint compliancePrint;
        private EmagReport emagReport;
        private TasksPlanningReport tasksPlanning;
        private MultipleAssignmentsReport multipleAssignments;
        private UnassignedTasksReport unassignedTasks;
        private ReportSchedulingErrors reportSchedulingErrors;
        private DownTimesReport downtimesReport;
        private DownTime downTime;
        private TrendReport trendReport;
        private Specifications specs;
        private UserRepository _UserRepository;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public ReportController()
        {
            compliance = new ComplianceReport();
            compliancePrint = new ComplianceReportPrint();
            emagReport = new EmagReport();
            tasksPlanning = new TasksPlanningReport();
            multipleAssignments = new MultipleAssignmentsReport();
            unassignedTasks = new UnassignedTasksReport();
            reportSchedulingErrors = new ReportSchedulingErrors();
            downtimesReport = new DownTimesReport();
            downTime = new DownTime();
            trendReport = new TrendReport();
            specs = new Specifications();
            _UserRepository = new UserRepository();
        }

        /// <summary>
        /// Get Compliance Report data - Minim access level 1 (Guest)
        /// </summary>
        /// <param name="granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="topLevelId">The Id from which the report was initiated, before drill-down</param>
        /// <param name="subLevel">The id of the current level being drilled-down</param>
        /// <param name="startTime">The beginning period of the report</param>
        /// <param name="endTime">The end period of the report</param>
        /// <param name="userId"></param>
        /// <param name="routeIds">The list of IDs representing routes to include in the report</param>
        /// <param name="teamIds">The list of IDs representing teams to include in the report</param>
        /// <param name="teamDetails">The level of details we want for Team (1=Summary  2=Routes  4=Plant Model)</param>
        /// <param name="qFactorOnly">Specify if we only want QFactor Tasks in the report.</param>
        /// <returns>List of COmpliance Report objects representing summary for the current level</returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/getcompliance")]
        public List<ComplianceReport> GetComplianceReport(int granularity, string startTime, string endTime, int userId, string routeIds, string teamIds, int teamDetails, bool qFactorOnly, int topLevelId, int subLevel, int selectionItemId = 0, bool HSEOnly = false) //, bool MinimumUptimeOnly = false
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }

         
            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return compliance.GetData(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], granularity, topLevelId, subLevel, startTime, endTime, userId, routeIds, teamIds, teamDetails, qFactorOnly, selectionItemId, HSEOnly); //MinimumUptimeOnly
                }
                catch (Exception ex)
                {
                    log.Error("Error Get compliance report - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get compliance report data");
            }
                
        }

        ///<summary>
        /// Get the list of specifications used to color the background of the cells in the Compliance Report - Minimum access level 1 (Guest)
        /// </summary>
        /// <param name="granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="ids">The list of IDs represented in the current level</param>
        /// <param name="startDate">The beginning period of the report</param>
        /// <param name="endDate">The ending period of the report</param>
        /// <returns>DataTable that hold row(s) representing specifications for the current level</returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/getcompliancespecs")]
        public List<Specifications> GetSpecs(int granularity, string ids, string startDate, string endDate)
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
                    return specs.GetSpecs(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], granularity, ids, startDate, endDate);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Specifications for compliance report - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get compliance specifications");
            }

        }


        /// <summary>
        /// Get Compliance Report data Print - Minim access level 1 (Guest)
        /// </summary>
        /// <param name="granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="topLevelId">The Id from which the report was initiated, before drill-down</param>
        /// <param name="subLevel">The id of the current level being drilled-down</param>
        /// <param name="startTime">The beginning period of the report</param>
        /// <param name="endTime">The end period of the report</param>
        /// <param name="userId"></param>
        /// <param name="routeIds">The list of IDs representing routes to include in the report</param>
        /// <param name="teamIds">The list of IDs representing teams to include in the report</param>
        /// <param name="teamDetails">The level of details we want for Team (1=Summary  2=Routes  4=Plant Model)</param>
        /// <param name="qFactorOnly">Specify if we only want QFactor Tasks in the report.</param>
        /// <returns>List of COmpliance Report objects representing summary for the current level for printing(include the entire plantModel)</returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/getcomplianceprint")]
        public List<ComplianceReportPrint> GetComplianceReportPrint(int granularity, string startTime, string endTime, int userId, string routeIds, string teamIds, int teamDetails, bool qFactorOnly, int topLevelId, int subLevel, bool HSEOnly = false) //, bool MinimumUptimeOnly = false
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }

            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return compliancePrint.GetReportDataPrint(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], granularity, topLevelId, subLevel, startTime, endTime, userId, routeIds, teamIds, teamDetails, qFactorOnly, HSEOnly); // MinimumUptimeOnly
                }
                catch (Exception ex)
                {
                    log.Error("Error Get compliance report print - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get compliance report data print");
            }
        }


        /// <summary>
        /// Get Emag report data - Minimum access level - 1(Guest)
        /// </summary>
        /// <param name="puId"></param>
        /// <param name="endDate"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/getemagreportdata")]
        public EmagReport GetEmagReportData(int puId, string endDate) // List<EmagReport>
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
                    return emagReport.GetEmagReportData(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], puId, endDate);
                }
                catch (System.Exception ex)
                {
                    log.Error("Error Get Emag Report Data - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get Emag report data");
            }
                
        }


        /// <summary>
        /// Get Emag report downtimes - Minimum access level 1 (Guest)
        /// </summary>
        /// <param name="puId"></param>
        /// <param name="endDate"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/getemagreportdowntimes")]
        public List<DownTimesReport> GetEmagReportDowntimes(int puId, string endDate)
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

                    return downtimesReport.GetDownTimes(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], puId, endDate);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Emag Report DownTimes - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get Emag report downtimes");
            }
                
        }

        /// <summary>
        /// Get downtime details - Minimum access level 1(Guest)
        /// </summary>
        /// <param name="puId"></param>
        /// <param name="eventReasonName"></param>
        /// <param name="endDate"></param>
        /// <param name="dayOffset">Index for column where the user click (from 1 to 30)</param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/getdowntimedetails")]
        public List<DownTime> GetDowntimeDetails(int puId, string eventReasonName, string endDate, int dayOffset)
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
                    return downTime.GetDowntimeDetails(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], puId, eventReasonName, endDate, dayOffset);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Downtime Details - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get downtime details");
            }
                
        }

        /// <summary>
        /// Get Trend Report for a taskId - Minimum access level 1
        /// </summary>
        /// <param name="varId"></param>
        /// <param name="endDate"></param>
        /// <param name="languageId">Optional parameter</param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/gettrendreport")]
        public TrendReport GetTrendReport(int varId, string endDate, int languageId)
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
                    return trendReport.GetTrendReport(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], varId, endDate, languageId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Trend Report - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get trend report");
            }

        }



        /// <summary>
        /// Get data for task planning report - Minimum access level 1 (Guest)
        /// </summary>
        /// <param name="Granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="TopLevelId">The Id from which the report was initiated, before drill-down</param>
        /// <param name="SubLevel">The id of the current level being drilled-down</param>
        /// <param name="StartTime">The beginning period of the report</param>
        /// <param name="EndTime">The end period of the report</param>
        /// <param name="UserId">User asking for the report</param>
        /// <param name="RouteIds">The list of IDs representing routes to include in the report</param>
        /// <param name="TeamIds">The list of IDs representing teams to include in the report</param>
        /// <param name="TeamDetails">The level of details we want for Team (1=Summary  2=Routes  4=Plant Model)</param>
        /// <param name="Departments"></param>
        /// <param name="Lines"></param>
        /// <param name="Units"></param>
        /// <returns>List of Tasks Planning Report </returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/gettasksplanning")]
        public List<TasksPlanning> GetTasksPlanningData(int Granularity, string StartTime, string EndTime, int? UserId, string RouteIds, string TeamIds, int? TeamDetails, string Departments, string Lines, string Units, int TopLevelId = 0, int SubLevel = 0)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", UserId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return tasksPlanning.GetData(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Granularity, StartTime, EndTime, UserId, RouteIds, TeamIds, TeamDetails, Departments, Lines, Units, TopLevelId, SubLevel);
                }
                catch (System.Exception ex)
                {
                    log.Error("Error Get Task Planning Data - User " + UserId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", UserId));
                throw new HttpException(401, "You need to have minimum access level as guest to get trend planing data");
            }
        }


        /// <summary>
        /// Get detail for task planning report - Minimum access level 1 (Guest)
        /// </summary>
        /// <param name="VarId"></param>
        /// <param name="Granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="TopLevelId">The Id from which the report was initiated, before drill-down</param>
        /// <param name="SubLevel">The id of the current level being drilled-down</param>
        /// <param name="StartTime">The beginning period of the report</param>
        /// <param name="EndTime">The end period of the report</param>
        /// <param name="UserId">User asking for the report</param>
        /// <param name="RouteIds">The list of IDs representing routes to include in the report</param>
        /// <param name="TeamIds">The list of IDs representing teams to include in the report</param>
        /// <param name="TeamDetails">The level of details we want for Team (1=Summary  2=Routes  4=Plant Model)</param>
        /// <returns>List of Tasks Planning Report </returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/gettasksplanningdetail")]
        public List<TasksPlanning> GetTasksPlanningDetail(int VarId, int Granularity, string StartTime, string EndTime, int? UserId, string RouteIds, string TeamIds, int? TeamDetails, int TopLevelId = 0, int SubLevel = 0)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", UserId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }


            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return tasksPlanning.GetDetail(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], VarId, Granularity, StartTime, EndTime, UserId, RouteIds, TeamIds, TeamDetails, TopLevelId, SubLevel);
                }
                catch (System.Exception ex)
                {
                    log.Error("Error Get Task Planning Detail - User " + UserId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", UserId));
                throw new HttpException(401, "You need to have minimum access level as guest to get task planing detail");
            }
        }


        /// <summary>
        /// Get data for multiple assignments report - Minimum access level 1 (Guest)
        /// </summary>
        /// <param name="LinesList">Prod lines list</param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/getmultipleassignments")]
        public List<MultipleAssignments> GetMultipleAssignmentsData(string LinesList)
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
                    return multipleAssignments.GetData(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], LinesList);
                }
                catch (System.Exception ex)
                {
                    log.Error("Error Get Multiple assignments data - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get multiple assignments data");
            }
                
        }

        /// <summary>
        /// Get data for unassigned task - Minimum access level 1 (Guest)
        /// </summary>
        /// <param name="PLIds">Prod lines list</param>
        /// <param name="RouteFlag">true or false</param>
        /// <param name="TeamFlag">true or false</param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/report/getunassignedtasks")]
        public List<UnassignedTasks> GetUnassignedTasksData(string PLIds, bool RouteFlag = false, bool TeamFlag = false)
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
                    return unassignedTasks.GetData(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], PLIds, RouteFlag, TeamFlag);
                }
                catch (System.Exception ex)
                {
                    log.Error("Error Get Unassigned Task Data - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get multiple assignments data");
            }

        }

        /// <summary>
        /// Get Data for task scheduling errors - Minimum access level 1(Guest)
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
        [Route("api/report/schedulingerrors")]
        public List<ReportSchedulingErrors> Get(string deptIds = null, string lineIds = null, string masterIds = null, string slaveIds = null, string groupIds = null, string variableIds = null)
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
                    return reportSchedulingErrors.GetTaskList(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], deptIds, lineIds, masterIds, slaveIds, groupIds, variableIds);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Schedulling Errors - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get multiple assignments data");
            }
        }
    }
}
