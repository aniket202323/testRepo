using eCIL.Areas.HelpPage;
using eCIL.Filters;
using eCIL.Helper;
using eCIL_DataLayer;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using System.Web.UI.WebControls.WebParts;
using static eCIL_DataLayer.Team;

namespace eCIL.Controllers
{
    public class TeamsController : ApiController
    {
        private Team team;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        private UserRepository _UserRepository;
        public TeamsController()
        {
            team = new Team();
            _UserRepository = new UserRepository();
        }

        /// <summary>
        /// Get all teams - minimum access level - 3(Line Manager)
        /// </summary>
        /// <returns></returns>
        // GET api/teams
        //[Authorize]
        [HttpGet]
        [eCILAuthorization]
        public List<Team> Get()
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }

            if (_UserRepository.CheckJwtToken(jwtToken) >= 3)
            {
                try
                {
                    return team.GetAllTeams(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("User id" + userId.ToString() + ' ' + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Info(String.Format("User {0} doesn't has minimum access level as line manager to get all teams",userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get teams");
            }
                
        }

        /// <summary>
        /// Get teams for a user - Minimum access level 1(guest)
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        // GET api/teams/userId=1850
        [HttpGet]
        [eCILAuthorization]
        public List<Team> Get(int userId)
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
                    return team.GetMyTeams(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], userId);
                }
                catch (Exception ex)
                {
                    log.Error("UserId " + userId.ToString() + " " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error("User {0} doesn't have the right access level to do thid action. Min access level required: Guest (Read)");
                throw new HttpException(401, "You need to have minimum access level as guest to get teams");
            }
                
        }

        /// <summary>
        /// Get users for a team -Minimum acces level 3
        /// </summary>
        /// <param name="TeamId"></param>
        /// <returns></returns>
        // GET api/teams/getteamsusers
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getteamsusers")]
        public List<TeamUsers> GetTeamUsers(int TeamId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expire token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if (_UserRepository.CheckJwtToken(jwtToken) >= 3)
            {
                try
                {
                    return team.GetTeamUsers(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], TeamId);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + " " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to execute this action. Min access level: Line Manager(Level 3)",userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get user for a team");
            }
                
        }

        /// <summary>
        /// Get tasks for a team - Minimum access level - 3 (Line Manager)
        /// </summary>
        /// <param name="TeamId"></param>
        /// <returns></returns>
        // GET api/teams/getteamtasks
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getteamtasks")]
        public List<TeamTasks> GetTeamTasks(int TeamId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} is using an expire token.",userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if (_UserRepository.CheckJwtToken(jwtToken) >= 3)
            {
                try
                {
                    
                    return team.GetTeamTasks(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], TeamId);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + " " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get team tasks");
            }
               
        }

        /// <summary>
        /// Get routes for a team - Minimum access level 3
        /// </summary>
        /// <param name="TeamId"></param>
        /// <returns></returns>
        // GET api/teams/getteamroutes
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getteamroutes")]
        public List<TeamRoutes> GetTeamRoutes(int TeamId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.",userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 3)
            {
                try
                {
                    return team.GetTeamRoutes(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], TeamId);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get team routes");
            }
                
        }

