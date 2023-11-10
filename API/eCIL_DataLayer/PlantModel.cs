using log4net.Core;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;

namespace eCIL_DataLayer
{
    public class PlantModel
    {

        #region SubClasses
        public class PlantModelData
        {
            #region Variables
            private string departmentDec;
            private string lineDesc;
            private int lineId;
            private string masterUnitDesc;
            private int masterUnitId;
            private string slaveUnitDesc;
            private int slaveUnitId;
            private string productionGroupDesc;
            private string fL1;
            private string fL2;
            private string fL3;
            private string fL4;
            private string moduleFeatureVersion;
            private string lineVersion;
            private string errormessage;
            #endregion

            #region Properties
            public string DepartmentDesc { get => departmentDec; set => departmentDec = value; }
            public string LineDesc { get => lineDesc; set => lineDesc = value; }
            public int LineId { get => lineId; set => lineId = value; }
            public string MasterUnitDesc { get => masterUnitDesc; set => masterUnitDesc = value; }
            public int MasterUnitId { get => masterUnitId; set => masterUnitId = value; }
            public string SlaveUnitDesc { get => slaveUnitDesc; set => slaveUnitDesc = value; }
            public int SlaveUnitId { get => slaveUnitId; set => slaveUnitId = value; }
            public string ProductionGroupDesc { get => productionGroupDesc; set => productionGroupDesc = value; }
            public string FL1 { get => fL1; set => fL1 = value; }
            public string FL2 { get => fL2; set => fL2 = value; }
            public string FL3 { get => fL3; set => fL3 = value; }
            public string FL4 { get => fL4; set => fL4 = value; }
            public string ModuleFeatureVersion { get => moduleFeatureVersion; set => moduleFeatureVersion = value; }
            public string LineVersion { get => lineVersion; set => lineVersion = value; }
            public string ErrorMessage { get => errormessage; set => errormessage = value; }
            #endregion

            public PlantModelData()
            {
                DepartmentDesc = string.Empty;
                LineDesc = string.Empty;
                LineId = 0;
                MasterUnitDesc = string.Empty;
                MasterUnitId = 0;
                SlaveUnitDesc = string.Empty;
                SlaveUnitId = 0;
                ProductionGroupDesc = string.Empty;
                FL1 = string.Empty;
                FL2 = string.Empty;
                FL3 = string.Empty;
                FL4 = string.Empty;
                ModuleFeatureVersion = string.Empty;
                LineVersion = string.Empty;

            }

            public PlantModelData(string deptDesc, string lineDesc, int lineId, string masterUnitDesc, string slaveUnitDesc, string productionGroupDesc, string fL1, string fL2, string fL3, string fL4, string moduleFeatureVersion, string lineversion)
            {
                DepartmentDesc = deptDesc;
                LineDesc = lineDesc;
                LineId = lineId;
                MasterUnitDesc = masterUnitDesc;
                SlaveUnitDesc = slaveUnitDesc;
                ProductionGroupDesc = productionGroupDesc;
                FL1 = fL1;
                FL2 = fL2;
                FL3 = fL3;
                FL4 = fL4;
                ModuleFeatureVersion = moduleFeatureVersion;
                LineVersion = lineversion;

            }

        }

        public class ProficyDataSource
        {
            #region Variables
            private int varId;
            private string departmentDesc;
            private int deptId;
            private string lineDesc;
            private int lineId;
            private string masterUnitDesc;
            private int masterUnitId;
            private string slaveUnitDesc;
            private int slaveUnitId;
            private string productionGroupDesc;
            private int productionGroupId;
            private string taskDesc;
            private string fL1;
            private string fL2;
            private string fL3;
            private string fL4;
            private string criteria;
            private string duration;
            private string fixedFrequency;
            private string hazards;
            private string longTaskName;
            private string lubricant;
            private string method;
            private string nbrItems;
            private string nbrPeople;
            private string pPE;
            private string taskAction;
            private string taskFrequency;
            private string taskType;
            private string testTime;
            private string tools;
            private string vmId;
            private string taskId;
            private string taskLocation;
            private string scheduleScope;
            private string startDate;
            private string lineVersion;
            private string modulefeatueVersion;
            private string documentLinkPath;
            private string documentLinkTitle;
            private string qfactorType;
            private string primaryQFactor;
            private bool hSEFlag;
            private int shiftOffset;
            private string status;
            private string autopostpone;
            #endregion

