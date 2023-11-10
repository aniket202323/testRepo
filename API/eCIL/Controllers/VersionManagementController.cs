using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web;
using System.Web.Http;
using System.Web.Http.Filters;
using eCIL.Filters;
using eCIL_DataLayer;
using System.Configuration;
using System.Collections;
using System.Threading.Tasks;
using System.IO;
using HttpContext = System.Web.HttpContext;
using eCIL.Helper;
using System.Web.Http.Description;

namespace eCIL.Controllers
{

    public class VersionManagementController : ApiController
    {

        private ExcelTask et;
        private UserRepository _UserRepository;
        private static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public VersionManagementController()
        {
            et = new ExcelTask();
            _UserRepository = new UserRepository();
        }
        /// <summary>
        /// GET data from the raw data file - Access level 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="sheet"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/versionmanagement/readdatafromexcelfile")]
        //GET api/versionmanagement/readDatafFromExcelFile?path=C:\\Excel_sheet\\gvTasks.xls&sheet=sheet
        public List<ExcelTask> ReadDataFromExcelFile(int userId, string sheet, string path)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
            //DirectoryInfo directory = new DirectoryInfo(targetLocation);
            //string tempPath = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}";
            //string path = directory.GetFiles(tempPath + "*.*").First().FullName;

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {

                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                var exceltask = new List<ExcelTask>();
                try
                {
                    exceltask = et.ReadDatafFromExcelFile(path, sheet);
                }
                catch(Exception ex)
                {
                    log.Error("User id" + userId.ToString() + " Error during reading data from Excel file: " + ex.Message.ToString() + " -- " + ex.StackTrace);
                    throw new HttpException(500, "Errors during reading excel file!");
                    
                }
                return exceltask;
            }
            else
            {
                log.Info(String.Format("User {0} doesn't has Access level as admin to read data from excel file uploaded", userId));
                throw new HttpException(401, "You need to have Access level as admin.");
            }
        }

