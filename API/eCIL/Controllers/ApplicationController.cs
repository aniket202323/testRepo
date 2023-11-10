using System;
using eCIL.Filters;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using eCIL.Helper;
using eCIL_DataLayer;
using STI;

namespace eCIL.Controllers
{

    public class ApplicationController : ApiController
    {
        private Utilities utilities;
        private UserRepository _UserRepository;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public ApplicationController()
        {
            utilities = new Utilities();
            _UserRepository = new UserRepository();
        }

        /// <summary>
        /// Get the site name - minimum access level 1(Guest)
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/application/getsitename")]
        public string Get()
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
                    return utilities.GetSiteName(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    return ex.Message;
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest (Read)", userId));
                throw new HttpException(401, "Unauthorized access. You need minimum guest access on eCIL group to be able to get the site name.");
            }
        }

        /// <summary>
        /// Get the site language
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/application/getsitelang")]
        public string GetSiteLang()
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
                    return utilities.GetSiteLang(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error GetSiteLang - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest (Read)", userId));
                throw new HttpException(401, "Unauthorized access. You need minimum guest access on eCIL group to be able to get the site language.");
            }
        }

        /// <summary>
        /// Get the site parameter
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/application/getsiteparamspecsetting")]
        public int GetSiteParamSpecSetting()
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
                    return utilities.GetSiteParamSpecSetting(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);
                }
                catch (Exception ex)
                {
                    log.Error("Error GetSiteParamSpecSetting - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest (Read)", userId));
                throw new HttpException(401, "Unauthorized access. You need minimum guest access on eCIL group to be able to get the site language.");
            }
        }

        /// <summary>
        /// Minimum access - 1(Guest)
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/application/gettimeframes")]
        public Array GetTimeFrames()
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

                var sti = new STI.DatesManager(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"]);

                var contacts = new[]
                {
                    new
                    {
                        TimeFrameId = 1,
                        TimeFrameName = "Yesterday",
                        StartTime = STI.DatesManager.FormatDateTimeToString(sti.YesterdayStart(DateTime.Now)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(sti.YesterdayEnd(DateTime.Now))
                    },
                    new
                    {
                        TimeFrameId = 2,
                        TimeFrameName = "Today",
                        StartTime = STI.DatesManager.FormatDateTimeToString(sti.TodayStart(DateTime.Now)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(sti.TodayEnd(DateTime.Now))
                    },
                    new
                    {
                        TimeFrameId = 3,
                        TimeFrameName = "Tomorrow",
                        StartTime = STI.DatesManager.FormatDateTimeToString(sti.TomorrowStart(DateTime.Now)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(sti.TomorrowEnd(DateTime.Now))
                    },
                    new
                    {
                        TimeFrameId = 4,
                        TimeFrameName = "Last Week",
                        StartTime = STI.DatesManager.FormatDateTimeToString(sti.LastWeekStart(DateTime.Now)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(sti.LastWeekEnd(DateTime.Now))
                    },
                    new
                    {
                        TimeFrameId = 5,
                        TimeFrameName = "This Week",
                        StartTime = STI.DatesManager.FormatDateTimeToString(sti.ThisWeekStart(DateTime.Now)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(sti.ThisWeekEnd(DateTime.Now))
                    },
                    new
                    {
                        TimeFrameId = 6,
                        TimeFrameName = "Next Week",
                        StartTime = STI.DatesManager.FormatDateTimeToString(sti.NextWeekStart(DateTime.Now)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(sti.NextWeekEnd(DateTime.Now))
                    },
                     new
                    {
                        TimeFrameId = 7,
                        TimeFrameName = "Last Month",
                        StartTime = STI.DatesManager.FormatDateTimeToString(sti.LastMonthStart(DateTime.Now)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(sti.LastMonthEnd(DateTime.Now))
                    },
                    new
                    {
                        TimeFrameId = 8,
                        TimeFrameName = "This Month",
                        StartTime = STI.DatesManager.FormatDateTimeToString(sti.ThisMonthStart(DateTime.Now)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(sti.ThisMonthEnd(DateTime.Now))
                    },
                    new
                    {
                        TimeFrameId = 9,
                        TimeFrameName = "Next Month",
                        StartTime = STI.DatesManager.FormatDateTimeToString(sti.NextMonthStart(DateTime.Now)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(sti.NextMonthEnd(DateTime.Now))
                    },
                    new
                    {
                        TimeFrameId = 10,
                        TimeFrameName = "Last 30 Days",
                        StartTime = STI.DatesManager.FormatDateTimeToString(DateTime.Now.AddDays(-30)),
                        EndTime = STI.DatesManager.FormatDateTimeToString(DateTime.Now)
                    },
                    new
                    {
                        TimeFrameId = 11,
                        TimeFrameName = "Next 30 Days",
                        StartTime = STI.DatesManager.FormatDateTimeToString(DateTime.Now),
                        EndTime = STI.DatesManager.FormatDateTimeToString(DateTime.Now.AddDays(30))
                    }
                };

                return contacts;
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "Unauthorized access. You need minimum guest access on eCIL group to be able to use DatesManager.dll");
            }

        }
    }
}