        /// <summary>
        /// Get team summary - Minimum access level 3
        /// </summary>
        /// <returns></returns>
        // GET api/teams/getteamssummary
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getteamssummary")]
        public List<TeamsSummary> GetTeamsSummary()
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
                    return team.GetTeamsSummary(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));

                throw new HttpException(401, "You need to have minimum access level as line manager to get team summary");
            }
               
        }

        /// <summary>
        /// Get routes for a team - Minimum access level 3
        /// </summary>
        /// <param name="TeamId"></param>
        /// <returns></returns>
        // GET api/teams/getreportteamroutes
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getreportteamroutes")]
        public List<ReportTeamRoutes> GetReportTeamRoutes(int TeamId)
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
                    return team.GetReportTeamRoutes(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], TeamId);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {

                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get team routes");
            }
                
        }

        /// <summary>
        /// Get Teams Routes - Minimum access level 3
        /// </summary>
        /// <returns></returns>
        // GET api/teams/getreportallteamroutes
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getreportallteamroutes")]
        public List<ReportTeamRoutes> GetReportAllTeamRoutes()
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
                    return team.GetReportAllTeamRoutes(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all team routes");
            }
                
        }

        /// <summary>
        /// Get Teams Users - Minimum access level 3
        /// </summary>
        /// <returns></returns>
        // GET api/teams/getreportallteamusers
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getreportallteamusers")]
        public List<ReportTeamUser> GetReportAllTeamUsers()
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
                    return team.GetReportAllTeamUsers(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get team users");
            }
                
        }

        /// <summary>
        /// Get teams tasks - Minimum access level 3
        /// </summary>
        /// <returns></returns>
        // GET api/teams/getreportallteamtasks
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getreportallteamtasks")]
        public List<ReportTeamTasks> GetReportAllTeamTasks()
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
                    return team.GetReportAllTeamTasks(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all team tasks");
            }
                
        }

        /// <summary>
        /// Get tasks for a team - Minimum access level 3
        /// </summary>
        /// <param name="TeamId"></param>
        /// <returns></returns>
        // GET api/teams/getreportteamtasks
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getreportteamtasks")]
        public List<ReportTeamTasks> GetReportTeamTasks(int TeamId)
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
                    return team.GetReportTeamTasks(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], TeamId);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get team tasks");
            }
                
        }

        /// <summary>
        /// Get users for a team - Minimum access level 3
        /// </summary>
        /// <param name="TeamId"></param>
        /// <returns></returns>
        // GET api/teams/getreportteamusers
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getreportteamusers")]
        public List<ReportTeamUsersAssociations> GetReportTeamUsers(int TeamId)
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
                    return team.GetReportTeamUsers(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], TeamId);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get team users");
            }
               
        }

        /// <summary>
        /// Get Crews for a team - Minimum access level 3
        /// </summary>
        /// <param name="TeamId"></param>
        /// <returns></returns>
        // GET api/teams/getreportteamcrews
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getreportteamcrews")]
        public List<ReportTeamCrewsAssociations> GetReportTeamCrews(int TeamId)
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
                    return team.GetReportTeamCrews(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], TeamId);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get team crews");
            }
                
        }

        /// <summary>
        /// Get all crews - Minimum access level 3
        /// </summary>
        /// <param name="LineId"></param>
        /// <returns></returns>
        // GET api/teams/getallcrews
        [HttpGet]
        [eCILAuthorization]
        [Route("api/teams/getallcrews")]
        public List<Crews> GetAllCrews(int LineId)
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
                    return team.GetAllCrews(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], LineId);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all crews");
            }
               
        }
        
        /// <summary>
        /// Create a team - Access level - 4(Admin) 
        /// </summary>
        /// <param name="Team"></param>
        /// <returns></returns>
        // POST api/teams
        [HttpPost]
        [eCILAuthorization]
        public string Post([FromBody] Team Team)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if ((_UserRepository.CheckJwtToken(jwtToken) == 4) || (_UserRepository.CheckJwtToken(jwtToken) == 3))
            {
                try
                {
                    return team.AddTeam(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Team);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to add a team");
            }
                
        }

        /// <summary>
        /// Save a team - Acess level 4(Admin)
        /// </summary>
        /// <param name="Team"></param>
        /// <returns></returns>
        // PUT api/teams/5
        [HttpPut]
        [eCILAuthorization]
        public string Put([FromBody] Team Team)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if ((_UserRepository.CheckJwtToken(jwtToken) == 4) || (_UserRepository.CheckJwtToken(jwtToken) == 3))
            {
                try
                {
                    return team.UpdateTeam(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Team);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to edit a team");
            }
               
        }

        /// <summary>
        /// Detele a list of teams - Access level 4 (Admin)
        /// </summary>
        /// <param name="TeamIds"></param>
        /// <returns></returns>
        // DELETE api/teams/5
        [HttpDelete]
        [eCILAuthorization]
        public string Delete(string TeamIds)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if ((_UserRepository.CheckJwtToken(jwtToken) == 4) || (_UserRepository.CheckJwtToken(jwtToken) == 3))
            {
                try
                {
                    return team.DeleteTeam(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], TeamIds);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    if (ex.Message.Contains("The DELETE statement conflicted with the REFERENCE constraint"))
                    {
                        throw new HttpException(500, "This team is linked to a defect, please address defect before deleting this team.");
                    }
                    else
                    {
                        throw new HttpException(500, ex.Message);
                    }
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to delete a team");
            }
                
        }

        /// <summary>
        /// Assign routes to a team - Access level 4 (Admin)
        /// </summary>
        /// <param name="Team"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/teams/updateteamroutesassociations")]
        public string UpdateTeamRoutesAssociations([FromBody] TeamsAssociations Team)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if ((_UserRepository.CheckJwtToken(jwtToken) == 4) || (_UserRepository.CheckJwtToken(jwtToken) == 3))
            {
                try
                {
                    return team.UpdateTeamRoutesAssociations(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Team);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to edit a team");
            }
                
        }

        /// <summary>
        /// Assign Users to a team - Access level 4 (Admin)
        /// </summary>
        /// <param name="Team"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/teams/updateteamusersassociations")]
        public string UpdateTeamUsersAssociations([FromBody] TeamsAssociations Team)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if ((_UserRepository.CheckJwtToken(jwtToken) == 4) || (_UserRepository.CheckJwtToken(jwtToken) == 3))
            {
                try
                {
                    return team.UpdateTeamUsersAssociations(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Team);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to edit a team");
            }
               
        }

        /// <summary>
        /// Assign tasks for a team - Access level 4 (Admin)
        /// </summary>
        /// <param name="Team"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/teams/updateteamtasksassociations")]
        public string UpdateTeamTasksAssociations([FromBody] TeamsAssociations Team)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if ((_UserRepository.CheckJwtToken(jwtToken) == 4) || (_UserRepository.CheckJwtToken(jwtToken) == 3))
            {
                try
                {
                    return team.UpdateTeamTasksAssociations(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Team);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to edit a team");
            }

        }

        /// <summary>
        /// Assign crews for a team - Access level 4(Admin)
        /// </summary>
        /// <param name="Team"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/teams/updateteamcrewroutes")]
        public string UpdateTeamCrewRoutes([FromBody] TeamCrewRoutes Team)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if ((_UserRepository.CheckJwtToken(jwtToken) == 4) || (_UserRepository.CheckJwtToken(jwtToken) == 3))
            {
                try
                {
                    return team.UpdateTeamCrewRoutes(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Team);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to edit a team");
            }
                
        }

    }
}
