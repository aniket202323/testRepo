using eCIL.Helper;
using eCIL.Filters;
using eCIL_DataLayer;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using System.Web.UI.WebControls;
using static eCIL_DataLayer.PlantModel;

namespace eCIL.Controllers
{

    public class PlantModelController : ApiController
    {
        private PlantModel plantModel;
        private UserRepository _UserRepository;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public PlantModelController()
        {
            plantModel = new PlantModel();
            _UserRepository = new UserRepository();
        }

        /// <summary>
        /// Get departments - Minimum Access Level 1(Guest)
        /// </summary>
        /// <returns></returns>
        // GET api/plantmodel
        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getdepartments")]
        public List<Department> GetDepartments(int userId)
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
                    return plantModel.GetDepartments(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], userId);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get departments - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest (Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get departments");
            }
                
        }

        /// <summary>
        /// Get production lines  - Minimum Access Level 1(Guest)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="deptId"></param>
        /// <returns></returns>
        // GET api/plantmodel
        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getlines")]
        public List<Line> GetProductionLines(int userId, string deptId = "0",int isRouteManagement =0 )
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
                    return plantModel.GetProductionLines(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], userId, isRouteManagement, deptId);
                }
                catch (Exception ex)
                {
                    log.Error("Error get production lines - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
           }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get eCIL Production Lines");
            }
                
        }

        /// <summary>
        /// get eCIL Master Units for a list of lines  - Minimum Access Level 1(Guest)
        /// </summary>
        /// <param name="lineId"></param>
        /// <param name="firstItemBlank"></param>
        /// <returns></returns>
        // GET api/plantmodel/lineId=183
        // GET api/plantmodel/lineId=183?firstItemBlank=true

        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getmasterunits")]
        public List<MasterUnit> GetMasterUnitsForALine(string lineId, bool firstItemBlank = false)
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
                    return plantModel.GetMasterUnits(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], lineId, firstItemBlank);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Master units for a line - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get eCIL Master Untis");
            }
                
        }

        /// <summary>
        /// Get eCIL slave units for a list of  master units  - Minimum Access Level 1(Guest)
        /// </summary>
        /// <param name="masterId"></param>
        /// <param name="firstItemBlank"></param>
        /// <returns></returns>
        // GET api/plantmodel/masterId=3691
        // GET api/plantmodel/masterId=3691?firstItemBlank=true
        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getslaveunits")]
        public List<SlaveUnit> GetSlaveForAMasterUnit(string masterId, bool firstItemBlank = false)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("Error Get Slave For Master Unit - User {0} trying to use an expired token.", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) >= 1)
            {
                try
                {
                    return plantModel.GetSlaveUnits(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], masterId, firstItemBlank);
                }
                catch (Exception ex)
                {
                    log.Error("Get Slave For A Master Unit - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get eCIL Slave units");
            }
                
        }

        /// <summary>
        /// Get eCIL slave units for a list of  master units  - Minimum Access Level 1(Guest)
        /// </summary>
        /// <param name="slaveUnitId"></param>
        /// <param name="firstItemBlank"></param>
        /// <returns></returns>
        // GET api/plantmodel/getproductiongroups=382
        // GET api/plantmodel/getproductiongroups=382?firstItemBlank=true
        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getproductiongroups")]
        public List<ProductionGroups> GetProductionGroups(string slaveUnitId, bool firstItemBlank = false)
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
                    return plantModel.GetProductionGroups(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], slaveUnitId, firstItemBlank);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get Production Groups - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get eCIL Variables groups");
            }
                
        }

        /// <summary>
        /// Get plantModel for editMode in TaskManagement.
        /// If the user will not pass any plantModelLevel, the default value will be 4 to get the department, line, master unit, slave units and groups.
        /// We don't care about the variables level because the user will not be able to edit anything for variables(tasks)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="plId"></param>
        /// <param name="plantModelLevel"> an integer and represents the lowerLevel for the data(Department = 0, Line = 1, MasterUnit = 2, SlaveUnit = 3, Group = 4, Variable = 5)</param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getplantmodeleditable")]
        public List<PlantModelEdit> GetPlantModelEditable(int userId, int? plId, int? plantModelLevel)
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
                    return plantModel.GetPlantModelEditMode(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], userId,plId,plantModelLevel);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get plant model editable - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Administrator", userId));
                throw new HttpException(401, "You need to have Access level as Administrator to get plant model editable");
            }
        }
        /// <summary>
        /// Get the plant model by FL for task management  - Minimum Access Level 1(Guest)
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        public List<FLObject> GetPlantModelByFl()
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
                    return plantModel.GetPlantModelByFL(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], true, true, true, true);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get PlantModel by FL - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get eCIL Variables groups");
            }
                
        }

        /// <summary>
        /// Get All Fl1 from th server  - Minimum Access Level 1(Guest)
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getfl1")]
        public List<FLObject> GetAllFl1()
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
                    return plantModel.GetPlantModelByFL(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], true, false, false, false);
                }
                catch (Exception ex)
                {
                    log.Error("Error Get All FL1 - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Line Manager (LEvel 3)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get eCIL Fl1");
            }
                
        }

        /// <summary>
        /// Get All Fl2 for a list of FL1  - Minimum Access Level 1(Guest)
        /// </summary>
        /// <param name="Fl1"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getfl2")]
        public List<FLObject>GetAllFL2ForFL1(string Fl1)
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
                List<FLObject> result = new List<FLObject>();
                try
                {
                    var tempResult = plantModel.GetPlantModelByFL(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], false, true, false, false);
                    var FL1List = Fl1.Split(new String[] { "," }, StringSplitOptions.None);
                    foreach (string fl in FL1List)
                    {
                        int FlId = 0;
                        Int32.TryParse(fl, out FlId);
                        var tempResult1 = tempResult.Where(x => x.ParentId == FlId && x.Level == 1).ToList();
                        result = result.Concat(tempResult1).ToList();
                    }
                    return result;

                }
                catch (Exception ex)
                {
                    log.Error("Error Get all FL2 for an FL1 - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get eCIL Fl2");
            }
            
        }


        /// <summary>
        /// Get All Fl3 for a list of FL2  - Minimum Access Level 1(Guest)
        /// </summary>
        /// <param name="Fl2"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getfl3")]
        public List<FLObject> GetAllFL3ForFL2(string Fl2)
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
                List<FLObject> result = new List<FLObject>();
                try
                {
                    var tempResult = plantModel.GetPlantModelByFL(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], false, false, true, false);
                    var FL2List = Fl2.Split(new String[] { "," }, StringSplitOptions.None);
                    foreach (string fl in FL2List)
                    {
                        int FlId = 0;
                        Int32.TryParse(fl, out FlId);
                        var tempResult1 = tempResult.Where(x => x.ParentId == FlId && x.Level == 2).ToList();
                        result = result.Concat(tempResult1).ToList();
                    }
                    return result;

                }
                catch (Exception ex)
                {
                    log.Error("Error Get all FL3 for a list of FL 2 - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Minimum access level: Guest(Read)", userId));
                throw new HttpException(401, "You need to have minimum access level as guest to get eCIL Fl3");
            }
            
        }

        /// <summary>
        /// Get All Fl4 for a list of FL3  - Minimum Access Level 1(Guest)
        /// </summary>
        /// <param name="Fl3"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/plantmodel/getfl4")]
        public List<FLObject> GetAllFL4ForFL3(string Fl3)
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
                List<FLObject> result = new List<FLObject>();
                try
                {
                    var tempResult = plantModel.GetPlantModelByFL(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], false, false, false, true);
                    var FL3List = Fl3.Split(new String[] { "," }, StringSplitOptions.None);
                    foreach (string fl in FL3List)
                    {
                        int FlId = 0;
                        Int32.TryParse(fl, out FlId);
                        var tempResult1 = tempResult.Where(x => x.ParentId == FlId && x.Level == 3).ToList();
                        result = result.Concat(tempResult1).ToList();
                    }
                    return result;

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
                throw new HttpException(401, "You need to have minimum access level as guest to get eCIL Fl4");
            }
            
        }

        /// <summary>
        /// Update FL1 or eCIL_LineVersion in Task Management - Access Level : Administrator
        /// </summary>
        /// <param name="lineDesc">Prod Line Description</param>
        /// <param name="udpName"> "FL1" or "eCIL_LineVersion"</param>
        /// <param name="udpValue">if user wants to update the FL1 or eCIL_LineVersion,he needs provide a value</param>
        /// <param name="toDelete">true - UDP will be deleted, false - udp will be updated</param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/plantmodel/updateprodlineudp")]
        public string UpdateProdLineUDP(string lineDesc, string udpName, string udpValue, bool toDelete)
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
                List<FLObject> result = new List<FLObject>();
                try
                {
                    return plantModel.UpdateLineUDP(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"],lineDesc,udpName,udpValue,toDelete);

                }
                catch (Exception ex)
                {
                    log.Error("Error Updating FL1 or LineVersion  - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Administrator", userId));
                throw new HttpException(401, "You need to have Access level as Administrator to update FL1 or LineVersion");
            }
        }

        /// <summary>
        /// Update FL2, FL3 or eCIL_ModuleFeatureVersion in Task Management - Access Level : Administrator
        /// </summary>
        /// <param name="lineDesc"> Prod Line Description</param>
        /// <param name="unitDesc"> Master Unit Description or Slave Unit Description</param>
        /// <param name="udpName">"FL2" or "FL3" or "eCIL_ModuleFeatureVersion"</param>
        /// <param name="udpValue">if user wants to update the FL2, FL3 or eCIL_ModuleFeatureVersion, he needs provide a value</param>
        /// <param name="toDelete"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/plantmodel/updateprodunitsudp")]
        public string UpdateProdUnitUDP(string lineDesc, string unitDesc, string udpName, string udpValue, bool toDelete)
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
                List<FLObject> result = new List<FLObject>();
                try
                {
                    return plantModel.UpdateUnitUDP(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], lineDesc, unitDesc, udpName, udpValue, toDelete);

                }
                catch (Exception ex)
                {
                    log.Error("Error Updating FL2, FL3 or ModuelFeature  - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Administrator", userId));
                throw new HttpException(401, "You need to have Access level as Administrator to update FL2, FL3 or LineVersion");
            }
        }

        /// <summary>
        /// Update zFL4 in Task Management - Access Level : Administrator
        /// </summary>
        /// <param name="lineDesc">Prod Line Description</param>
        /// <param name="unitDesc">Unit Description</param>
        /// <param name="groupDesc"> Var Group Description</param>
        /// <param name="udpName">"FL4"</param>
        /// <param name="udpValue">if user wants to update the FL4, he needs provide a value</param>
        /// <param name="toDelete"></param>
        /// <returns></returns>
        [HttpPut]
        [eCILAuthorization]
        [Route("api/plantmodel/updategroupudps")]
        public string UpdateGroupsUDP(string lineDesc, string unitDesc, string groupDesc, string udpName, string udpValue, bool toDelete)
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
                List<FLObject> result = new List<FLObject>();
                try
                {
                    return plantModel.UpdateGroupUDP(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], lineDesc, unitDesc, groupDesc, udpName, udpValue, toDelete);

                }
                catch (Exception ex)
                {
                    log.Error("Error Updating FL4  - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Administrator", userId));
                throw new HttpException(401, "You need to have Access level as Administrator to update FL4");
            }
        }
        /// <summary>
        /// Add new Module - Access Level 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="plantModelData"></param>
        /// <returns></returns>
        [HttpPost]
        [eCILAuthorization]
        [Route("api/plantmodel/addmodule")]
        public void AddModule(int userId, [FromBody]PlantModelData plantModelData)
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
                    if (!string.IsNullOrEmpty(plantModelData.SlaveUnitDesc) && !string.IsNullOrEmpty(plantModelData.FL3))
                        plantModel.AddModule(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], plantModelData, userId);
                    else
                    {
                        log.Info(String.Format("User {0} trying to insert a module without to specify the FL3 and Module description.", userId));
                        throw new HttpException(600, "Module Description and FL3 can not be empty string or null.");
                    }
                        
                }
                catch (Exception ex)
                {
                    log.Error("Error Adding Module - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin(Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to add eCIL Modules");
            }
                
        }

        /// <summary>
        /// Add new Production Group -  Access Level 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="plantModelData"></param>
        /// <returns></returns>
        [HttpPost]
        [eCILAuthorization]
        [Route("api/plantmodel/addproductiongroup")]
        public void AddProductionGroup(int userId, [FromBody]PlantModelData plantModelData)
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
                        plantModel.AddProductionGroup(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], plantModelData, userId);                 
                }
                catch (Exception ex)
                {
                    log.Error("Error Add Production Group - User " + userId.ToString() + ": " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, ex.Message);
                }
            }
            else
            {
                log.Error(String.Format("User {0} doesn't have the right access to call this. Access level: Admin (Level 4)", userId));
                throw new HttpException(401, "You need to have minimum access level as admin to add eCIL Production Group");
            }
               
        }
    }
}
