using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web;


namespace BatchArchiveValidation.Helper
{
    public class Logger
    {

        public static void Writelog(string message)
        {
            string logFileEnable = ConfigurationManager.AppSettings["LogFileEnable"].ToString();
            if (logFileEnable == "True")
            {
                string logPath = ConfigurationManager.AppSettings["LogFilePath"].ToString();

                using (StreamWriter writer = new StreamWriter(logPath, true))
                {
                    writer.WriteLine($"{DateTime.Now}:{message}");

                }

            }
        }
    }
}