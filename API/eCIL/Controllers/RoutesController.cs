using eCIL.Helper;
using eCIL.Filters;
using eCIL_DataLayer;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using static eCIL_DataLayer.Route;

namespace eCIL.Controllers
{

    public class RoutesController : ApiController
    {
        private Route route;
        private UserRepository _UserRepository;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public RoutesController()
        {
            route = new Route();
            _UserRepository = new UserRepository();
        }

        /// <summary>
        /// Get all routes  - Minimum access level 3(Line Manager)
        /// </summary>
        /// <returns></returns>
        // GET api/routes
        [HttpGet]
        [eCILAuthorization]
        public List<Route> Get()
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
                    return route.GetAllRoutes(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error Getroutes - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all routes");
            }
                
        }

        /// <summary>
        /// Get all routes for a user  - Minimum access level 1(Guest)
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        // GET api/routes?userId=1850
        [HttpGet]
        [eCILAuthorization]
        public List<Route> Get(int userId)
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
                    return route.GetMyRoutes(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get All FL4 for a list of FL3 - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get all routes");
            }

        }

        /// <summary>
        /// get a specific route  - Minimum access level 3(Line Manager)
        /// </summary>
        /// <param name="RouteId"></param>
        /// <returns></returns>
        // GET api/routes/getrouteteams
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/getrouteteams")]
        public List<RouteTeams> GetRouteTeams(int RouteId)
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
                    return route.GetRouteTeams(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], RouteId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Route Teams - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all route teams");
            }
                
        }



        /// <summary>
        /// get tasks for a route - Minimum access level 3(Line Manager)
        /// </summary>
        /// <param name="RouteId"></param>
        /// <param name="LineIds"></param>
        /// <returns></returns>
        // GET api/routes/getroutetasks
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/getroutetasks")]
        public List<RouteTasks> GetRouteTasks(int RouteId, string LineIds = null)
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
                    return route.GetRouteTasks(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], RouteId, LineIds);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Route Task - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all route tasks");
            }
               
        }

        /// <summary>
        /// Get routes summary  - Minimum access level 3(Line Manager)
        /// </summary>
        /// <returns></returns>
        // GET api/routes/getroutessummary
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/getroutessummary")]
        public List<RoutesSummary> GetRoutesSummary()
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
                    return route.GetRoutesSummary(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Routes Summary - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all route summary");
            }
                
        }

        /// <summary>
        /// Get Route Teams - Minimum access level 3(Line Manager)
        /// </summary>
        /// <param name="RouteId"></param>
        /// <returns></returns>
        // GET api/routes/getreportrouteteams
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/getreportrouteteams")]
        public List<ReportRouteTeams> GetReportRouteTeams(int RouteId)
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
                    return route.GetReportRouteTeams(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], RouteId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Report ROute Teams - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all route teams");
            }
               
        }

        /// <summary>
        /// Get Route Tasks - Minimum access level 3(Line Manager)
        /// </summary>
        /// <param name="RouteId"></param>
        /// <returns></returns>
        // GET api/routes/getreportroutetasks
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/getreportroutetasks")]
        public List<ReportRouteTasks> GetReportRouteTasks(int RouteId)
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
                    return route.GetReportRouteTasks(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], RouteId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Report Route Tasks - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all route tasks");
            }
                
        }

        /// <summary>
        /// Get Route Tasks - Minimum access level 3(Line Manager)
        /// </summary>
        /// <param name="RouteId"></param>
        /// <returns></returns>
        // GET api/routes/getreportrouteactivity
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/getreportrouteactivity")]
        public Route GetReportRouteActivity(int RouteId)
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
                    return route.GetReportRouteActivity(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], RouteId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Report Route Activity - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all route tasks");
            }

        }

        /// <summary>
        /// Get all route teams - Minimum access level 3(Line Manager)
        /// </summary>
        /// <returns></returns>
        // GET api/routes/getreportallrouteteams
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/getreportallrouteteams")]
        public List<ReportRouteTeams> GetReportAllRouteTeams()
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
                    return route.GetReportAllRouteTeams(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get report all route teams - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all route teams");
            }
                
        }

        /// <summary>
        /// Get all Route Tasks - Minimum access level 3(Line Manager)
        /// </summary>
        /// <returns></returns>
        // GET api/routes/getreportallroutetasks
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/getreportallroutetasks")]
        public List<ReportRouteTasks> GetReportAllRouteTasks()
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
                    return route.GetReportAllRouteTasks(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get all route tasks - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all route tasks");
            }
                
        }

        /// <summary>
        /// Add a new route - Access level 4(Admin)
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        // POST api/routes
        [HttpPost]
        [eCILAuthorization]
        public string Post([FromBody] Route Route)
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
                    return route.AddRoute(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Route);
                }
                catch (Exception ex)
                {
                    log.Error("Error Adding a new route - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to add a route");
            }

        }


        /// <summary>
        /// Create a new display for the new route added - Access level 4(Admin)
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/routes/createroutedisplay")]
        public string CreateRouteDisplay([FromBody] Route Route, string url)
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
                    return route.CreateRouteDisplay(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Route, userId, ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString, url);
                }
                catch (Exception ex)
                {
                    log.Error("Error Adding a new route - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }

            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to add a route");
            }

        }

        /// <summary>
        /// Save a route - Access level 4 (Admin)
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        // PUT api/routes/UpdateSheetDesc
        [HttpPut]
        [eCILAuthorization]
        [Route("api/routes/UpdateSheetDesc")]
        public string UpdateSheetDesc([FromBody] Route Route)
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
                    return route.UpdateSheetDesc(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Route, userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Edit a route - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to edit a route");
            }

        }

        /// <summary>
        /// Save a route - Access level 4 (Admin)
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        // PUT api/routes/5
        [HttpPut]
        [eCILAuthorization]
        public string Put([FromBody] Route Route)
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
                    return route.UpdateRoute(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Route);
                }
                catch (Exception ex)
                {
                    log.Error("Error Edit a route - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to edit a route");
            }
                
        }


        /// <summary>
        /// Delete a route - Access level - 4 (Admin)
        /// </summary>
        /// <param name="RouteIds"></param>
        /// <returns></returns>
        // DELETE api/routes/5
        [HttpDelete]
        [eCILAuthorization]
        public string Delete(string RouteIds)
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
                    return route.DeleteRoute(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], RouteIds, userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Delete a route - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to delete a route");
            }
                
        }

        /// <summary>
        /// Assign teams for a route - Access level 4 (Admin)
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/routes/updaterouteteamsassociations")]
        public string UpdateRouteTeamsAssociations([FromBody] RouteAssociations Route)
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
                    return route.UpdateRouteTeamsAssociations(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Route);
                }
                catch (Exception ex)
                {
                    log.Error("Error Update Route Teams Associations - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access Level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to update a route");
            }
                
        }

        /// <summary>
        /// Assig Tasks to a Route - Acess level 4(Admin)
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/routes/updateroutetasksassociations")]
        public string UpdateRouteTasksAssociations([FromBody] RouteAssociations Route)
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
                    return route.UpdateRouteTasksAssociations(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Route);
                }
                catch (Exception ex)
                {
                    log.Error("Error Updating Route Tasks Associations - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to update a route");
            }
                
        }

        /// <summary>
        /// Assig Variables to a Display associated to a route  - Acess level 4(Admin)
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/routes/updatedisplayvariablesassociations")]
        public string UpdateDisplayVariablesAssociations([FromBody] RouteAssociations Route)
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
                    return route.UpdateDisplayVariablesAssociations(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Route, userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Updating Display Variables Associations - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to update a route");
            }

        }
        /// <summary>
        /// Find a Route Id for task  - Acess level 4(Admin)
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/findrouteId")]
        public int FindRouteId(int Var_Id)
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
                    return route.FindRouteId(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Var_Id);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Route Id: " + ex.Message);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 3 or 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to find a route");
            }
        }

        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/IsIntegratedRoute")]
        public Boolean IsIntegratedRoute(int Route_Id)
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
                    return route.IsIntegratedTourRoute(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Route_Id);
                }
                catch (Exception ex)
                {
                    log.Error("Error Checking Integrated Route: " + ex.Message);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 3 or 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to check for Integrated Route");
            }
        }

        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/CheckIfRouteHasQR")]
        public Boolean CheckIfRouteHasQR(string Route_Ids)
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
                    return route.CheckIfRouteHasQRCode(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], Route_Ids);
                }
                catch (Exception ex)
                {
                    log.Error("Error Checking QR Code for Route: " + ex.Message);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 3 or 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to check If there is any QR Code for this Route");
            }
        }
    }
}
