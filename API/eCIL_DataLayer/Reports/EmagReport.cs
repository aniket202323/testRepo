using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eCIL_DataLayer.Reports
{
    public class DateTime
    {
        #region Variables
        private int dayPosition;
        private string val;
        #endregion

        #region Properties
        public int DayPosition { get => dayPosition; set => dayPosition = value; }
        public string Value { get => val; set => val = value; }
        #endregion

        #region Methods
        public static List<DateTime> ConvertFromReaderToDateTimeListBasedOnIndex(SqlDataReader reader)
        {
            List<DateTime> result = new List<DateTime>();
            try
            {
                for (int i = 1; i <= 30; i++)
                {
                    DateTime temp = new DateTime();
                    if (!reader.IsDBNull(reader.GetOrdinal(i.ToString())))
                    {
                        temp.DayPosition = i;
                        temp.Value = reader.GetString(reader.GetOrdinal(i.ToString()));
                    }
                    result.Add(temp);
                }
                return result;

            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public static List<DateTime> ConvertFromReaderToDateTimeListBasedOnIndexWith35Days(SqlDataReader reader)
        {
            List<DateTime> result = new List<DateTime>();
            try
            {
                for (int i = 1; i <= 35; i++)
                {
                    DateTime temp = new DateTime();
                    if (!reader.IsDBNull(reader.GetOrdinal("Col" + i.ToString())))
                    {
                        temp.DayPosition = i;
                        temp.Value = reader.GetString(reader.GetOrdinal("Col" + i.ToString()));
                    }
                    result.Add(temp);
                }
                return result;

            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public static List<DateTime> ConvertFromReaderToDateTimeListBasedOnPosition(SqlDataReader reader)
        {
            List<DateTime> result = new List<DateTime>();
            try
            {
                while (reader.Read())
                {
                    DateTime temp = new DateTime();
                    if (!reader.IsDBNull(reader.GetOrdinal("ColumnPos")))
                        temp.DayPosition = reader.GetInt32(reader.GetOrdinal("ColumnPos"));
                    if (!reader.IsDBNull(reader.GetOrdinal("ColumnDate")))
                        temp.Value = reader.GetString(reader.GetOrdinal("ColumnDate"));
                    result.Add(temp);
                }
                return result;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        #endregion
    }

    public class EmagData
    {
        #region Variables
        private string taskId;
        private string fl4;
        private string task;
        private string frequency;
        private List<DateTime> values;
        private List<DateTime> dates;
        private int varId;
        #endregion

        #region Properties
        public string TaskId { get => taskId; set => taskId = value; }
        public string Fl4 { get => fl4; set => fl4 = value; }
        public string Task { get => task; set => task = value; }
        public string Frequency { get => frequency; set => frequency = value; }
        public List<DateTime> Values { get => values; set => values = value; }
        public List<DateTime> Dates { get => dates; set => dates = value; }
        public int VarId { get => varId; set => varId = value; }
        #endregion
    }
    public class EmagReport
    {
        #region Variables
        private string startReportPeriod;
        private string endReportPeriod;
        private List<EmagData> emagData;
        private List<DateTime> dates;
        #endregion

        #region Properties
        public string StartReportPeriod { get => startReportPeriod; set => startReportPeriod = value; }
        public string EndReportPeriod { get => endReportPeriod; set => endReportPeriod = value; }
        public List<EmagData> EmagData { get => emagData; set => emagData = value; }
        public List<DateTime> Dates { get => dates; set => dates = value; }
        #endregion

        #region Methods
        public EmagReport GetEmagReportData(string connectionString, int puId, string endDate)
        {
            EmagReport result = new EmagReport();
            result.StartReportPeriod = System.DateTime.Parse(endDate).Date.AddDays(-30).Add(System.DateTime.Now.TimeOfDay).ToString("yyyy-MM-dd HH:mm:ss");
            result.EndReportPeriod = System.DateTime.Parse(endDate).Date.Add(System.DateTime.Now.TimeOfDay).ToString("yyyy-MM-dd HH:mm:ss");

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_Report_eMag", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@PUId", puId));
                    command.Parameters.Add(new SqlParameter("@EndTime", endDate));
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        EmagData temp = new EmagData();
                        result.EmagData = new List<EmagData>();
                        while (reader.Read())
                        {
                            temp = ConvertReaderToEmagReport(reader);
                            result.EmagData.Add(temp);
                        }
                        reader.NextResult();
                        result.Dates = new List<DateTime>();
                        while (reader.Read())
                        {
                            if (!reader.IsDBNull(reader.GetOrdinal("ColumnPos")))
                            {
                                DateTime temp1 = new DateTime();
                                temp1.DayPosition = reader.GetInt32(reader.GetOrdinal("ColumnPos"));
                                temp1.Value = reader.GetString(reader.GetOrdinal("ColumnDate"));
                                result.Dates.Add(temp1);
                            }
                        }
                        
                    }

                }
                return result;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
        #endregion

        #region Utilities
        public EmagData ConvertReaderToEmagReport(SqlDataReader reader)
        {
            try
            {
                EmagData temp = new EmagData();
                if (!reader.IsDBNull(reader.GetOrdinal("Task_Id")))
                    temp.TaskId = reader.GetString(reader.GetOrdinal("Task_Id"));
                if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                    temp.Fl4 = reader.GetString(reader.GetOrdinal("FL4"));
                if (!reader.IsDBNull(reader.GetOrdinal("Task")))
                    temp.Task = reader.GetString(reader.GetOrdinal("Task"));
                if (!reader.IsDBNull(reader.GetOrdinal("Freq")))
                    temp.Frequency = reader.GetString(reader.GetOrdinal("Freq"));

                temp.Values = DateTime.ConvertFromReaderToDateTimeListBasedOnIndex(reader);

                if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                    temp.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));

                return temp;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }

        }

        #endregion
    }

    public class DownTimesReport
    {
        #region Variables
        private string component;
        private int reason;
        private List<DateTime> values;
        #endregion

        #region Properties
        public int Reason { get => reason; set => reason = value; }
        public string Component { get => component; set => component = value; }
        public List<DateTime> Values { get => values; set => values = value; }
        #endregion

        #region Methods
        public List<DownTimesReport> GetDownTimes(string connectionString, int puId, string endDate)
        {
            List<DownTimesReport> result = new List<DownTimesReport>();
            var finalEndDate = System.DateTime.Parse(endDate).Date.Add(System.DateTime.Now.TimeOfDay).ToString("yyyy-MM-ddThh:mm:ss");
            try
            {
                using(SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_Report_eMag_DownTimes", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@PUID",puId));
                    command.Parameters.Add(new SqlParameter("@EndTime", finalEndDate));
                    using(SqlDataReader reader = command.ExecuteReader())
                    {
                        while(reader.Read())
                        {
                            DownTimesReport temp = new DownTimesReport();
                            if (!reader.IsDBNull(reader.GetOrdinal("Component")))
                                temp.Component = reader.GetString(reader.GetOrdinal("Component"));
                            if (!reader.IsDBNull(reader.GetOrdinal("Reason1")))
                                temp.Reason = reader.GetInt32(reader.GetOrdinal("Reason1"));
                            temp.Values = DateTime.ConvertFromReaderToDateTimeListBasedOnIndex(reader);
                            result.Add(temp);
                        }

                    }
                    return result;
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
        #endregion
    }

    public class DownTime
    {
        #region Variables
        private string startTime;
        private string endTime;
        private float duration;
        private string location;
        private string fault;
        private string reason1;
        private string reason2;
        private string reason3;
        private string reason4;
        private string causeComment;
        private string actionComment;
        #endregion

        #region Properties
        public string StartTime { get => startTime; set => startTime = value; }
        public string EndTime { get => endTime; set => endTime = value; }
        public float Duration { get => duration; set => duration = value; }
        public string Location { get => location; set => location = value; }
        public string Fault { get => fault; set => fault = value; }
        public string Reason1 { get => reason1; set => reason1 = value; }
        public string Reason2 { get => reason2; set => reason2 = value; }
        public string Reason3 { get => reason3; set => reason3 = value; }
        public string Reason4 { get => reason4; set => reason4 = value; }
        public string CauseComment { get => causeComment; set => causeComment = value; }
        public string ActionComment { get => actionComment; set => actionComment = value; }
        #endregion

        #region Methods
        public List<DownTime> GetDowntimeDetails(string connectionString, int puId, string eventReasonName, string endTime, int dayOffset)
        {
            var finalEndDate = System.DateTime.Parse(endTime).Date.Add(System.DateTime.Now.TimeOfDay).ToString("yyyy-MM-ddThh:mm:ss");
            List<DownTime> result = new List<DownTime>();
            try
            {
                using(SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_Report_eMag_DownTimeDetails", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@PU_Id", puId));
                    command.Parameters.Add(new SqlParameter("@Event_Reason_Name", eventReasonName ?? (Object)DBNull.Value));
                    command.Parameters.Add(new SqlParameter("@EndTime", finalEndDate));
                    command.Parameters.Add(new SqlParameter("@DayOffset",dayOffset));
                    using(SqlDataReader reader = command.ExecuteReader())
                    {
                        while(reader.Read())
                        {
                            DownTime temp = ConvertReaderToDownTime(reader);
                            result.Add(temp);
                        }
                    }

                }
                return result;

            }catch(Exception ex)
            {
                Console.WriteLine(ex.Message);
                return null;
            }
        }
        #endregion

        #region Utilities
        private DownTime ConvertReaderToDownTime(SqlDataReader reader)
        {
            try
            {
                DownTime temp = new DownTime();
                if (!reader.IsDBNull(reader.GetOrdinal("StartTime")))
                    temp.StartTime = reader.GetString(reader.GetOrdinal("StartTime"));
                if (!reader.IsDBNull(reader.GetOrdinal("EndTime")))
                    temp.EndTime = reader.GetString(reader.GetOrdinal("EndTime"));
                if (!reader.IsDBNull(reader.GetOrdinal("Duration")))
                    temp.Duration = (float)reader.GetDecimal(reader.GetOrdinal("Duration"));
                if (!reader.IsDBNull(reader.GetOrdinal("Location")))
                    temp.Location = reader.GetString(reader.GetOrdinal("Location"));
                try
                {
                    if (!reader.IsDBNull(reader.GetOrdinal("Fault")))
                        temp.Fault = reader.GetString(reader.GetOrdinal("Fault"));
                }
                catch
                {
                    temp.Fault = "";
                }
                
                if (!reader.IsDBNull(reader.GetOrdinal("Reason1")))
                    temp.Reason1 = reader.GetString(reader.GetOrdinal("Reason1"));
                if (!reader.IsDBNull(reader.GetOrdinal("Reason2")))
                    temp.Reason2 = reader.GetString(reader.GetOrdinal("Reason2"));
                if (!reader.IsDBNull(reader.GetOrdinal("Reason3")))
                    temp.Reason3 = reader.GetString(reader.GetOrdinal("Reason3"));
                if (!reader.IsDBNull(reader.GetOrdinal("Reason4")))
                    temp.Reason4 = reader.GetString(reader.GetOrdinal("Reason4"));
                if (!reader.IsDBNull(reader.GetOrdinal("CauseComment")))
                    temp.CauseComment = reader.GetString(reader.GetOrdinal("CauseComment"));
                if (!reader.IsDBNull(reader.GetOrdinal("ActionComment")))
                    temp.ActionComment = reader.GetString(reader.GetOrdinal("ActionComment"));
                return temp;
            }catch(Exception ex)
            {
                Console.WriteLine(ex.Message);
                return null;
            }
            
        }
        #endregion
    }

    public class TrendReport
    {
        #region Variables
        private string endReportPeriod;
        private List<EmagData> emagData;
        private List<Trend> trends;

        #endregion

        #region Properties
        public string EndReportPeriod { get => endReportPeriod; set => endReportPeriod = value; }
        public List<EmagData> EmagData { get => emagData; set => emagData = value; }
        public List<Trend> Trends { get => trends; set => trends = value; }
        #endregion

        #region Methods
        public TrendReport GetTrendReport(string connectionString, int taskId, string endDate, int languageId)
        {
            TrendReport result = new TrendReport();
            result.EndReportPeriod = System.DateTime.Parse(endDate).Date.Add(System.DateTime.Now.TimeOfDay).ToString("yyyy-MM-dd HH:mm:ss");

            var finalEndDate = System.DateTime.Parse(endDate).Date.Add(System.DateTime.Now.TimeOfDay).ToString("yyyy-MM-ddTHH:mm:ss");

            try
            {
                using(SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_eCIL_Report_Trend", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    command.Parameters.Add(new SqlParameter("@VarId", taskId));
                    command.Parameters.Add(new SqlParameter("@EndDate", finalEndDate));
                    command.Parameters.Add(new SqlParameter("@LanguageId", languageId));
                    using(SqlDataReader reader = command.ExecuteReader())
                    {
                        result.EmagData = new List<EmagData>();
                        while(reader.Read())
                            result.EmagData.Add(ConvertReaderToTrendReport(reader));
                        reader.NextResult();
                        result.Trends = new List<Trend>();
                        while (reader.Read())
                        {
                            Trend temp = new Trend();
                            
                            if (!reader.IsDBNull(reader.GetOrdinal("TrendDay")))
                                temp.TrendDay = reader.GetInt32(reader.GetOrdinal("TrendDay"));
                            if (!reader.IsDBNull(reader.GetOrdinal("TrendMonth")))
                                temp.TrendMonth = reader.GetInt32(reader.GetOrdinal("TrendMonth"));
                            if (!reader.IsDBNull(reader.GetOrdinal("ColNum")))
                                temp.ColNum = reader.GetInt32(reader.GetOrdinal("ColNum"));
                            result.Trends.Add(temp);
                        }
                    }
                }
                return result;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
        #endregion

        #region Utilities
        public EmagData ConvertReaderToTrendReport(SqlDataReader reader)
        {
            try
            {
                EmagData temp = new EmagData();
                if (!reader.IsDBNull(reader.GetOrdinal("TaskId")))
                    temp.TaskId = reader.GetString(reader.GetOrdinal("TaskId"));
                if (!reader.IsDBNull(reader.GetOrdinal("FL4")))
                    temp.Fl4 = reader.GetString(reader.GetOrdinal("FL4"));
                if (!reader.IsDBNull(reader.GetOrdinal("VarDesc")))
                    temp.Task = reader.GetString(reader.GetOrdinal("VarDesc"));
                if (!reader.IsDBNull(reader.GetOrdinal("TaskFreq")))
                    temp.Frequency = reader.GetString(reader.GetOrdinal("TaskFreq"));

                temp.Values = DateTime.ConvertFromReaderToDateTimeListBasedOnIndexWith35Days(reader);

                if (!reader.IsDBNull(reader.GetOrdinal("VarId")))
                    temp.VarId = reader.GetInt32(reader.GetOrdinal("VarId"));

                return temp;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }

        }
        #endregion

        #region SubClasses
        public class Trend
        {
            #region Variable
            private int trendDay;
            private int trendMonth;
            private int colNum;
            #endregion

            #region Properties
            public int TrendDay { get => trendDay; set => trendDay = value; }
            public int TrendMonth { get => trendMonth; set => trendMonth = value; }
            public int ColNum { get => colNum; set => colNum = value; }
            #endregion

        }
        #endregion
    }
}
