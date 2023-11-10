using eCIL.Helper;
using eCIL.Filters;
using eCIL_DataLayer;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using System.Web.Http.Description;
using static eCIL_DataLayer.Defect;

namespace eCIL.Controllers
{

    public class DefectsController : ApiController
    {
        private Defect defect;
        private UserRepository _UserRepository;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public DefectsController()
        {
            defect = new Defect();
            _UserRepository = new UserRepository();
        }

        /// <summary>
        /// Get defect types from eDH- Minimum access level - 2(Operator)
        /// </summary>
        /// <returns></returns>
        //Get api/defects/defecttypes
        [HttpGet]
        [eCILAuthorization]
        [Route("api/defects/defecttypes")]
        public List<DefectSelector> GetDefectTypes(string language)
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
                    var eDHToken = HttpContext.Current.Request.Headers["EDHAccessToken"];
                    return defect.GetDefectTypes(ConfigurationManager.ConnectionStrings["eDHWebService"].ConnectionString, eDHToken, language);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get defect types - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator (Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get defect types");
            }
                
        }

        /// <summary>
        /// Get defect components from eDH- Minimum access level - 2(Operator)
        /// </summary>
        /// <returns></returns>
        //Get api/defects/defectcomponents
        [HttpGet]
        [eCILAuthorization]
        [Route("api/defects/defectcomponents")]
        public List<DefectSelector> GetDefectComponents(string language)
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
                    var eDHToken = HttpContext.Current.Request.Headers["EDHAccessToken"];
                    return defect.GetDefectComponents(ConfigurationManager.ConnectionStrings["eDHWebService"].ConnectionString, eDHToken, language);
                }
                catch (Exception ex)
                {
                    log.Error("Error get defects components - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator (Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get defect components");
            }  
        }

        /// <summary>
        /// Get defectHowFound List from eDH- Minimum access level - 2(Operator)
        /// </summary>
        /// <returns></returns>
        //Get api/defects/defecthowfoundlist
        [HttpGet]
        [eCILAuthorization]
        [Route("api/defects/defecthowfoundlist")]
        public List<DefectSelector> GetDefectHowFoundList(string language)
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
                    var eDHToken = HttpContext.Current.Request.Headers["EDHAccessToken"];
                    return defect.GetDefectHowFoundList(ConfigurationManager.ConnectionStrings["eDHWebService"].ConnectionString, eDHToken, language);
                }
                catch (Exception ex)
                {
                    log.Error("Error get defect how found list - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator (Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get defect how found list");
            }
                
        }

        /// <summary>
        /// get defect priorities from eDH- Minimum access level - 2(Operator)
        /// </summary>
        /// <returns></returns>
        //Get api/defects/defectpriorities
        [HttpGet]
        [eCILAuthorization]
        [Route("api/defects/defectpriorities")]
        public List<DefectSelector> GetDefectPriorities(string language)
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
                    var eDHToken = HttpContext.Current.Request.Headers["EDHAccessToken"];
                    return defect.GetDefectPriorities(ConfigurationManager.ConnectionStrings["eDHWebService"].ConnectionString, eDHToken, language);
                }
                catch (Exception ex)
                {
                    log.Error("Error get defect priorities - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator(Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get defect defect priorities");
            }
                
        }


        /// <summary>
        /// Get Instance Opened Defects- Minimum access level - 2(Operator)
        /// </summary>
        /// <param name="TestId"></param>
        /// <returns></returns>
        //Get api/defects/getinstanceopeneddefects
        [HttpGet]
        [eCILAuthorization]
        public List<DefectHistory> GetInstanceOpenedDefects(Int64 TestId)
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
                    return defect.GetInstanceOpenedDefects(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], TestId);
                }
                catch (Exception ex)
                {
                    log.Error("Error get Instance opened defects - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator(Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get all instance opened defects for a task");
            }
               
        }

        /// <summary>
        /// Get Task Opened Defects- Minimum access level - 2(Operator)
        /// </summary>
        /// <param name="VarId"></param>
        /// <returns></returns>
        //Get api/defects/gettaskopeneddefects
        [HttpGet]
        [eCILAuthorization]
        public List<DefectHistory> GetTaskOpenedDefects(int VarId)
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
                    return defect.GetTaskOpenedDefects(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], VarId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Task Opened Defects - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator(Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get all opened defects for a task");
            }
                
        }

        /// <summary>
        /// Get Defects History- Minimum access level - 2(Operator)
        /// </summary>
        /// <param name="VarId"></param>
        /// <param name="NbrBack"></param>
        /// <returns></returns>
        //Get api/defects/getdefectshistory
        [HttpGet]
        [eCILAuthorization]
        public List<DefectHistory> GetDefectsHistory(int VarId, int NbrBack)
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
                    return defect.GetDefectsHistory(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], VarId, NbrBack);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Defects History - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator (Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get the defect history for a task");
            }
                
        }

        /// <summary>
        /// Get FL defects from eDH- Minimum access level - 2(Operator)
        /// </summary>
        /// <param name="Credentials"></param>
        /// <param name="DepartmentId"></param>
        /// <param name="ProdLineId"></param>
        /// <param name="ProdUnitId"></param>
        /// <returns></returns>
        //Get api/defects/getfldefects
        [HttpGet]
        [eCILAuthorization]
        [Route("api/defects/getfldefects")]
        public List<FLDefects> GetFLDefects(string Credentials, string DepartmentId, string ProdLineId, string ProdUnitId)
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
                    var eDHToken = HttpContext.Current.Request.Headers["EDHAccessToken"];
                    return defect.GetFLDefects(ConfigurationManager.ConnectionStrings["eDHWebService"].ConnectionString, eDHToken, Credentials, DepartmentId, ProdLineId, ProdUnitId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get FL Defects - User " + userId.ToString() + ": " + ex.Message);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator(Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get FL defects");
            }
                
        }

        /// <summary>
        /// Add a deffect to eDH - Minimum access level - 2(Operator)
        /// </summary>
        /// <param name="Defect"></param>
        /// <returns></returns>
        //Get api/defects/adddefect
        [HttpPost]
        [eCILAuthorization]
        [Route("api/defects/adddefect")]
        public string AddDefect([FromBody]CILDefect Defect)
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
                    var eDHToken = HttpContext.Current.Request.Headers["EDHAccessToken"];
                    return defect.AddDefect(Defect, ConfigurationManager.ConnectionStrings["eDHWebService"].ConnectionString, eDHToken);
                }
                catch (Exception ex)
                {
                    log.Error("Error Add Defect - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator(Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to add a defect");
            }
               
        }


        /// <summary>
        /// Get Plant Model by FLCode
        /// </summary>
        /// <param name="FLCode"></param>
        /// <returns></returns>
        //Get api/defects/getplantmodelbyflcode
        [HttpGet]
        [eCILAuthorization]
        [Route("api/defects/getplantmodelbyflcode")]
        public FLPlantModel GetPlantModelByFLCode(string FLCode)
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
                    return defect.GetPlantModelByFLCode(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], FLCode);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Plant Model by FLCode - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator(Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get the Plant Model by FLCode");
            }

        }

        /// <summary>
        /// Get eMag Defect Details
        /// </summary>
        /// <param name="VarId"></param>
        /// <param name="ColumnTime"></param>
        /// <returns></returns>
        //Get api/defects/getemagdefectdetails
        [HttpGet]
        [eCILAuthorization]
        public List<DefectHistory> GetEmagDefectDetails(int VarId, string ColumnTime)
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
                    return defect.GetEmagDefectDetails(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], VarId, ColumnTime);
                }
                catch (Exception ex)
                {
                    log.Error("Error get emag defect details - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Operator(Read/Write)", userId));
                throw new HttpException(401, "You need to have minimum access level as operator to get the emag defect details");
            }

        }
    }
}