            #region Properties

            public int VarId { get => varId; set => varId = value; }
            public string DepartmentDesc { get => departmentDesc; set => departmentDesc = value; }
            public int DeptId { get => deptId; set => deptId = value; }
            public string LineDesc { get => lineDesc; set => lineDesc = value; }
            public int LineId { get => lineId; set => lineId = value; }
            public string MasterUnitDesc { get => masterUnitDesc; set => masterUnitDesc = value; }
            public int MasterUnitId { get => masterUnitId; set => masterUnitId = value; }
            public string SlaveUnitDesc { get => slaveUnitDesc; set => slaveUnitDesc = value; }
            public int SlaveUnitId { get => slaveUnitId; set => slaveUnitId = value; }
            public string ProductionGroupDesc { get => productionGroupDesc; set => productionGroupDesc = value; }
            public int ProductionGroupId { get => productionGroupId; set => productionGroupId = value; }
            public string TaskDesc { get => taskDesc; set => taskDesc = value; }
            public string FL1 { get => fL1; set => fL1 = value; }
            public string FL2 { get => fL2; set => fL2 = value; }
            public string FL3 { get => fL3; set => fL3 = value; }
            public string FL4 { get => fL4; set => fL4 = value; }
            public string Criteria { get => criteria; set => criteria = value; }
            public string Duration { get => duration; set => duration = value; }
            public string FixedFrequency { get => fixedFrequency; set => fixedFrequency = value; }
            public string Hazards { get => hazards; set => hazards = value; }
            public string LongTaskName { get => longTaskName; set => longTaskName = value; }
            public string Lubricant { get => lubricant; set => lubricant = value; }
            public string Method { get => method; set => method = value; }
            public string NbrItems { get => nbrItems; set => nbrItems = value; }
            public string NbrPeople { get => nbrPeople; set => nbrPeople = value; }
            public string PPE { get => pPE; set => pPE = value; }
            public string TaskAction { get => taskAction; set => taskAction = value; }
            public string TaskFrequency { get => taskFrequency; set => taskFrequency = value; }
            public string TaskType { get => taskType; set => taskType = value; }
            public string TestTime { get => testTime; set => testTime = value; }
            public string Tools { get => tools; set => tools = value; }
            public string VMId { get => vmId; set => vmId = value; }
            public string TaskId { get => taskId; set => taskId = value; }
            public string TaskLocation { get => taskLocation; set => taskLocation = value; }
            public string ScheduleScope { get => scheduleScope; set => scheduleScope = value; }
            public string StartDate { get => startDate; set => startDate = value; }
            public string LineVersion { get => lineVersion; set => lineVersion = value; }
            public string ModulefeatueVersion { get => modulefeatueVersion; set => modulefeatueVersion = value; }
            public string DocumentLinkPath { get => documentLinkPath; set => documentLinkPath = value; }
            public string DocumentLinkTitle { get => documentLinkTitle; set => documentLinkTitle = value; }
            public string QfactorType { get => qfactorType; set => qfactorType = value; }
            public string PrimaryQFactor { get => primaryQFactor; set => primaryQFactor = value; }
            public bool HSEFlag { get => hSEFlag; set => hSEFlag = value; }
            public int ShiftOffset { get => shiftOffset; set => shiftOffset = value; }
            public string Status { get => status; set => status = value; }
            public string Autopostpone { get => autopostpone; set => autopostpone = value; }
            #endregion

