using eCIL.Helper;
using eCIL.Filters;
using eCIL_DataLayer;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;

namespace eCIL.Controllers
{
    public class QRCodeController : ApiController
    {
        private QRCodes qrCodes;
        private QRCodes.QRCodeProps qrCodeProps;
        private QRCodes.QRLineDetails qrLineDetails;

        private UserRepository _UserRepository;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public QRCodeController()
        {
            qrCodes = new QRCodes();
            qrCodeProps = new QRCodes.QRCodeProps();
            qrLineDetails = new QRCodes.QRLineDetails();
            _UserRepository = new UserRepository();
        }

        /// <summary>
        /// Save Task QR code details in database
        /// </summary>
        /// <returns></returns>
        // POST api/routes
        [HttpPost]
        [eCILAuthorization]
        [Route("api/QRCodes/saveQRCodeInfo")]
        public string SaveQRCodeInfo([FromBody] QRCodes.QRCodeProps qrCodeProps)
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
                    return qrCodes.SaveQRCodeInfo(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], qrCodeProps, userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error in saveQRCodeInfoForTask Adding Task QR info" + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to save QR Information");
            }

        }

        /// <summary>
        /// Update details of QR Name for edit button
        /// </summary>
        /// <returns></returns>
        // Put api/routes
        [HttpPost]
        [eCILAuthorization]
        [Route("api/routes/updateQRCodeName")]
        public string UpdateQRCodeName([FromBody] QRCodes qrDetailsProps)
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
                    return qrCodes.UpdateQRCodeName(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], qrDetailsProps, userId);
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
                throw new HttpException(401, "You need to have minimum access level as admin to update QR Information");
            }

        }

  
        /// <summary>
        /// Update details of QR Name for edit button By Task
        /// </summary>
        /// <returns></returns>
        // Put api/QRCodes/updateQRCodeInfoForTasks
        [HttpPost]
        [eCILAuthorization]
        [Route("api/QRCodes/updateQRCodeInfoForTask")]
        public string updateQRCodeInfoForTask([FromBody] QRCodes.QRCodeProps qrCodeProps)
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
                    return qrCodes.updateQRCodeInfoForTask(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], qrCodeProps, userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error editing QR Info for task " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to update QR Information");
            }

        }
        /// <summary>
        /// Generate QR Code for specific route
        /// </summary>
        /// <returns></returns>
        // GET api/routes/generateQRCodeForRoute
        [HttpPost]
        [eCILAuthorization]
        [Route("api/routes/getQRCodeForTask")]
        public Byte[] getQRCodeForTask([FromBody] QRCodes.QRCodeProps qrCodeProps)
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
                    return qrCodes.getQRCodeForTask(qrCodeProps);

                }
                catch (Exception ex)
                {
                    log.Error("Error generateQRCodeForRoute - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to generate QRCode For Route");
            }

        }

        /// <summary>
        /// Generate QR Code for specific route
        /// </summary>
        /// <returns></returns>
        // GET api/routes/getQRCodeForTaskById
        [HttpPost]
        [eCILAuthorization]
        [Route("api/routes/getQRCodeForTaskById")]
        public Byte[] getQRCodeForTaskById([FromBody] QRCodes.QRCodeProps qrCodeProps)
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
                    return qrCodes.getQRCodeForTaskById(qrCodeProps);

                }
                catch (Exception ex)
                {
                    log.Error("Error generateQRCodeForRoute - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to generate QRCode For Route");
            }

        }

        /// <summary>
        /// Generate QR Code for specific route
        /// </summary>
        /// <returns></returns>
        // GET api/routes/generateQRCodeForRoute
        [HttpGet]
        [eCILAuthorization]
        [Route("api/routes/generateQRCodeForRoute")]
        public Byte[] generateQRCodeForRoute(string RouteId, string mainUrl)
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
                    return qrCodes.generateQRCodeForRoute(RouteId, mainUrl);

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
                throw new HttpException(401, "You need to have minimum access level as admin to generate QR Code");
            }

        }

        /// <summary>
        /// Get all saved QR Code details from database
        /// </summary>
        /// <returns></returns>
        // GET api/routes/getAllQRCodeInfoForRoute
        [HttpGet]
        [eCILAuthorization]
        [Route("api/QRCodes/getAllQRCodeInfoForRoute")]
        public List<QRCodes> getAllQRCodeInfoForRoute()
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
                    return qrCodes.getAllQRCodeInfoForRoute(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
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
                throw new HttpException(401, "You need to have minimum access level as line manager to get all QR Information");
            }

        }

        /// <summary>
        /// Get all saved QR Code details from database for Task
        /// </summary>
        /// <returns></returns>
        // GET api/routes/getAllQRCodeInfoForTask
        [HttpGet]
        [eCILAuthorization]
        [Route("api/QRCodes/getAllQRCodeInfoForTask")]
        public List<QRCodes.QRCodeProps> getAllQRCodeInfoForTask()
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
                    return qrCodes.getAllQRCodeInfoForTask(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get saved QR code for Task " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all QR Information");
            }

        }

        /// <summary>
        /// Get all saved QR Code details from database for Task
        /// </summary>
        /// <returns></returns>
        // GET api/routes/getAllQRCodeInfoForTask
        [HttpGet]
        [eCILAuthorization]
        [Route("api/QRCodes/getInfoForQRId")]
        public List<QRCodes.QRLineDetails> getInfoForQRId(string qrId, Boolean IsRouteId)
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
                    return qrCodes.getInfoForQRId(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], qrId, IsRouteId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get saved QR code for Task " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get specific QR Information");
            }

        }

        /// <summary>
        /// Get all  QR Code details from database of QR_Id for URL 
        /// </summary>
        /// <returns></returns>
        // GET api/QRCodes/getURLInfoByQRId
        [HttpGet]
        [eCILAuthorization]
        [Route("api/QRCodes/getURLInfoByQRId")]
        public QRCodes.QRLineDetails getURLInfoByQRId(string qrId)
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
                    return qrCodes.getURLInfoByQRId(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], qrId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get saved QR code for Task " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get specific QR Information");
            }

        }

        /// <summary>
        /// Delete QR Code 
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        [HttpPost]
        [eCILAuthorization]
        [Route("api/routes/deleteQRCode")]
        public string DeleteQRCode([FromBody] QRCodes qrDetailsProps)
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
                    return qrCodes.DeleteQRCode(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], qrDetailsProps);
                }
                catch (Exception ex)
                {
                    log.Error("Error deleting QR info for route " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to delete QR Information");
            }

        }

       
        /// <summary>
        /// Get all saved TourStop QR Code details from database 
        /// </summary>
        /// <returns></returns>
        // GET api/routes/getAllQRCodeInfoForTourStop
        [HttpGet]
        [eCILAuthorization]
        [Route("api/QRCodes/getAllQRCodeInfoForTourStop")]
        public List<QRCodes.QRCodeTourStop> getAllQRCodeInfoForTourStop()
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
                    return qrCodes.getAllQRCodeInfoForTourStop(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get saved QR code for Task " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get all QR Information");
            }

        }

        /// <summary>
        /// Generate QR Code for specified Tour Stops
        /// </summary>
        /// <returns></returns>
        // GET api/routes/generateQRCodeForRoute
        [HttpPost]
        [eCILAuthorization]
        [Route("api/routes/getQRCodeForTourStop")]
        public List<Byte[]> getQRCodeForTourStop([FromBody] QRCodes.QRCodeTourStop qrCodeTourStop)
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
                    return qrCodes.getQRCodeForTourStop(qrCodeTourStop);

                }
                catch (Exception ex)
                {
                    log.Error("Error generateQRCodeForTourStop - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to generate QRCode For Route");
            }

        }

        /// <summary>
        /// Retrive the OpsHub Server configured on web config
        /// </summary>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/get-opshub-server")]
        public String getOpsHubServer()
        {
          return System.Configuration.ConfigurationManager.AppSettings["OpsHubServer"];
        }
            }
}