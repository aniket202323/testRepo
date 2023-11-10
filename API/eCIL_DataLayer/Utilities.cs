using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Net.Http.Headers;
using System.IO;
using System.Collections.ObjectModel;
using System.Net.Http;
using System.Configuration;
using System.Web;

namespace eCIL_DataLayer
{
    public class Utilities
    {
        #region Variables
        public enum TaskResultsOffset : int
        {
            Undefined = 0,
            Pending = 1,
            Ok = 2,
            Defect = 3,
            Late = 4,
            Missed = 5
        }
        #endregion

        #region Methods
        public static T DirectCast<T>(object o, Type type) where T : class
        {
            if (!(type.IsInstanceOfType(o)))
            {
                throw new ArgumentException();
            }
            T value = o as T;
            if (value == null && o != null)
            {
                throw new InvalidCastException();
            }
            return value;
        }

        public string GetSiteName(string _connectionString)
        {
            string SiteName = string.Empty;
            try
            {
                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    SqlCommand command = new SqlCommand("spLocal_STI_Cmn_GetSiteName", conn);
                    command.CommandType = System.Data.CommandType.StoredProcedure;
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            SiteName = reader.GetString(0);
                        }
                        reader.Close();
                    }
                    conn.Close();
                }

                return SiteName;
            }
            catch
            {
                return null;
            }
        }

        public string GetSiteLang(string _connectionString)
        {
            try
            {
                string SiteLang = string.Empty;
                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    string query = @"select l.Lang_Abbrev
                                     from dbo.Site_Parameters sp 
                                     join dbo.Parameters p on p.Parm_Id = sp.Parm_Id 
                                     join dbo.Languages l on l.Language_Id = sp.Value where p.Parm_Id = 8";

                    SqlCommand command = new SqlCommand(query, conn);
                    command.CommandType = System.Data.CommandType.Text;

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            if (!reader.IsDBNull(reader.GetOrdinal("Lang_Abbrev")))
                                SiteLang = reader.GetString(0);
                        }
                        reader.Close();
                    }
                    conn.Close();
                }
                return SiteLang;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }

        public int GetSiteParamSpecSetting(string _connectionString)
        {
            try
            {
                int ParamCount = 0;
                using (SqlConnection conn = new SqlConnection(_connectionString))
                {
                    conn.Open();
                    string query = @"SELECT Count(f.Field_Desc) AS Param_count from dbo.site_parameters s
				                     JOIN dbo.parameters p on s.parm_id=p.parm_id
                                     JOIN dbo.ed_fieldtype_validvalues f on f.ed_field_type_id = p.field_type_id and f.field_id = s.value
				                     WHERE p.Parm_Long_Desc like '%spec%' and f.Field_Desc  like  '%=%'";

                    SqlCommand command = new SqlCommand(query, conn);
                    command.CommandType = System.Data.CommandType.Text;

                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            if (!reader.IsDBNull(reader.GetOrdinal("Param_count")))
                                ParamCount = reader.GetInt32(0);
                        }
                        reader.Close();
                    }
                    conn.Close();
                }
                return ParamCount;
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }


        public string VerifyFrequency(int frequency)
        {
            string errormessage = null;
            if (!(string.IsNullOrEmpty(frequency.ToString())))
            {
                Regex re = new Regex("^[0-9 ]+$");

                if (!(re.IsMatch(frequency.ToString())))
                {
                    errormessage = "Incorrect format of Frequency. Must be numeric";
                }
            }
            else
            {
                errormessage = "Incorrect format of Frequency. Should not be empty.";
            }
            return errormessage;
        }

        public string VerifyFrequencyRange(int frequency, string frequencyType)
        {
            string errormessage = null;
            if (frequencyType == "Shiftly")
            {
                if (frequency != 0)
                {
                    errormessage = "Incorrect format of Frequency.Must be 0 for Shiftly task.";
                }
            }
            else if (frequencyType == "Daily")
            {
                if (frequency != 1)
                {
                    errormessage = "Incorrect format of Frequency.Must be 1 for Daily task.";
                }
            }
            else if (frequencyType == "Multi-Day")
            {
                if (!((frequency >= 2) && (frequency <= 365)))
                {
                    errormessage = "Incorrect format of Frequency.Must be between 0 to 365 for a multi-day task.";
                }
            }
            else if (frequencyType == "Minutes")
            {
                if ((frequency >= 10) && (frequency <= 634))
                {
                    if ((frequency % 5) != 0)
                    {
                        errormessage = "Incorrect format of Frequency.Must be Multiple of 5 for Minutely tasks.";
                    }
                }
                else
                {
                    errormessage = "Incorrect format of Frequency.Must be between 10 to 634 for a minutely task.";
                }

            }
            return errormessage;
        }

        public string VerifyWindow(int window)
        {
            string errormessage = null;
            if (!(string.IsNullOrEmpty(window.ToString())))
            {
                Regex re = new Regex("^[0-9 ]+$");
                if (!(re.IsMatch(window.ToString())))
                {
                    errormessage = "Incorrect format of Window. Must be numeric";
                }
            }
            else
            {
                errormessage = "Incorrect format of Window. Must not be empty.";
            }
            return errormessage;
        }

        public string VerifyWindowRange(int window, int frequency, string frequencyType)
        {
            string errormessage = null;

            if (frequencyType == "Shiftly")
            {
                if ((!(window >= 0)))
                {
                    errormessage = "Incorrect format of Window. Must be greater than equals to 0 for Shiftly tasks";
                }
            }
            else if (frequencyType == "Daily")
            {
                if ((!(window >= 0)) && (!(window < 24)))
                {
                    errormessage = "Incorrect format of Window. Must be greater than equals to 0 and less than 24 for Daily tasks";
                }
            }
            else if (frequencyType == "Minutes")
            {
                if ((window >= 0) && (window <= frequency))
                {
                    if ((window % 5) != 0)
                    {
                        errormessage = "Incorrect format of Window. Must be multiple of 5";
                    }
                }
                else
                {
                    errormessage = "Incorrect format of Window. Must be greater than equals to 0 and less than frequency for Minutes tasks";
                }
            }
            else if (frequencyType == "Multi-Day")
            {
                if ((window >= 0) && (window <= frequency))
                {
                    errormessage = null;
                }
                else
                {
                    errormessage = "Incorrect format of Window. Must be greater than equals to 0 and less than frequency for Multi-Day and Minutes tasks";
                }
            }


            return errormessage;
        }

        public string VerifyShiftOffset(int shiftoffset)
        {
            string errormessage = null;
            if (!(string.IsNullOrEmpty(shiftoffset.ToString())))
            {
                Regex re = new Regex("^[0-9 ]+$");
                if (!(re.IsMatch(shiftoffset.ToString())))
                {
                    errormessage = "Incorrect format of ShiftOffset. Must be numeric";
                }
            }
            return errormessage;
        }

        public string VerifyShiftOffsetRange(int shiftOffset, int frequency)
        {
            string errormessage = null;

            if ((shiftOffset >= 0) && (shiftOffset < frequency))
            {
                if ((shiftOffset % 5) != 0)
                {
                    errormessage = "Incorrect format of ShiftOffset.Must be multiple of 5";
                }
            }
            else
            {
                errormessage = "Incorrect format of ShiftOffset.Must be greater than equal to 0 and less than frequency";
            }
            return errormessage;
        }

        public string VerifyTestTime(string testTime, string frequencyType)
        {
            string errormessage = string.Empty;
            if (frequencyType == "Daily" || frequencyType == "Multi-Day")
            {
                if (!(string.IsNullOrEmpty(testTime)))
                {
                    TimeSpan timeResult;
                    Regex re = new Regex("^[0-2][0-9]:[0-5][0-9]$");

                    if (TimeSpan.TryParse(testTime, out timeResult))
                    {
                        if (!(re.IsMatch(testTime)))
                        {
                            errormessage = "Incorrect format of Test Time. Must be HH:MM.";

                        }
                    }
                    else
                    {
                        errormessage = "Incorrect format of Test Time. Must be HH:MM.";
                    }

                }
                else
                {
                    errormessage = "Incorrect format of Test Time. Must be HH:MM.";
                }
            }
            return errormessage;
        }

        public  string DeleteImage(string fileName, string folderPath)
        {
           if(fileName.Contains("\"") || fileName.Contains("/"))
            {
                return "invalid file name";
            }

           var filePath = System.Web.Hosting.HostingEnvironment.MapPath("~/") + folderPath + fileName;
            if (File.Exists(filePath))
            {
                File.Delete(filePath);
            }

            return "file deleted";
        }

        public byte[] GetImage(string fileName, string folderPath)
        {
            var path = System.Web.Hosting.HostingEnvironment.MapPath("~/") + folderPath +fileName;
          
            byte[] binaryImage = File.ReadAllBytes(path);
          
            return binaryImage;
        }

            public string SaveImage(HttpPostedFile httpPostedFile, string filename, string folderPath)
        {
            // string path = string.Empty;
            var path = System.Web.Hosting.HostingEnvironment.MapPath("~/") + folderPath;
            string targetLocation = path;
            if (filename.EndsWith(".JPG") || filename.EndsWith(".jpg"))
                path = $@"{targetLocation}{filename}";
            else if (filename.EndsWith(".JPEG") || filename.EndsWith(".jpeg"))
                path = $@"{targetLocation}{filename}";
            else if (filename.EndsWith(".PNG") || filename.EndsWith(".png"))
                path = $@"{targetLocation}{filename}";
            else
            {
                throw new HttpException("Please upload valid format file.");
            }
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
                throw new HttpException(500, ex.Message);
            }
            try
            {
                httpPostedFile.SaveAs(path);
            }
            catch (Exception ex)
            {
                throw new HttpException(" Error writting in " + path + " -- " + ex.Message);
            }

            return filename;
        }

        #endregion

    }
}