            public ProficyDataSource()
            {

                VarId = 0;
                DepartmentDesc = string.Empty;
                DeptId = 0;
                LineDesc = string.Empty;
                LineId = 0;
                MasterUnitDesc = string.Empty;
                MasterUnitId = 0;
                SlaveUnitDesc = string.Empty;
                SlaveUnitId = 0;
                ProductionGroupDesc = string.Empty;
                ProductionGroupId = 0;
                TaskDesc = string.Empty;
                FL1 = string.Empty;
                FL2 = string.Empty;
                FL3 = string.Empty;
                FL4 = string.Empty;
                Criteria = string.Empty;
                Duration = string.Empty;
                FixedFrequency = string.Empty;
                Hazards = string.Empty;
                LongTaskName = string.Empty;
                Lubricant = string.Empty;
                Method = string.Empty;
                NbrItems = string.Empty;
                NbrPeople = string.Empty;
                PPE = string.Empty;
                TaskAction = string.Empty;
                TaskFrequency = string.Empty;
                TaskType = string.Empty;
                TestTime = string.Empty;
                Tools = string.Empty;
                VMId = string.Empty;
                TaskId = string.Empty;
                TaskLocation = string.Empty;
                ScheduleScope = string.Empty;
                StartDate = string.Empty;
                LineVersion = string.Empty;
                ModulefeatueVersion = string.Empty;
                DocumentLinkPath = string.Empty;
                DocumentLinkTitle = string.Empty;
                QfactorType = string.Empty;
                PrimaryQFactor = string.Empty;
                HSEFlag = false;
                ShiftOffset = 0;
                status = string.Empty;
                Autopostpone = "-1";
            }


        }

        public class LineVersion
        {
            #region Variables
            private string lineDesc;
            private string currentVersion;
            private string newVersion;
            private List<ModuleVersion> moduleVersion;
            #endregion

            #region Properties
            public string LineDesc { get => lineDesc; set => lineDesc = value; }
            public string CurrentVersion { get => currentVersion; set => currentVersion = value; }
            public string NewVersion { get => newVersion; set => newVersion = value; }
            public List<ModuleVersion> ModuleVersion { get => moduleVersion; set => moduleVersion = value; }
            #endregion
        }

        public class ModuleVersion : LineVersion
        {
            #region Variables
            private string moduleDesc;
            #endregion

            #region Properties
            public string ModuleDesc { get => moduleDesc; set => moduleDesc = value; }
            #endregion
        }
        public class Department
        {
            #region Variables
            private int deptId;
            private string deptDesc;
            #endregion

            #region Properties
            public int DeptId { get => deptId; set => deptId = value; }
            public string DeptDesc { get => deptDesc; set => deptDesc = value; }
            #endregion

            public Department(int id, string desc)
            {
                DeptId = id;
                DeptDesc = desc;
            }
        }

        public class Line
        {
            #region Variables
            private int lineId;
            private string lineDesc;
            #endregion

            #region Properties
            public int LineId { get => lineId; set => lineId = value; }
            public string LineDesc { get => lineDesc; set => lineDesc = value; }
            #endregion

            public Line(int id, string desc)
            {
                LineId = id;
                LineDesc = desc;
            }
        }

        public class MasterUnit
        {
            #region Variables
            private int masterId;
            private string masterDesc;
            #endregion

            #region Properties
            public int MasterId { get => masterId; set => masterId = value; }
            public string MasterDesc { get => masterDesc; set => masterDesc = value; }
            #endregion

            public MasterUnit(int id, string desc)
            {
                MasterId = id;
                MasterDesc = desc;
            }
        }

        public class SlaveUnit
        {
            #region Variables
            private int slaveId;
            private string slaveDesc;
            #endregion

            #region Properties
            public int SlaveId { get => slaveId; set => slaveId = value; }
            public string SlaveDesc { get => slaveDesc; set => slaveDesc = value; }
            #endregion

            public SlaveUnit(int id, string desc)
            {
                SlaveId = id;
                SlaveDesc = desc;
            }
        }

        public class ProductionGroups
        {
            #region Variables
            private int pugId;
            private string pugDesc;
            #endregion

            #region Properties
            public int PUGId { get => pugId; set => pugId = value; }
            public string PUGDesc { get => pugDesc; set => pugDesc = value; }
            #endregion

