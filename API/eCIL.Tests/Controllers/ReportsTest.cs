using System;
using System.Collections.Generic;
using System.Text;
using eCIL_DataLayer;
using eCIL_DataLayer.Reports;
using NUnit.Framework;
using System.Linq;

namespace eCIL.Test.Controllers
{
    /// <summary>
    /// Descripción resumida de ReportsTest
    /// </summary>
    [TestFixture]
    public class ReportsTest
    {

        public const string connectionStrings = "Server=brtc-mslab081;";
        public const string database = " Initial Catalog=GBDB;User ID=MESECIL;Password=MESECIL;Application Name=eCIL";
        public String lineId = "577";

        [Test]
        public void TestActiveSchedulingReportInClass()
        {
            TaskEdit task = new TaskEdit();
            Assert.IsTrue(task.GetType().GetProperty("Active") != null);
        }

        [Test]
        public void TestActiveSchedulingReportInListResponse()
        {
            ReportSchedulingErrors tasks = new ReportSchedulingErrors();
            List<ReportSchedulingErrors> list = tasks.GetTaskList(connectionStrings + database, null, lineId, null, null, null, null).ToList();
            ReportSchedulingErrors def = list.FirstOrDefault();
            Assert.IsTrue(def.GetType().GetProperty("Active") != null);
        }

        [Test]
        public void TestActiveSchedulingReportIsBoolean()
        {
            ReportSchedulingErrors tasks = new ReportSchedulingErrors();
            List<ReportSchedulingErrors> list = tasks.GetTaskList(connectionStrings + database, null, lineId, null, null, null, null).ToList();
            ReportSchedulingErrors def = list.FirstOrDefault();
            Assert.IsNotInstanceOf<bool>(def.GetType().GetProperty("Active"));
        }
    }
}