        /// <summary>
        /// Validation step - Access Level 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="sheet"></param>
        /// <param name="linelevelcomparision"></param>
        /// <param name="modulelevelcomparision"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/versionmanagement/readandvalidaterawdatafile")]
        public List<ValidatedTask> ReadandValidateRawDatafile(int userId,string path, string sheet, bool linelevelcomparision, bool modulelevelcomparision)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
            //string path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xlsx";

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {

                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                    return et.RawDataFileValidation(path, sheet, linelevelcomparision, modulelevelcomparision);
                }catch(Exception ex)
                {
                    log.Error("User id" + userId.ToString() + ' ' + "Error during validation data from Excel File: " + ex.Message.ToString() + " -- " + ex.StackTrace);
                    throw new HttpException(500, "Error during validation data from Excel File: " + ex.Message.ToString());
                }
                
            }
             else
                {
                    log.Info(String.Format("User {0} doesn't has Access level as admin to validate data from excel file.", userId));
                    throw new HttpException(401, "You need to have Access level as admin.");
                }   

        }

        /// <summary>
        /// Get proficy data from database - Access level 4(Admin)
        /// </summary>
        /// <param name="lineLevelComparision"></param>
        /// <param name="moduleLeveComparision"></param>
        /// <param name="plId"></param>
        /// <param name="puId"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/versionmanagement/readproficydata")]
        public string ReadProficyData(string path, bool lineLevelComparision, bool moduleLeveComparision, string plId, string puId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];
            var userId = _UserRepository.GetUserIdFromToken(jwtToken);

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                string errormessage = string.Empty;

                try
                {
                    var result = new List<PlantModel.ProficyDataSource>();
                    result = et.ReadProficyData(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], lineLevelComparision, moduleLeveComparision, plId, puId);
                    //check for unique VM IDs 

                    if (result.Count() != result.Select(x => x.VMId).Distinct().ToList().Count())
                        return "Non-Unique VM IDs were detected on the line in Proficy";
                    return null;
                }
                catch (Exception ex)
                {
                    log.Error("User id" + userId.ToString() + ' ' + "Error during reading proficy data: " + ex.Message.ToString() + " -- " + ex.StackTrace);
                    return ex.Message.ToString();

                }
            }
            else
            {
                log.Info(String.Format("User {0} doesn't has Access level as admin to read proficy data.", userId));
                throw new HttpException(401, "You need to have Access level as admin.");
            }

        }

        /// <summary>
        /// Step 4 - ValidatePlantModel - Access Level - 4(Admin)
        /// </summary>
        /// <param name="linelevelcomparision"></param>
        /// <param name="modulelevelcomparision"></param>
        /// <param name="lineId"></param>
        /// <param name="slaveUnitId"></param>
        /// <param name="userId"></param>
        /// <param name="sheet"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/versionmanagement/validateProficyPlantModelConfiguration")]
        public List<string> ValidateProficyPlantModelConfiguration(string path,bool linelevelcomparision, bool modulelevelcomparision, int lineId, int slaveUnitId, int userId, string sheet)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
            //string path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xlsx";

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                var plantmodeldata = new List<PlantModel.PlantModelData>();
                var exceltask = new List<ExcelTask>();
                var resulterrormessagelist = new List<string>();
                if (linelevelcomparision == true)
                {
                    try
                    {
                        plantmodeldata = et.GetLineHierarchyInfo(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], lineId);

                    }catch(Exception ex)
                    {
                        log.Error("User id" + userId.ToString() + ' ' + "Error getting Line Hierarchy for lineId= " + lineId + " " + ex.Message + " -- " + ex.StackTrace);
                        throw new HttpException(500, "Error getting line hierarchy for lineId=" + lineId);
                    } 
                    try
                    {
                        resulterrormessagelist = ValidateLineLevelData(plantmodeldata, path, sheet);
                    }
                    catch(Exception ex)
                    {
                        log.Error("User id" + userId.ToString() + ' ' + "Error during validation data for line level. "  + ex.Message + " -- " + ex.StackTrace);
                        throw new HttpException(600, "Error during validation data for line level");
                    }
                    if (resulterrormessagelist.Count() > 0)
                        return resulterrormessagelist;
                }
                else if (modulelevelcomparision == true)
                {
                    try
                    {
                        plantmodeldata = et.GetModuleHierarchyInfo(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], slaveUnitId);
                    }
                    catch(Exception ex)
                    {
                        log.Error("User id" + userId.ToString() + ' ' + "Error getting module hierarchy info for slaveUnitId= " + slaveUnitId + " " + ex.Message + " -- " + ex.StackTrace);
                        throw new HttpException(500, "Error getting module hierarchy info for slaveunitId=" + slaveUnitId);
                    }
                }
                    
                try
                {
                    resulterrormessagelist = PlantModelConfigurationValidation(plantmodeldata, modulelevelcomparision);
                }
                catch(Exception ex)
                {
                    log.Error("User id" + userId.ToString() + ' ' + "Error validating plant model configuration" + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, "Error validating plant model configuration");
                }
                

                //if (resulterrormessagelist.Count() > 0)
                //    return resulterrormessagelist;


                //else if (linelevelcomparision == true)
                //{
                //    try
                //    {
                //        exceltask = et.ReadDatafFromExcelFile(path, sheet);
                //    }catch(Exception ex)
                //    {
                //        log.Error("User id" + userId.ToString() + ' ' + "Error reading data from excel file uploaded - " + ex.Message + " -- " + ex.StackTrace);
                //        throw new HttpException(500,"Error reading data from excel file uploaded");
                //    }
                //    try
                //    {
                //        resulterrormessagelist = et.AddNewModulestoPlantModelDataSource(plantmodeldata, exceltask);
                //    }catch(Exception ex)
                //    {
                //        log.Error("User id" + userId.ToString() + ' ' + "Error aading new modules to plant model datasource - " + ex.Message + " -- " + ex.StackTrace);
                //        throw new HttpException(500, "Error ading new modules to plant model datasource");
                //    }
                    
                //}

                if (resulterrormessagelist.Count() > 0)
                    return resulterrormessagelist;
                else
                    return null;
            }
            else
            {
                log.Info(String.Format("User {0} doesn't has Access level as admin to validate proficy plant model data configuration", userId));
                throw new HttpException(401, "You need to have minimum access level as admin.");
            }


        }


        /// <summary>
        /// After step 4 - AddNewModulestoPlantModelDataSource - Access Level - 4(Admin)
        /// </summary>
        /// <param name="linelevelcomparision"></param>
        /// <param name="modulelevelcomparision"></param>
        /// <param name="lineId"></param>
        /// <param name="slaveUnitId"></param>
        /// <param name="userId"></param>
        /// <param name="sheet"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/versionmanagement/addNewModulestoPlantModelDataSource")]
        public List<PlantModel.PlantModelData> AddNewModulestoPlantModelDataSource(string path, bool linelevelcomparision, bool modulelevelcomparision, int lineId, int slaveUnitId, int userId, string sheet)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
            //string path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xlsx";

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }


            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {

                var plantmodeldata = new List<PlantModel.PlantModelData>();
                var resultplantmodeldata = new List<PlantModel.PlantModelData>();
                var exceltask = new List<ExcelTask>();

                if (linelevelcomparision == true)
                {
                    try
                    {
                        plantmodeldata = et.GetLineHierarchyInfo(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], lineId);

                    }
                    catch (Exception ex)
                    {
                        log.Error("User id" + userId.ToString() + ' ' + "Error getting Line Hierarchy for lineId= " + lineId + " " + ex.Message + " -- " + ex.StackTrace);
                        throw new HttpException(500, "Error getting line hierarchy for lineId=" + lineId);
                    }

                }
                else if (modulelevelcomparision == true)
                {
                    try
                    {
                        plantmodeldata = et.GetModuleHierarchyInfo(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], slaveUnitId);
                    }
                    catch (Exception ex)
                    {
                        log.Error("User id" + userId.ToString() + ' ' + "Error getting module hierarchy info for slaveUnitId= " + slaveUnitId + " " + ex.Message + " -- " + ex.StackTrace);
                        throw new HttpException(500, "Error getting module hierarchy info for slaveunitId=" + slaveUnitId);
                    }
                }

                if (linelevelcomparision == true)
                {
                    try
                    {
                        exceltask = et.ReadDatafFromExcelFile(path, sheet);
                    }
                    catch (Exception ex)
                    {
                        log.Error("User id" + userId.ToString() + ' ' + "Error reading data from excel file uploaded - " + ex.Message + " -- " + ex.StackTrace);
                        throw new HttpException(500, "Error reading data from excel file uploaded");
                    }
                    try
                    {
                        resultplantmodeldata = et.AddNewModulestoPlantModelDataSource(plantmodeldata, exceltask);
                   
                    }
                    catch (Exception ex)
                    {
                        log.Error("User id" + userId.ToString() + ' ' + "Error aading new modules to plant model datasource - " + ex.Message + " -- " + ex.StackTrace);
                        throw new HttpException(500, "Error ading new modules to plant model datasource");
                    }

                   
                }
                return resultplantmodeldata;
            }
            else
            {
                log.Info(String.Format("User {0} doesn't has Access level as admin to validate proficy plant model data configuration", userId));
                throw new HttpException(401, "You need to have minimum access level as admin.");
            }

          
        }


        /// <summary>
        /// Step 5 - Compare - Access Level - 4(Admin)
        /// </summary>
        /// <param name="moduleLevelComparision"></param>
        /// <param name="userId"></param>
        /// <param name="sheet"></param>
        /// <param name="plId"></param>
        /// <param name="puId"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/versionmanagement/compareRawDataAndProficy")]
        //GET api/versionmanagement/compareRawDataAndProficy?moduleLevelComparision=true&path=C:\\Excel_sheet\\gvTasks.xls&sheet=Sheet&plId=56&puId=868
        public string CompareRawDataAndProficy(string path, bool moduleLevelComparision, int userId, string sheet, int plId, int puId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
            //string path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xlsx";

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                
            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                    return et.CompareRawDataAndProficy(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], moduleLevelComparision, path, sheet, plId, puId);
                }
                catch (Exception ex)
                {
                    log.Error("User id" + userId.ToString() + " Error during comparison between raw data and Proficy - " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(600, "Error occuered during comparison between raw data and proficy");
                }
            }
            else
            {
                log.Info(String.Format("User {0} doesn't has Aaccess level as admin to compare raw data with proficy", userId));
                throw new HttpException(401, "You need to have Access level as admin.");
            }
                
        }

        /// <summary>
        ///  Step 5 - Compare - Access level - 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="sheet"></param>
        /// <param name="lineLevelComparision"></param>
        /// <param name="moduleLevelComparision"></param>
        /// <param name="plId"></param>
        /// <param name="puId"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/versionmanagement/taskToUpdate")]

        public List<TaskEdit> TaskToUpdate(string path, int userId, string sheet, bool lineLevelComparision, bool moduleLevelComparision, int plId, int puId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];


            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }

            

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                    //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
                    //string path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xlsx";
                    return et.TaskToUpdate(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], path, sheet, lineLevelComparision, moduleLevelComparision, plId, puId);
                }
                catch (Exception ex)
                {
                    log.Error("User id" + userId.ToString() + " Error during updating task - " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Info(String.Format("User {0} doesn't has Access level as admin updating tasks", userId));
                throw new HttpException(401, "You need to have Access level as admin.");
            }
        }

        /// <summary>
        /// Step 5 - GetLineVersionStatistics - Access Level - 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="sheet"></param>
        /// <param name="linelevelcomparision"></param>
        /// <param name="lineId"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/versionmanagement/getLineVersionStatistics")]
        public List<PlantModel.LineVersion> GetLineVersionStatistics(string path,int userId, string sheet, bool linelevelcomparision, int lineId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
            //string path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xlsx";

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
                

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                    var result = et.GetLineVersionStatistics(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], path, sheet, linelevelcomparision, lineId);
                    return result;
                }
                catch (Exception ex)
                {
                    log.Error("User id" + userId.ToString() + " Error getting line version statistics - " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
            else
            {
                log.Info(String.Format("User {0} doesn't has Access level as admin to get line version statistics", userId));
                throw new HttpException(401, "You need to have minimum access level as admin.");
            }
            
        }


        /// <summary>
        /// GetModuleVersionStatistics - Access Level - 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <param name="sheet"></param>
        /// <param name="modulelevelcomparision"></param>
        /// <param name="puId"></param>
        /// <returns></returns>
        [HttpGet]
        [eCILAuthorization]
        [Route("api/versionmanagement/getModuleVersionStatistics")]
        public List<PlantModel.ModuleVersion> GetModuleVersionStatistics(int userId,string path, string sheet, bool modulelevelcomparision, int puId)
        {
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
            //string path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xlsx";

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                try
                {
                    var result =  et.GetModuleVersionStatistics(ConfigurationManager.ConnectionStrings["ServerName"].ConnectionString + ConfigurationManager.AppSettings["DatabaseConnection"], path, sheet, modulelevelcomparision, puId);
                    return result;
                }
                catch (Exception ex)
                {
                    log.Error("User id" + userId.ToString() + " Error during getting module version - " + ex.Message + " -- " + ex.StackTrace);
                    throw new HttpException(500, ex.Message);
                }
            }
             else
            {
                log.Info(String.Format("User {0} doesn't has Access level as admin to get module version statistics", userId));
                throw new HttpException(401, "You need to have minimum access level as admin.");
            }  

        }

        /// <summary>
        /// Upload excel file - Access Level 4(Admin)
        /// </summary>
        /// <param name="userId"></param>
        /// <returns></returns>
        [HttpPost]
        [eCILAuthorization]
        [Route("api/versionmanagement/fileupload")]
        public async Task<string> Upload(int userId)
        {
            string result = string.Empty;
            string path = string.Empty;
            var jwtToken = HttpContext.Current.Request.Headers["AuthToken"];

            if (_UserRepository.CheckJwtToken(jwtToken) == -2)
            {
                log.Error(String.Format("User {0} trying to use an expired token!", userId));
                throw new HttpException(402, "Your token is expired. Please request a new token");
            }
               

            if (_UserRepository.CheckJwtToken(jwtToken) == 4)
            {
                if (!Request.Content.IsMimeMultipartContent())
                {
                    log.Error("User id" + userId.ToString() + " Error: UnsupportedMediaType for file.");
                    throw new HttpResponseException(HttpStatusCode.UnsupportedMediaType);
                }
                

                var provider = new MultipartMemoryStreamProvider();
                await Request.Content.ReadAsMultipartAsync(provider);
                foreach (var file in provider.Contents)
                {
                    var filename = file.Headers.ContentDisposition.FileName.Trim('\"');
                    var buffer = await file.ReadAsByteArrayAsync();
                    //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
                    string targetLocation = System.Web.Hosting.HostingEnvironment.MapPath("~/Files/");

                    if (filename.EndsWith(".xls"))
                        path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xls";
                    else if(filename.EndsWith(".xlsx"))
                        path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xlsx";

                    string folder = Path.GetDirectoryName(path);
                    try
                    {
                        if (!(Directory.Exists(folder)))
                        {
                            Directory.CreateDirectory(folder);
                        }
                    }
                    catch (Exception ex)
                    {
                        log.Error("User id" + userId.ToString() + " Error creating Files directory - " + ex.Message + " -- " + ex.StackTrace);
                        throw new HttpException(500, ex.Message);
                    }
                    try
                    {
                        
                        File.WriteAllBytes(path, buffer);
                    }catch(Exception ex)
                    {
                        log.Error("User id" + userId.ToString() + " Error writting in " + path + " -- " + ex.Message + " -- " + ex.StackTrace);
                        throw new HttpException(" Error writting in " + path + " -- " + ex.Message);
                        
                    }
                    
                }

                return path;
            }
            else
            {
                log.Info(String.Format("User {0} doesn't has Access level as admin updating tasks", userId));
                throw new HttpException(401, "You need to have minimum access level as admin.");
            }
        }

        #region Utilies
        [ApiExplorerSettings(IgnoreApi = true)]
        public List<string> ValidateLineLevelData(List<PlantModel.PlantModelData> plantModelData, string path, string sheet)
        {

            var errorMessageList = new List<string>();
            var exceltask = new List<ExcelTask>();

            if ((plantModelData.Count()) == 0)
                errorMessageList.Add("There is no FL2 configured on any Master Unit of this line in Proficy.");
            else
            {
                exceltask = et.ReadDatafFromExcelFile(path, sheet);
                var PlantModelDataFL2 = new Hashtable();
                var ExcelTaskFL2 = new Hashtable();
                for (int i = 0; i < plantModelData.Count(); i++)
                {

                    if (!(PlantModelDataFL2.ContainsValue(plantModelData[i].FL2)))
                        PlantModelDataFL2.Add(plantModelData[i].FL2, plantModelData[i].FL2);
                }

                for (int j = 0; j < exceltask.Count(); j++)
                {
                    if (!(ExcelTaskFL2.ContainsValue(exceltask[j].FL2)))
                        ExcelTaskFL2.Add(exceltask[j].FL2, exceltask[j].FL2);

                }

                foreach (DictionaryEntry de in ExcelTaskFL2)
                {
                    if (!(PlantModelDataFL2.ContainsValue(de.Value)))
                        errorMessageList.Add("FL2" + de.Value + "listed in the Raw Data file could not be located on the selected line in Proficy.");

                }

            }
            return errorMessageList;
        }

        [ApiExplorerSettings(IgnoreApi = true)]
        public List<string> PlantModelConfigurationValidation(List<PlantModel.PlantModelData> plantModelData, bool modulelevelcomparision)
        {
            var errormessagelist = new List<string>();
            string FL2FL3Key;
            string UniqueFL3F4Key;
            var GroupFL4s = new Hashtable();
            var ModuleFL3s = new Hashtable();
            var plantmodelFl1 = new Hashtable();
            var plantmodelFL2 = new Hashtable();
            var plantmodelFL3 = new Hashtable();
            var plantmodelFL2Fl3ModeuleDesc = new Hashtable();
            var fl2fl3moduledesc = new List<ExcelTask.Fl2Fl3ModuleDesc>();
            var fl2fl3moduledescobj = new ExcelTask.Fl2Fl3ModuleDesc(plantModelData[0].FL2, plantModelData[0].FL3, plantModelData[0].SlaveUnitDesc);
            fl2fl3moduledesc.Add(fl2fl3moduledescobj);
            bool Objfound;

            foreach (var plantmodeldataObj in plantModelData)
            {
                Objfound = false;
                if (!(plantmodelFl1.ContainsValue(plantmodeldataObj.FL1)))
                    plantmodelFl1.Add(plantmodeldataObj.FL1, plantmodeldataObj.FL1);

                if (!(plantmodelFL2.ContainsValue(plantmodeldataObj.FL2)))
                    plantmodelFL2.Add(plantmodeldataObj.FL2, plantmodeldataObj.FL2);

                if (modulelevelcomparision == true)
                {
                    if (!(plantmodelFL3.ContainsValue(plantmodeldataObj.FL3)))
                        plantmodelFL3.Add(plantmodeldataObj.FL3, plantmodeldataObj.FL3);
                }

                foreach (var fl2fl3moduledescobj1 in fl2fl3moduledesc)
                {
                    if ((fl2fl3moduledescobj1.Compare(plantmodeldataObj.FL2, plantmodeldataObj.FL3, plantmodeldataObj.SlaveUnitDesc)))
                    {
                        Objfound = true;
                        break;
                    }
                }
                if (Objfound == false)
                {
                    var temp = new ExcelTask.Fl2Fl3ModuleDesc(plantmodeldataObj.FL2, plantmodeldataObj.FL3, plantmodeldataObj.SlaveUnitDesc);
                    fl2fl3moduledesc.Add(temp);
                }
            }


            foreach (DictionaryEntry de in plantmodelFl1)
            {
                if (string.IsNullOrEmpty(de.Value.ToString()))
                    errormessagelist.Add("Invalid Plant Model Configuration. FL1 information is missing.");
            }


            foreach (DictionaryEntry de in plantmodelFL2)
            {
                if (string.IsNullOrEmpty(de.Value.ToString()))
                    errormessagelist.Add("Invalid Plant Model Configuration. FL2 information is missing.");
            }

            if (modulelevelcomparision == true)
            {
                foreach (DictionaryEntry de in plantmodelFL3)
                {
                    if (string.IsNullOrEmpty(de.Value.ToString()))
                        errormessagelist.Add("Invalid Plant Model Configuration. FL3 information is missing.");
                }
            }

            foreach (var fl2fl3moduledescobj1 in fl2fl3moduledesc)
            {
                if (!(string.IsNullOrEmpty(fl2fl3moduledescobj1.FL3)))
                {
                    FL2FL3Key = string.Format("{0}-{1}", fl2fl3moduledescobj1.FL2, fl2fl3moduledescobj1.FL3);
                    if (ModuleFL3s.Contains(FL2FL3Key))
                        errormessagelist.Add("Invalid Plant Model Configuration. Two modules under the same FL2 cannot have the same FL3. FL2-FL3 " + FL2FL3Key + " is duplicate");
                    else
                        ModuleFL3s.Add(FL2FL3Key, FL2FL3Key);
                }
            }

            foreach (var plantmodeldataObj in plantModelData)
            {
                if ((!(string.IsNullOrEmpty(plantmodeldataObj.FL4))) && (!(DBNull.Value.Equals(plantmodeldataObj.FL3))))
                {
                    UniqueFL3F4Key = string.Format("{0}-{1}-{2}-{3}", plantmodeldataObj.MasterUnitDesc, plantmodeldataObj.SlaveUnitDesc, plantmodeldataObj.FL3, plantmodeldataObj.FL4);
                    if (GroupFL4s.Contains(UniqueFL3F4Key))
                        errormessagelist.Add("Invalid Plant Model Configuration. Two Groups cannot have the same FL4 on a Module.");
                    else
                        GroupFL4s.Add(UniqueFL3F4Key, UniqueFL3F4Key);
                }
            }

            return errormessagelist;

        }

        [ApiExplorerSettings(IgnoreApi = true)]
        [HttpDelete]
        [Route("api/versionmanagement/deletefile")]
        public string DeleteFile(int userId, string path)
        {
            //string targetLocation = HttpContext.Current.Server.MapPath("~/Files/");
            //string path = $@"{targetLocation}Excel_VersionManagement_{ userId.ToString()}.xls";
            try
            {
                File.Delete(path);
                return "Success";
            }catch(Exception ex)
            {
                log.Error("User id" + userId.ToString() + " Error during deleting excel file uploaded - " + ex.Message + " -- " + ex.StackTrace);
                return ex.Message;
            }
            
        }
        #endregion
    }
}