            public ProductionGroups(int id, string desc)
            {
                PUGId = id;
                PUGDesc = desc;
            }
        }
        public class FLObject
        {
            #region Variables
            private int id;
            private int parentId;
            private string itemDesc;
            private string flPath;
            private int level;
            private string levelType;
            #endregion

            #region Properties
            public int Id { get => id; set => id = value; }
            public int ParentId { get => parentId; set => parentId = value; }
            public string ItemDesc { get => itemDesc; set => itemDesc = value; }
            public string FLPath { get => flPath; set => flPath = value; }
            public int Level { get => level; set => level = value; }
            public string LevelType { get => levelType; set => levelType = value; }
            #endregion
        }

        #endregion

        #region Methods
        public List<Department> GetDepartments(string _connectionString, int userId, int accessLevel = 1)
        {
            var result = new List<Department>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetDepartmentsByUserSecurity", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@UserId", userId));
                command.Parameters.Add(new SqlParameter("@MinimumAccessLevel", accessLevel));
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        result.Add(new Department(reader.GetInt32(0), reader.GetString(1)));
                    }
                    reader.Close();
                }
            }
            return result;

        }

        public List<Line> GetProductionLines(string _connectionString, int userId, int isRouteManagement, string deptId = "0", int accessLevel = 1 )
        {
            var deptIds = deptId.Split(new String[] { "," }, StringSplitOptions.None);
            var result = new List<Line>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                foreach (string id in deptIds)
                {
                    SqlCommand command = new SqlCommand("spLocal_eCIL_GetProdLines", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@UserId", userId));
                    command.Parameters.Add(new SqlParameter("@MinimumAccessLevel", accessLevel));
                    command.Parameters.Add(new SqlParameter("@Dept_Id", Int32.Parse(id)));
                    command.Parameters.Add(new SqlParameter("@IsRouteManagement", isRouteManagement));
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            result.Add(new Line(reader.GetInt32(0), reader.GetString(1)));
                        }
                        reader.Close();
                    }
                }
                conn.Close();
            }
            return result;

        }

        public List<MasterUnit> GetMasterUnits(string _connectionString, string lineId, bool firstItemBlank = false)
        {
            var lineIds = lineId.Split(new String[] { "," }, StringSplitOptions.None);
            var result = new List<MasterUnit>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                foreach (string id in lineIds)
                {
                    SqlCommand command = new SqlCommand("spLocal_eCIL_GetMasterUnits", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@PLId", Int32.Parse(id)));
                    command.Parameters.Add(new SqlParameter("@FirstItemBlank", firstItemBlank));
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            result.Add(new MasterUnit(reader.GetInt32(0), reader.GetString(1)));
                        }
                        reader.Close();
                    }
                }
                conn.Close();
            }
            return result;
        }

        public List<SlaveUnit> GetSlaveUnits(string _connectionString, string masterId, bool firstItemBlank = false)
        {
            var masterIds = masterId.Split(new String[] { "," }, StringSplitOptions.None);
            var result = new List<SlaveUnit>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                foreach (string id in masterIds)
                {
                    SqlCommand command = new SqlCommand("spLocal_STI_Cmn_GetSlaveUnitsOnMaster", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@MasterUnitId", Int32.Parse(id)));
                    command.Parameters.Add(new SqlParameter("@FirstItemBlank", firstItemBlank));
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            result.Add(new SlaveUnit(reader.GetInt32(0), reader.GetString(1)));
                        }
                        reader.Close();
                    }
                }
                conn.Close();
            }
            return result;
        }

        public List<ProductionGroups> GetProductionGroups(string _connectionString, string slaveUnitId, bool firstItemBlank = false)
        {
            var slaveUnitsIds = slaveUnitId.Split(new String[] { "," }, StringSplitOptions.None);
            var result = new List<ProductionGroups>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();

                foreach (string id in slaveUnitsIds)
                {
                    SqlCommand command = new SqlCommand("spLocal_STI_Cmn_GetProductionGroups", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@PUId", Int32.Parse(id)));
                    command.Parameters.Add(new SqlParameter("@FirstItemBlank", firstItemBlank));
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            result.Add(new ProductionGroups(reader.GetInt32(0), reader.GetString(1)));
                        }
                        reader.Close();
                    }
                }
                conn.Close();
            }
            return result;
        }


        public List<FLObject> GetPlantModelByFL(string _connectionString, bool FL1, bool FL2, bool FL3, bool FL4)
        {
            var result = new List<FLObject>();

            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetPlantModelByFL", conn);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        FLObject temp = new FLObject();
                        if (!reader.IsDBNull(reader.GetOrdinal("Id")))
                            temp.Id = reader.GetInt32(reader.GetOrdinal("Id"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ParentId")))
                            temp.ParentId = reader.GetInt32(reader.GetOrdinal("ParentId"));
                        if (!reader.IsDBNull(reader.GetOrdinal("ItemDesc")))
                            temp.ItemDesc = reader.GetString(reader.GetOrdinal("ItemDesc"));
                        if (!reader.IsDBNull(reader.GetOrdinal("FLPath")))
                            temp.FLPath = reader.GetString(reader.GetOrdinal("FLPath"));
                        else
                            temp.FLPath = "";
                        if (!reader.IsDBNull(reader.GetOrdinal("Level")))
                            temp.Level = reader.GetInt32(reader.GetOrdinal("Level"));
                        if (!reader.IsDBNull(reader.GetOrdinal("LevelType")))
                            temp.LevelType = reader.GetString(reader.GetOrdinal("LevelType"));
                        result.Add(temp);

                    }
                    reader.Close();
                }
                conn.Close();
            }

            if (FL1)
            {
                var result1 = result.Where(x => x.Level == 0).ToList();
                return result1;
            }
            else if (FL2)
            {
                var result1 = result.Where(x => x.Level == 1).ToList();
                return result1;
            }
            else if (FL3)
            {
                var result1 = result.Where(x => x.Level == 2).ToList();
                return result1;
            }
            else if (FL4)
            {
                var result1 = result.Where(x => x.Level == 3).ToList();
                return result1;
            }
            else return result;
        }

        public void AddModule(string _connectionString, PlantModelData plantModelData, int userId)
        {
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                try
                {
                    SqlParameter Param_PU_Id = new SqlParameter("@PU_Id", SqlDbType.Int);
                    Param_PU_Id.Direction = ParameterDirection.Output;
                    Param_PU_Id.Value = DBNull.Value;

                    //Creation of the new Slave Unit (Module)
                    SqlCommand cmd1 = new SqlCommand();
                    cmd1.Connection = conn;
                    cmd1.Transaction = transaction;
                    cmd1.CommandText = "spEM_CreateProdUnit";
                    cmd1.CommandType = CommandType.StoredProcedure;
                    cmd1.Parameters.Add(Param_PU_Id);
                    cmd1.Parameters.Add(new SqlParameter("@Description", plantModelData.SlaveUnitDesc));
                    cmd1.Parameters.Add(new SqlParameter("@PL_Id", plantModelData.LineId));
                    cmd1.Parameters.Add(new SqlParameter("@User_Id", userId));
                    cmd1.ExecuteNonQuery();

                    if (!DBNull.Value.Equals(Param_PU_Id.Value) || !string.IsNullOrEmpty(Param_PU_Id.Value.ToString()))
                    {
                        //Set this new unit as a Slave of the Master Unit
                        SqlCommand cmd2 = new SqlCommand();
                        cmd2.Connection = conn;
                        cmd2.Transaction = transaction;
                        cmd2.CommandText = "spEM_SetMasterUnit";
                        cmd2.CommandType = CommandType.StoredProcedure;
                        cmd2.Parameters.Add(new SqlParameter("@PU_Id", Param_PU_Id.Value));
                        cmd2.Parameters.Add(new SqlParameter("@Master_Unit", plantModelData.MasterUnitId));
                        cmd2.Parameters.Add(new SqlParameter("@User_Id", userId));
                        cmd2.ExecuteNonQuery();

                        //Add the FL3 information to this new Slave Unit
                        SqlCommand cmd3 = new SqlCommand();
                        cmd3.Connection = conn;
                        cmd3.Transaction = transaction;
                        cmd3.CommandText = "spLocal_STI_Cmn_CreateUDP_Prod_Unit";
                        cmd3.CommandType = CommandType.StoredProcedure;
                        cmd3.Parameters.Add(new SqlParameter("@LineDesc", plantModelData.LineDesc));
                        cmd3.Parameters.Add(new SqlParameter("@UnitDesc", plantModelData.SlaveUnitDesc));
                        cmd3.Parameters.Add(new SqlParameter("@Table_Field_Desc", "FL3"));
                        cmd3.Parameters.Add(new SqlParameter("@Value", plantModelData.FL3));
                        cmd3.ExecuteNonQuery();
                    }

                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    try
                    {
                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }
        }

        public void AddProductionGroup(string _connectionString, PlantModelData plantModelData, int userId)
        {
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction;

                transaction = conn.BeginTransaction("StartTransaction");

                try
                {
                    //Creation of the new Production Group
                    SqlCommand cmd1 = new SqlCommand();
                    cmd1.Connection = conn;
                    cmd1.Transaction = transaction;
                    cmd1.CommandText = "spEM_CreatePUG";
                    cmd1.CommandType = CommandType.StoredProcedure;
                    cmd1.Parameters.Add(new SqlParameter("@Description", plantModelData.ProductionGroupDesc));
                    cmd1.Parameters.Add(new SqlParameter("@PU_Id", plantModelData.SlaveUnitId));
                    cmd1.Parameters.Add(new SqlParameter("@PUG_Order", 999));
                    cmd1.Parameters.Add(new SqlParameter("@User_Id", userId));
                    cmd1.Parameters.Add(new SqlParameter("@PUG_Id", DBNull.Value));
                    cmd1.ExecuteNonQuery();

                    //Creation of the FL4 on the new Production Group
                    if (!string.IsNullOrEmpty(plantModelData.FL4))
                    {
                        SqlCommand cmd2 = new SqlCommand();
                        cmd2.Connection = conn;
                        cmd2.Transaction = transaction;
                        cmd2.CommandText = "spLocal_STI_Cmn_CreateUDP_PU_Group";
                        cmd2.CommandType = CommandType.StoredProcedure;
                        cmd2.Parameters.Add(new SqlParameter("@LineDesc", plantModelData.LineDesc));
                        cmd2.Parameters.Add(new SqlParameter("@UnitDesc", plantModelData.SlaveUnitDesc));
                        cmd2.Parameters.Add(new SqlParameter("@GroupDesc", plantModelData.ProductionGroupDesc));
                        cmd2.Parameters.Add(new SqlParameter("@Table_Field_Desc", "FL4"));
                        cmd2.Parameters.Add(new SqlParameter("@Value", plantModelData.FL4));
                        cmd2.ExecuteNonQuery();
                    }

                    transaction.Commit();
                }
                catch (Exception ex)
                {
                    try
                    {
                        transaction.Rollback();
                    }
                    catch (Exception ex2)
                    {
                        conn.Close();
                        throw new Exception(ex2.Message);
                    }

                    conn.Close();
                    throw new Exception(ex.Message);
                }

                conn.Close();
            }
        }

        //Task Management EditMode methods

        //Get plantModel for editMode in TaskManagement
        //plantModelLevel is an integer and represents the lowerLevel for the data(Department = 0, Line = 1, MasterUnit = 2, SlaveUnit = 3, Group = 4, Variable = 5)
        //if the user will not pass any plantModelLevel, the default value will be 4 to get the department, line, master unit, slave units and groups
        //We don't care about the variables level because the user will not be able to edit anything for variables(tasks)
        public List<PlantModelEdit> GetPlantModelEditMode(string _connectionString, int userId, int? plId, int? plantModelLevel)
        {
            List<PlantModelEdit> result = new List<PlantModelEdit>();
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand("spLocal_eCIL_GetPlantModel2", conn);
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@UserId", userId));
                command.Parameters.Add(new SqlParameter("@PLId", plId ?? 0));
                command.Parameters.Add(new SqlParameter("@LowerLevel", plantModelLevel ?? 4));
                try
                {
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            PlantModelEdit temp = new PlantModelEdit();
                            temp = ConvertReaderToPlantModelEdit(reader);
                            result.Add(temp);
                        }

                    }
                    conn.Close();
                    return result;
                } catch
                {
                    conn.Close();
                    return new List<PlantModelEdit>();
                }

            }
        }

        public PlantModelEdit ConvertReaderToPlantModelEdit(SqlDataReader reader)
        {
            PlantModelEdit result = new PlantModelEdit();
            if (!reader.IsDBNull(reader.GetOrdinal("Id")))
                result.Id = reader.GetInt32(reader.GetOrdinal("Id"));
            if (!reader.IsDBNull(reader.GetOrdinal("ParentId")))
                result.ParentId = reader.GetInt32(reader.GetOrdinal("ParentId"));
            if (!reader.IsDBNull(reader.GetOrdinal("Level")))
                result.Level = reader.GetInt32(reader.GetOrdinal("Level"));
            if (!reader.IsDBNull(reader.GetOrdinal("ItemId")))
                result.ItemId = reader.GetInt32(reader.GetOrdinal("ItemId"));
            if (!reader.IsDBNull(reader.GetOrdinal("ItemDesc")))
                result.ItemDesc = reader.GetString(reader.GetOrdinal("ItemDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("PLId")))
                result.LineId = reader.GetInt32(reader.GetOrdinal("PLId"));
            if (!reader.IsDBNull(reader.GetOrdinal("PLDesc")))
                result.LineDesc = reader.GetString(reader.GetOrdinal("PLDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitId")))
                result.MasterUnitId = reader.GetInt32(reader.GetOrdinal("MasterUnitId"));
            if (!reader.IsDBNull(reader.GetOrdinal("MasterUnitDesc")))
                result.MasterUnitDesc = reader.GetString(reader.GetOrdinal("MasterUnitDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("PUId")))
                result.SlaveUnitId = reader.GetInt32(reader.GetOrdinal("PUId"));
            if (!reader.IsDBNull(reader.GetOrdinal("PUDesc")))
                result.SlaveUnitDesc = reader.GetString(reader.GetOrdinal("PUDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                result.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));
            if (!reader.IsDBNull(reader.GetOrdinal("VarDesc")))
                result.VarDesc = reader.GetString(reader.GetOrdinal("VarDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("FL1")))
                result.FL1 = reader.GetString(reader.GetOrdinal("FL1"));
            if (!reader.IsDBNull(reader.GetOrdinal("FL2")))
                result.FL2 = reader.GetString(reader.GetOrdinal("FL2"));
            if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                result.FL3 = reader.GetString(reader.GetOrdinal("FL3"));
            if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                result.FL4 = reader.GetString(reader.GetOrdinal("FL4"));
            if (!reader.IsDBNull(reader.GetOrdinal("LocalDesc")))
                result.LocalDesc = reader.GetString(reader.GetOrdinal("LocalDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("GlobalDesc")))
                result.GlobalDesc = reader.GetString(reader.GetOrdinal("GlobalDesc"));
            if (!reader.IsDBNull(reader.GetOrdinal("LineVersion")))
                result.LineVersion = reader.GetString(reader.GetOrdinal("LineVersion"));
            if (!reader.IsDBNull(reader.GetOrdinal("ModuleFeature")))
                result.ModuleFeatureVersion = reader.GetString(reader.GetOrdinal("ModuleFeature"));
            return result;
        }

        //update field for plantModel in editMode
        public string UpdateLineUDP(string _connectionString, string lineDesc, string udpName, string udpValue, bool toDelete)
        {
            string result = string.Empty;
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction = conn.BeginTransaction("eCIL-UpdateUDP-Prod_Line-Table");
                command.Connection = conn;
                command.Transaction = transaction;
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@LineDesc", lineDesc));
                command.Parameters.Add(new SqlParameter("@Table_Field_Desc", udpName));
                if (toDelete == true)
                {
                    command.CommandText = "spLocal_STI_Cmn_DeleteUDP_Prod_Line";
                }
                else
                {
                    command.CommandText = "spLocal_STI_Cmn_CreateUDP_Prod_Line";
                    command.Parameters.Add(new SqlParameter("@Value", udpValue));
                }
                try
                {
                    command.ExecuteNonQuery();
                    transaction.Commit();
                    return "Success";
                }
                catch (Exception ex)
                {
                    return ex.Message.ToString();
                }
            }
        }

        public string UpdateUnitUDP(string _connectionString, string lineDesc, string unitDesc, string udpName, string udpValue, bool toDelete)
        {
            string result = string.Empty;
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction = conn.BeginTransaction("eCIL-UpdateUDP-Prod_Unit-Table");
                command.Connection = conn;
                command.Transaction = transaction;
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@LineDesc", lineDesc));
                command.Parameters.Add(new SqlParameter("@UnitDesc", unitDesc));
                command.Parameters.Add(new SqlParameter("@Table_Field_Desc", udpName));
                if (toDelete == true)
                {
                    command.CommandText = "spLocal_STI_Cmn_DeleteUDP_Prod_Unit";
                }
                else
                {
                    command.CommandText = "spLocal_STI_Cmn_CreateUDP_Prod_Unit";
                    command.Parameters.Add(new SqlParameter("@Value", udpValue));
                }
                try
                {
                    command.ExecuteNonQuery();
                    transaction.Commit();
                    return "Success";
                }
                catch (Exception ex)
                {
                    return ex.Message.ToString();
                }
            }
        }

        public string UpdateGroupUDP(string _connectionString, string lineDesc, string unitDesc, string groupDesc, string udpName, string udpValue, bool toDelete)
        {
            string result = string.Empty;
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                SqlCommand command = new SqlCommand();
                SqlTransaction transaction = conn.BeginTransaction("eCIL-UpdateUDP-Prod_Unit-Table");
                command.Connection = conn;
                command.Transaction = transaction;
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.Add(new SqlParameter("@LineDesc", lineDesc));
                command.Parameters.Add(new SqlParameter("@UnitDesc", unitDesc));
                command.Parameters.Add(new SqlParameter("@GroupDesc", groupDesc));
                command.Parameters.Add(new SqlParameter("@Table_Field_Desc", udpName));
                if (toDelete == true)
                {
                    command.CommandText = "spLocal_STI_Cmn_DeleteUDP_PU_Group";
                }
                else
                {
                    command.CommandText = "spLocal_STI_Cmn_CreateUDP_PU_Group";
                    command.Parameters.Add(new SqlParameter("@Value", udpValue));
                }
                try
                {
                    command.ExecuteNonQuery();
                    transaction.Commit();
                    return "Success";
                }
                catch (Exception ex)
                {
                    return ex.Message.ToString();
                }
            }
        }
        #endregion

    }

    public class PlantModelEdit : PlantModel.PlantModelData
    {
        #region Variables
        private int id;
        private int parentId;
        private int level;
        private int itemId;
        private string itemDesc;
        private int varId;
        private string varDesc;
        private string localDesc;
        private string globalDesc;
        #endregion

        #region Properties
        public int Id { get => id; set => id = value; }
        public int ParentId { get => parentId; set => parentId = value; }
        public int Level { get => level; set => level = value; }
        public int ItemId { get => itemId; set => itemId = value; }
        public string ItemDesc { get => itemDesc; set => itemDesc = value; }
        public int VarId { get => varId; set => varId = value; }
        public string VarDesc { get => varDesc; set => varDesc = value; }
        public string LocalDesc { get => localDesc; set => localDesc = value; }
        public string GlobalDesc { get => globalDesc; set => globalDesc = value; }
        #endregion

        #region Constructor
        public PlantModelEdit()
        {
            Id = 0;
            ParentId = 0;
            Level = 0;
            ItemId = 0;
            ItemDesc = string.Empty;
            VarId = 0;
            VarDesc = string.Empty;
            LocalDesc = string.Empty;
            GlobalDesc = string.Empty;
        }


        #endregion
    }
}
