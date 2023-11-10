//using eCIL_DataLayer.ProficyClient;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eCIL_DataLayer.Reports
{
    public class Compliance
    {
        #region Variables
        private int itemId;
        private string itemDesc;
        private int totalCount;
        private int onTime;
        private int doneLate;
        private int numberMissed;
        private int taskDueLate;
        private decimal pctDone;
        private int defectsFound;
        private int openDefects;
        private string fl3;
        private string fl4;
        #endregion

        #region Properties
        public int ItemId { get => itemId; set => itemId = value; }
        public string ItemDesc { get => itemDesc; set => itemDesc = value; }
        public int TotalCount { get => totalCount; set => totalCount = value; }
        public int OnTime { get => onTime; set => onTime = value; }
        public int DoneLate { get => doneLate; set => doneLate = value; }
        public int NumberMissed { get => numberMissed; set => numberMissed = value; }
        public int TaskDueLate { get => taskDueLate; set => taskDueLate = value; }
        public decimal PctDone { get => pctDone; set => pctDone = value; }
        public int DefectsFound { get => defectsFound; set => defectsFound = value; }
        public int OpenDefects { get => openDefects; set => openDefects = value; }
        public string Fl3 { get => fl3; set => fl3 = value; }
        public string Fl4 { get => fl4; set => fl4 = value; }
        #endregion
    }

    public class ComplianceReport : Compliance
    {
        #region Variables
            private int granularity;
            private int subLevel;
            private int parentId;
            private int stops;
            private string line;
            private string routeIds;
            private string teamIds;
            private int teamDetail;
            private int topLevelId;
            #endregion

        #region Properties
            public int Granularity { get => granularity; set => granularity = value; }
            public int SubLevel { get => subLevel; set => subLevel = value; }
            public int ParentId { get => parentId; set => parentId = value; }
            public int Stops { get => stops; set => stops = value; }
            public string Line { get => line; set => line = value; }
            public string RouteIds { get => routeIds; set => routeIds = value; }
            public string TeamIds { get => teamIds; set => teamIds = value; }
            public int TeamDetail { get => teamDetail; set => teamDetail = value; }
            public int TopLevelId { get => topLevelId; set => topLevelId = value; }
        #endregion

        #region Methods

        /// <summary>
        /// 
        /// </summary>
        /// <param name="connectionString">ConnectionString to database</param>
        /// <param name="granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="topLevelId">The Id from which the report was initiated, before drill-down</param>
        /// <param name="subLevel">The id of the current level being drilled-down</param>
        /// <param name="startTime">The beginning period of the report</param>
        /// <param name="endTime">The end period of the report</param>
        /// <param name="routeIds">The list of IDs representing routes to include in the report</param>
        /// <param name="teamIds">The list of IDs representing teams to include in the report</param>
        /// <param name="teamDetails">The level of details we want for Team (1=Summary  2=Routes  4=Plant Model)</param>
        /// <param name="qFactorOnly">Specify if we only want QFactor Tasks in the report.</param>
        /// <returns>List of COmpliance Report objects representing summary for the current level</returns>
        public List<ComplianceReport> GetData(string connectionString, int granularity, int topLevelId, int subLevel, string startTime, string endTime, int? userId, string routeIds, string teamIds, int teamDetails, bool qFactorOnly, int selectionItemId = 0, bool HSEOnly = false) //, bool MinimumUptimeOnly = false
            {
                List<ComplianceReport> result = new List<ComplianceReport>();
                try
                {

                string fieldFilter = String.Empty;
                int fieldValue = 0;

                fieldFilter = selectionItemId != 0 ? "ItemId" : "";
                fieldValue = selectionItemId != 0 ? selectionItemId : 0;

                using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        SqlCommand command = new SqlCommand("spLocal_eCIL_Report_Compliance", conn);
                        command.CommandType = System.Data.CommandType.StoredProcedure;
                        command.Parameters.Add(new SqlParameter("@Granularity", granularity));
                        command.Parameters.Add(new SqlParameter("@TopLevelID", topLevelId));
                        command.Parameters.Add(new SqlParameter("@SubLevel", subLevel));
                        command.Parameters.Add(new SqlParameter("@StartTime", startTime));
                        command.Parameters.Add(new SqlParameter("@EndTime", endTime));
                        command.Parameters.Add(new SqlParameter("@UserId", userId ?? (object)DBNull.Value));
                        command.Parameters.Add(new SqlParameter("@RouteIds", routeIds ?? (object)DBNull.Value));
                        command.Parameters.Add(new SqlParameter("@TeamIds", teamIds ?? (object)DBNull.Value));
                        command.Parameters.Add(new SqlParameter("@TeamDetail", teamDetails));
                        command.Parameters.Add(new SqlParameter("@QFactorOnly", qFactorOnly));
                        command.Parameters.Add(new SqlParameter("@HSEOnly", HSEOnly));
                        //command.Parameters.Add(new SqlParameter("@UptimeFilter", MinimumUptimeOnly));

                    using (SqlDataReader reader = command.ExecuteReader())
                        {
                            while(reader.Read())
                            {

                                if (String.IsNullOrEmpty(fieldFilter) || (!String.IsNullOrEmpty(fieldFilter) & reader.GetInt32(reader.GetOrdinal(fieldFilter)) == fieldValue))
                                {
                                    ComplianceReport temp = ConvertReaderToComplianceReport(reader);
                                    result.Add(temp);
                                }
                            }
                        }
                    }

                    return result;

                } catch (Exception ex)
                {
                    throw new Exception(ex.Message);
                }
        }
            #endregion

        #region Utilities
            private ComplianceReport ConvertReaderToComplianceReport(SqlDataReader reader)
            {
                ComplianceReport result = new ComplianceReport();
            try
            {
                if (!reader.IsDBNull(reader.GetOrdinal("Granularity")))
                    result.Granularity = reader.GetInt32(reader.GetOrdinal("Granularity"));
                if (!reader.IsDBNull(reader.GetOrdinal("SubLevel")))
                    result.SubLevel = reader.GetInt32(reader.GetOrdinal("SubLevel"));
                if (!reader.IsDBNull(reader.GetOrdinal("ParentId")))
                    result.ParentId = reader.GetInt32(reader.GetOrdinal("ParentId"));
                if (!reader.IsDBNull(reader.GetOrdinal("ItemId")))
                    result.ItemId = reader.GetInt32(reader.GetOrdinal("ItemId"));
                if (!reader.IsDBNull(reader.GetOrdinal("ItemDesc")))
                    result.ItemDesc = reader.GetString(reader.GetOrdinal("ItemDesc"));
                if (!reader.IsDBNull(reader.GetOrdinal("TotalCount")))
                    result.TotalCount = reader.GetInt32(reader.GetOrdinal("TotalCount"));
                if (!reader.IsDBNull(reader.GetOrdinal("OnTime")))
                    result.OnTime = reader.GetInt32(reader.GetOrdinal("OnTime"));
                if (!reader.IsDBNull(reader.GetOrdinal("DoneLate")))
                    result.DoneLate = reader.GetInt32(reader.GetOrdinal("DoneLate"));
                if (!reader.IsDBNull(reader.GetOrdinal("NumberMissed")))
                    result.NumberMissed = reader.GetInt32(reader.GetOrdinal("NumberMissed"));
                if (!reader.IsDBNull(reader.GetOrdinal("TaskDueLate")))
                    result.TaskDueLate = reader.GetInt32(reader.GetOrdinal("TaskDueLate"));
                if (!reader.IsDBNull(reader.GetOrdinal("PctDone")))
                    result.PctDone = reader.GetDecimal(reader.GetOrdinal("PctDone"));
                if (!reader.IsDBNull(reader.GetOrdinal("DefectsFound")))
                    result.DefectsFound = reader.GetInt32(reader.GetOrdinal("DefectsFound"));
                if (!reader.IsDBNull(reader.GetOrdinal("OpenDefects")))
                    result.OpenDefects = reader.GetInt32(reader.GetOrdinal("OpenDefects"));
                if (!reader.IsDBNull(reader.GetOrdinal("Stops")))
                    result.Stops = reader.GetInt32(reader.GetOrdinal("Stops"));
                if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                    result.Fl3 = reader.GetString(reader.GetOrdinal("FL3"));
                if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                    result.Fl4 = reader.GetString(reader.GetOrdinal("FL4"));
                if (!reader.IsDBNull(reader.GetOrdinal("Line")))
                    result.Line = reader.GetString(reader.GetOrdinal("Line"));
                if (!reader.IsDBNull(reader.GetOrdinal("RouteIDs")))
                    result.RouteIds = reader.GetString(reader.GetOrdinal("RouteIDs"));
                if (!reader.IsDBNull(reader.GetOrdinal("TeamIDs")))
                    result.TeamIds = reader.GetString(reader.GetOrdinal("TeamIDs"));
                if (!reader.IsDBNull(reader.GetOrdinal("TeamDetail")))
                    result.TeamDetail = reader.GetInt32(reader.GetOrdinal("TeamDetail"));
                if (!reader.IsDBNull(reader.GetOrdinal("TopLevelID")))
                    result.TopLevelId = reader.GetInt32(reader.GetOrdinal("TopLevelID"));
                return result;

            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
            #endregion
    }

    public class ComplianceReportPrint : Compliance
    {
        #region Variables
            private string deptDesc;
            private int deptId;
            private string plDesc;
            private int plId;
            private string masterDesc;
            private int masterUnit;
            private string slaveDesc;
            private int puId;
            private string pugDesc;
            private int pugId;
            private string varDesc;
            private string routeDesc;
            private int section;
            #endregion

        #region Properties
            public string DeptDesc { get => deptDesc; set => deptDesc = value; }
            public int DeptId { get => deptId; set => deptId = value; }
            public string PlDesc { get => plDesc; set => plDesc = value; }
            public int PlId { get => plId; set => plId = value; }
            public string MasterDesc { get => masterDesc; set => masterDesc = value; }
            public int MasterUnit { get => masterUnit; set => masterUnit = value; }
            public string SlaveDesc { get => slaveDesc; set => slaveDesc = value; }
            public int PuId { get => puId; set => puId = value; }
            public string PugDesc { get => pugDesc; set => pugDesc = value; }
            public int PugId { get => pugId; set => pugId = value; }
            public string VarDesc { get => varDesc; set => varDesc = value; }
            public string RouteDesc { get => routeDesc; set => routeDesc = value; }
            public int Section { get => section; set => section = value; }
        #endregion

        #region Methods
        /// <summary>
        /// 
        /// </summary>
        /// <param name="connectionString">ConnectionString to database</param>
        /// <param name="granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="topLevelId">The Id from which the report was initiated, before drill-down</param>
        /// <param name="subLevel">The id of the current level being drilled-down</param>
        /// <param name="startTime">The beginning period of the report</param>
        /// <param name="endTime">The end period of the report</param>
        /// <param name="routeIds">The list of IDs representing routes to include in the report</param>
        /// <param name="teamIds">The list of IDs representing teams to include in the report</param>
        /// <param name="teamDetails">The level of details we want for Team (1=Summary  2=Routes  4=Plant Model)</param>
        /// <param name="qFactorOnly">Specify if we only want QFactor Tasks in the report.</param>
        /// <returns>List of COmpliance Report objects representing summary for the current level for printing(include the entire plantModel)</returns>
        public List<ComplianceReportPrint> GetReportDataPrint(string connectionString, int granularity, int topLevelId, int subLevel, string startTime, string endTime, int? userId, string routeIds, string teamIds, int teamDetails, bool qFactorOnly, bool HSEOnly = false) //, bool MinimumUptimeOnly = false
        {
            List<ComplianceReportPrint> result = new List<ComplianceReportPrint>();
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_Report_CompliancePrint", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@Granularity", granularity));
                    command.Parameters.Add(new SqlParameter("@TopLevelID", topLevelId));
                    command.Parameters.Add(new SqlParameter("@SubLevel", subLevel));
                    command.Parameters.Add(new SqlParameter("@StartTime", startTime));
                    command.Parameters.Add(new SqlParameter("@EndTime", endTime));
                    command.Parameters.Add(new SqlParameter("@UserId", userId != null ? userId : null));
                    command.Parameters.Add(new SqlParameter("@RouteIds", routeIds != "" || routeIds != null ? routeIds : null));
                    command.Parameters.Add(new SqlParameter("@TeamIds", teamIds != "" || teamIds != null ? teamIds : null));
                    command.Parameters.Add(new SqlParameter("@TeamDetail", teamDetails));
                    command.Parameters.Add(new SqlParameter("@QFactorOnly", qFactorOnly));
                    command.Parameters.Add(new SqlParameter("@HSEOnly", HSEOnly));
                    //command.Parameters.Add(new SqlParameter("@UptimeFilter", MinimumUptimeOnly));

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while(reader.Read())
                        {
                            ComplianceReportPrint temp = ConvertReaderToComplianceReportPrint(reader);
                            result.Add(temp);
                        }
                    }
                }
                return result;
            }catch
            {
                return null;
            }
            
        }
        #endregion

        #region Utilities
            public ComplianceReportPrint ConvertReaderToComplianceReportPrint(SqlDataReader reader)
            {
                try
                {
                    ComplianceReportPrint result = new ComplianceReportPrint();
                    if (!reader.IsDBNull(reader.GetOrdinal("ItemId")))
                        result.ItemId = reader.GetInt32(reader.GetOrdinal("ItemId"));
                    if (!reader.IsDBNull(reader.GetOrdinal("ItemDesc")))
                        result.ItemDesc = reader.GetString(reader.GetOrdinal("ItemDesc"));
                    if (!reader.IsDBNull(reader.GetOrdinal("TotalCount")))
                        result.TotalCount = reader.GetInt32(reader.GetOrdinal("TotalCount"));
                    if (!reader.IsDBNull(reader.GetOrdinal("OnTime")))
                        result.OnTime = reader.GetInt32(reader.GetOrdinal("OnTime"));
                    if (!reader.IsDBNull(reader.GetOrdinal("DoneLate")))
                        result.DoneLate = reader.GetInt32(reader.GetOrdinal("DoneLate"));
                    if (!reader.IsDBNull(reader.GetOrdinal("NumberMissed")))
                        result.NumberMissed = reader.GetInt32(reader.GetOrdinal("NumberMissed"));
                    if (!reader.IsDBNull(reader.GetOrdinal("TaskDueLate")))
                        result.TaskDueLate = reader.GetInt32(reader.GetOrdinal("TaskDueLate"));
                    if (!reader.IsDBNull(reader.GetOrdinal("PctDone")))
                        result.PctDone = reader.GetDecimal(reader.GetOrdinal("PctDone"));
                    if (!reader.IsDBNull(reader.GetOrdinal("DefectsFound")))
                        result.DefectsFound = reader.GetInt32(reader.GetOrdinal("DefectsFound"));
                    if (!reader.IsDBNull(reader.GetOrdinal("OpenDefects")))
                        result.OpenDefects = reader.GetInt32(reader.GetOrdinal("OpenDefects"));
                    if (!reader.IsDBNull(reader.GetOrdinal("FL3")))
                        result.Fl3 = reader.GetString(reader.GetOrdinal("FL3"));
                    if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                        result.Fl4 = reader.GetString(reader.GetOrdinal("FL4"));
                    if (!reader.IsDBNull(reader.GetOrdinal("DeptDesc")))
                        result.DeptDesc = reader.GetString(reader.GetOrdinal("DeptDesc"));
                    if (!reader.IsDBNull(reader.GetOrdinal("DeptId")))
                        result.DeptId = reader.GetInt32(reader.GetOrdinal("DeptId"));
                    if (!reader.IsDBNull(reader.GetOrdinal("PLDesc")))
                        result.PlDesc = reader.GetString(reader.GetOrdinal("PLDesc"));
                    if (!reader.IsDBNull(reader.GetOrdinal("PLId")))
                        result.PlId = reader.GetInt32(reader.GetOrdinal("PLId"));
                    if (!reader.IsDBNull(reader.GetOrdinal("MasterDesc")))
                        result.MasterDesc = reader.GetString(reader.GetOrdinal("MasterDesc"));
                    if (!reader.IsDBNull(reader.GetOrdinal("Master_Unit")))
                        result.MasterUnit = reader.GetInt32(reader.GetOrdinal("Master_Unit"));
                    if (!reader.IsDBNull(reader.GetOrdinal("SlaveDesc")))
                        result.SlaveDesc = reader.GetString(reader.GetOrdinal("SlaveDesc"));
                    if (!reader.IsDBNull(reader.GetOrdinal("PU_Id")))
                        result.PuId = reader.GetInt32(reader.GetOrdinal("PU_Id"));
                    if (!reader.IsDBNull(reader.GetOrdinal("PUGDesc")))
                        result.PugDesc = reader.GetString(reader.GetOrdinal("PUGDesc"));
                    if (!reader.IsDBNull(reader.GetOrdinal("PUGId")))
                        result.PugId = reader.GetInt32(reader.GetOrdinal("PUGId"));
                    if (!reader.IsDBNull(reader.GetOrdinal("VarDesc")))
                        result.VarDesc = reader.GetString(reader.GetOrdinal("VarDesc"));
                    if (!reader.IsDBNull(reader.GetOrdinal("RouteDesc")))
                        result.RouteDesc = reader.GetString(reader.GetOrdinal("RouteDesc"));
                    if (!reader.IsDBNull(reader.GetOrdinal("Section")))
                        result.Section = reader.GetInt32(reader.GetOrdinal("Section"));

                    return result;
                }catch
                {
                    return null;
                }
            
            }
            #endregion

    }

    public class Specifications
    {
        #region Variables
            private string lr;
            private string lu;
            private string lw;
            private string t;
            private string ur;
            private string uu;
            private string uw;
            private string lineDesc;
            private string specName;
            private int propId;
            private int actSpecId;
            #endregion

        #region Properties
            public string Lr { get => lr; set => lr = value; }
            public string Lu { get => lu; set => lu = value; }
            public string Lw { get => lw; set => lw = value; }
            public string T { get => t; set => t = value; }
            public string Ur { get => ur; set => ur = value; }
            public string Uu { get => uu; set => uu = value; }
            public string Uw { get => uw; set => uw = value; }
            public string LineDesc { get => lineDesc; set => lineDesc = value; }
            public string SpecName { get => specName; set => specName = value; }
            public int PropId { get => propId; set => propId = value; }
            public int ActSpecId { get => actSpecId; set => actSpecId = value; }
        #endregion

        #region Methods
        ///<summary>
        /// Get the list of specifications used to color the background of the cells in the Compliance Report.
        /// </summary>
        /// <param name="Granularity">1=Team, 2=Route, 3=Site, 4=Department, 5=Line, 6=Master, 7=Modules, 8=Tasks</param>
        /// <param name="IDs">The list of IDs represented in the current level</param>
        /// <param name="StartDate">The beginning period of the report</param>
        /// <param name="EndDate">The ending period of the report</param>
        /// <returns>DataTable that hold row(s) representing specifications for the current level</returns>
        public List<Specifications> GetSpecs(string connectionString, int granularity, string ids, string startDate, string endDate)
        {
            List<Specifications> result = new List<Specifications>();
            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_ComplianceReportSpecs", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@Granularity", granularity));
                    command.Parameters.Add(new SqlParameter("@IDs",ids));
                    command.Parameters.Add(new SqlParameter("@StartDate", startDate));
                    command.Parameters.Add(new SqlParameter("@EndDate", endDate));
                    using(SqlDataReader reader = command.ExecuteReader())
                    {
                        while(reader.Read())
                        {
                            Specifications temp = ConvertReaderToSpecification(reader);
                            result.Add(temp);
                        }
                    }
                }
                return result;
            }catch
            {
                return null;
            }
            
        }
        #endregion

        #region Utilities
        public Specifications ConvertReaderToSpecification(SqlDataReader reader)
        {
            try
            {
                Specifications result = new Specifications();
                if (!reader.IsDBNull(reader.GetOrdinal("LR")))
                    result.Lr = reader.GetString(reader.GetOrdinal("LR"));
                if (!reader.IsDBNull(reader.GetOrdinal("LU")))
                    result.Lu = reader.GetString(reader.GetOrdinal("LU"));
                if (!reader.IsDBNull(reader.GetOrdinal("LW")))
                    result.Lw = reader.GetString(reader.GetOrdinal("LW"));
                if (!reader.IsDBNull(reader.GetOrdinal("T")))
                    result.T = reader.GetString(reader.GetOrdinal("T"));
                if (!reader.IsDBNull(reader.GetOrdinal("UR")))
                    result.Ur = reader.GetString(reader.GetOrdinal("UR"));
                if (!reader.IsDBNull(reader.GetOrdinal("UU")))
                    result.Uu = reader.GetString(reader.GetOrdinal("UU"));
                if (!reader.IsDBNull(reader.GetOrdinal("UW")))
                    result.Uw = reader.GetString(reader.GetOrdinal("UW"));
                if (!reader.IsDBNull(reader.GetOrdinal("LineDesc")))
                    result.LineDesc = reader.GetString(reader.GetOrdinal("LineDesc"));
                if (!reader.IsDBNull(reader.GetOrdinal("SpecName")))
                    result.SpecName = reader.GetString(reader.GetOrdinal("SpecName"));
                if (!reader.IsDBNull(reader.GetOrdinal("PropId")))
                    result.PropId = reader.GetInt32(reader.GetOrdinal("PropId"));
                if (!reader.IsDBNull(reader.GetOrdinal("ActSpecId")))
                    result.ActSpecId = reader.GetInt32(reader.GetOrdinal("ActSpecId"));
                return result;
            }catch
            {
                return null;
            }
            
        }
        #endregion

    }
}
