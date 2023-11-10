using eCIL.Helper;
using eCIL.Filters;
using eCIL_DataLayer;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Configuration;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using static eCIL_DataLayer.Route;

namespace eCIL.Controllers
{

    public class TourStopController : ApiController
    {
        private TourStop tour;
        private TourStopInfo tourStopInfo;
        private UserRepository _UserRepository;
        private Utilities utilities;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public TourStopController()
        {
            tour = new TourStop();
            tourStopInfo = new TourStopInfo();
            _UserRepository = new UserRepository();
            utilities = new Utilities();
        }



        /// <summary>
        /// Add a new tourstop - Access level 4(Admin)
        /// </summary>
        /// <param name="Route"></param>
        /// <returns></returns>
        // POST api/tourstop
        [HttpPost]
        [eCILAuthorization]
        [Route("api/tourstop/AddTourStop")]
        public int Post([FromBody] TourStop tourstop)
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
                    return tour.AddTourStop(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourstop);
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
        /// Get all  Var_Id for specific tour stop
        /// </summary>
        /// <returns></returns>
        // GET api/TourStop/getTourStopInfo
        [HttpGet]
        [eCILAuthorization]
        [Route("api/TourStop/getTourStopInfo")]
        public List<TourStopTask> getTourStopInfo(int routeId)
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
                    return tourStopInfo.getTourStopInfo(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], routeId);
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
        /// Get all tour stop for specific route
        /// </summary>
        /// <returns></returns>
        // GET api/TourStop/getTourStop
        [HttpGet]
        [eCILAuthorization]
        [Route("api/TourStop/getTourStop")]
        public List<TourStopMap> getTourStop(int routeId)
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
                    return tourStopInfo.getTourStop(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], routeId);
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
        /// Get tourMap image for specific tourstop
        /// </summary>
        /// <returns></returns>
        // GET api/TourStop/getTourMapImage
        [HttpGet]
        [eCILAuthorization]
        [Route("api/TourStop/getTourMapImage")]
        public Byte[] getTourMapImage(int tourId)
        {
            Byte[] tourMapImage;
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);
            string filename = string.Empty;
            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }


            if (_UserRepository.CheckJwtToken(jwtToken) >= 3)
            {
                try
                {
                    filename = tourStopInfo.getTourMapImage(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourId);
                    if (filename != null && filename.Length > 0)
                    {
                        tourMapImage =  utilities.GetImage(filename, ConfigurationManager.AppSettings["TourMapImageFolderPath"]);
                    }
                    else
                    {
                        throw new HttpException("No image to show for selected TourStop");
                    }
                  
                }
                catch (Exception ex)
                {
                    log.Error("Error fetching tourMap image " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (Level 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as line manager to get specific QR Information");
            }
            return tourMapImage;
        }

        /// <summary>
        /// Get tourMap image count for specific image name
        /// </summary>
        /// <returns></returns>
        // GET api/TourStop/getTourMapImageCount
        [HttpGet]
        [eCILAuthorization]
        [Route("api/TourStop/getTourMapImageCount")]
        public int getTourMapImageCount(string tourMap)
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
                    return tourStopInfo.getTourMapImageCount(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourMap);

                }
                catch (Exception ex)
                {
                    log.Error("Error providing tourMap image count " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
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
        ///Assign tasks to a tour stop - access level 4 (Admin)
        /// </summary>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/tourstop/updatetourstoptasks")]
        public string UpdateTourStopTasks([FromBody] TourStop tourstop)
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
                    return tour.UpdateTourStopTask(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourstop);
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
        /// Update tour stop description
        /// </summary>
        /// <returns></returns>
        // Put api/UpdateTourStopDesc
        [HttpPut]
        [eCILAuthorization]
        [Route("api/tourstop/updateTourStopDesc")]
        public string updateTourStopDesc([FromBody] TourStop tourstop)
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
                    return tour.UpdateTourStopDesc(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourstop);
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
        
        [HttpPost]
        [eCILAuthorization]
        [Route("api/tourstop/uploadTourMapImage")]
        public  string UploadTourMapImage()
        {
            string result ;
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);
           
            string tourId = HttpContext.Current.Request.Form["tourId"];
            string routeId = HttpContext.Current.Request.Form["routeId"];
            HttpPostedFile httpPostedFile = HttpContext.Current.Request.Files["file"];

            if (httpPostedFile == null) 
            {

                throw new HttpException("No file selected");
            }
          
            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }


            if ((_UserRepository.CheckJwtToken(jwtToken) == 4) || (_UserRepository.CheckJwtToken(jwtToken) == 3))
            {
                try
                {
                    string folderPath = ConfigurationManager.AppSettings["TourMapImageFolderPath"];
                    
                    string fileName = httpPostedFile.FileName;
                    string concatFileName = routeId + "_" + tourId;
                    fileName = fileName.Replace(fileName.Split('.')[0], concatFileName);


                    fileName = utilities.SaveImage(httpPostedFile, fileName, ConfigurationManager.AppSettings["TourMapImageFolderPath"]);

                    if (fileName.Length > 0)
                    {
                        TourStop tourStopFileObj = new TourStop();
                        tourStopFileObj.TourMap = fileName;
                        tourStopFileObj.TourId = Convert.ToInt32(tourId);// will take tour ID from UI and then upload image against it
                        result = tour.UpdateTourMapLink(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourStopFileObj);
                    }
                }
                catch (Exception ex)
                {
                    log.Error("Error Uploading TourMap image - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to upload TourMap image");
            }

            return "Image Uploaded.";
        }

        /// <summary>
        /// copy tour stop map image from other tour stop
        /// </summary>
        /// <returns></returns>
        // Put api/CopyTourStopMapImage
        [HttpPut]
        [eCILAuthorization]
        [Route("api/tourstop/CopyTourStopMapImage")]
        public string CopyTourStopMapImage([FromBody] TourStop tourStop)
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
                    return tourStop.UpdateTourMapLink(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourStop);
                    
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
        /// unlink image and delete if it is last tourstop using that image
        /// </summary>
        /// <returns></returns>
        // Put api/UnlinkTourStopMapImage
        [HttpPut]
        [eCILAuthorization]
        [Route("api/tourstop/UnlinkTourStopMapImage")]
        public int unlinkTourStopMapImage([FromBody] TourStop tourStop)
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
                    tour.UnlinkTourStopMapImage(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourStop);
                    int fileCount = tourStopInfo.getTourMapImageCount(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourStop.TourMap);
                     if (fileCount == 0)
                    {
                        utilities.DeleteImage(tourStop.TourMap, ConfigurationManager.AppSettings["TourMapImageFolderPath"]);
                    }
                     
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
            return 1;
        }

        /// <summary>
        /// Delete a tourstop - Access level - 4 (Admin)
        /// </summary>
        /// deletes TourStop and check if image is not used for any tourStop then delete the image as well
        /// <returns></returns>
        // DELETE api/DeleteTourStop
        [HttpDelete]
        [eCILAuthorization]
        public string DeleteTourStop([FromBody]TourStop tourStop)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);
            string filename = string.Empty;
            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if ((_UserRepository.CheckJwtToken(jwtToken) == 4) || (_UserRepository.CheckJwtToken(jwtToken) == 3))
            {
                try
                {
                    filename = tour.DeleteTourStop(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], tourStop, userId);
                    if (filename != null && filename.Length > 0)
                    {
                        int fileCount = tourStopInfo.getTourMapImageCount(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], filename);
                        if (fileCount == 0)
                        {
                            utilities.DeleteImage(tourStop.TourMap, ConfigurationManager.AppSettings["TourMapImageFolderPath"]);
                        }
                    }
                }
                catch (Exception ex)
                {
                    log.Error("Error Delete a Tourstop - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to delete a route");
            }

            return "1";    
        }

        /// <summary>
        /// Delete a tourstop Map image - Access level - 4 (Admin)
        /// </summary>
        /// This will delete the image from destination folder and unlink from all the tourstops
        /// <returns></returns>
        // DELETE api/DeleteTourStopMap Image
        [HttpDelete]
        [eCILAuthorization]
        [Route("api/tourstop/DeleteTourStopMapImage")]
        public string DeleteTourStopMapImage(string filename)
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
                    tour.DeleteTourMapImage(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], filename);
                    if (filename != null && filename.Length > 0)
                    {
                        utilities.DeleteImage(filename, ConfigurationManager.AppSettings["TourMapImageFolderPath"]);
                    }

                }
                catch (Exception ex)
                {
                    log.Error("Error Delete a Tourstop - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to delete a route");
            }

            return "tour stop deleted along with tour stop map image if any.";
        }

    }
}
