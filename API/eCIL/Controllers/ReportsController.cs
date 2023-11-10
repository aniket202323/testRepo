using eCIL_DataLayer.Reports;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.Http;
namespace eCIL.Controllers
{
    public class ReportsController : ApiController
    {
        private ComplianceReport compliance;
        private ComplianceReportPrint compliancePrint;
        private Specifications specification;
        private EmagReport emagReport;
        private DownTimesReport downtimeReport;
        private DownTime downtimeDetails;
        private TrendReport trendReport;
        public ReportsController()
        {
            compliance = new ComplianceReport();
            compliancePrint = new ComplianceReportPrint();
            specification = new Specifications();
            emagReport = new EmagReport();
            downtimeReport = new DownTimesReport();
            downtimeDetails = new DownTime();
        }


        #region Compliance Report
        [HttpGet]
        [Route("api/reports/getcompliancereport")]
        public List<ComplianceReport> GetComplianceReport(int granularity, int topLevelId, int subLevel, string startTime, string endTime, int userId, string routeIds, string teamIds, int teamDetails, bool qFactorOnly)
        {
            try
            {
                return compliance.GetData(ConfigurationManager.AppSettings["DatabaseConnection"], granularity, topLevelId, subLevel, startTime, endTime, userId, routeIds, teamIds, teamDetails, qFactorOnly);
            }catch(Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }
        }

        [HttpGet]
        [Route("api/reports/getcompliacereportprint")]
        public List<ComplianceReportPrint> GetComplianceReportPrint(int granularity, int topLevelId, int subLevel, string startTime, string endTime, int? userId, string routeIds, string teamIds, int teamDetails, bool qFactorOnly)
        {
            try
            {
                return compliancePrint.GetReportDataPrint(ConfigurationManager.AppSettings["DatabaseConnection"], granularity, topLevelId, subLevel, startTime, endTime, userId, routeIds,  teamIds,  teamDetails, qFactorOnly);
            }catch(Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }
        }

        [HttpGet]
        [Route("api/reports/getspecs")]
        public List<Specifications> GetSpecs(int granularity, string ids, string startDate, string endDate)
        {
            try
            {
                return specification.GetSpecs(ConfigurationManager.AppSettings["DatabaseConnection"], granularity, ids, startDate, endDate);
            }catch(Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }
        }
        #endregion

        #region EmagReport
        [HttpGet]
        [Route("api/reports/getemagreportdata")]
        public EmagReport GetEmagReportData(int puId, string endDate)
        {
            try
            {
                return emagReport.GetEmagReportData( ConfigurationManager.AppSettings["DatabaseConnection"], puId, endDate);

            }catch(Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }
        }

        [HttpGet]
        [Route("api/reports/getdowntimesreport")]
        public List<DownTimesReport> GetDownTimesReport(int puId, string endDate)
        {
            try
            {
                return downtimeReport.GetDownTimes(ConfigurationManager.AppSettings["DatabaseConnection"], puId, endDate);
            }catch(Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }
        }

        [HttpGet]
        [Route("api/reports/getdowntimedetails")]
        public List<DownTime> GetDowntimeDetails(int puId, string eventReasonName, string endTime, int dayOffset)
        {
            try
            {
                return downtimeDetails.GetDowntimeDetails(ConfigurationManager.AppSettings["DatabaseConnection"], puId, eventReasonName, endTime, dayOffset);
            }catch(Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }
        }

        [HttpGet]
        [Route("api/reports/")]
        public TrendReport GetTrendReport(int taskId, string endDate, int languageId)
        {
            try
            {
                return trendReport.GetTrendReport(ConfigurationManager.AppSettings["DatabaseConnection"], taskId, endDate, languageId);
            }
            catch(Exception ex)
            {
                throw new HttpException(500, ex.Message);
            }
        }
        #endregion
    }
}
