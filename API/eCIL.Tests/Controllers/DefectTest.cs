
using System;
using NUnit;
using NUnit.Framework;
using eCIL;
using eCIL_DataLayer;
using eCIL.Controllers;

namespace eCIL.Test.Controllers
{
    [TestFixture]
    public class DefectTest
    {
        public const string connectionStrings = "Server=brtc-mslab081;";
        public const string database = " Initial Catalog=GBDB;User ID=MESECIL;Password=MESECIL;Application Name=eCIL";
        public const string eDHToken = "";

        public Defect.CILDefect myDefect = new Defect.CILDefect
        {
            UserName = "",
            FLCode = "DIMR-111-536",
            PMNotification = false,
            Description = "API eDH Test",
            SourceRecordID = 377631360,
            DefectComponentId = null,
            PriorityId = 25,
            Repeat = true,
            UserId = 123,
            DefectTypeCode = "DEF5",
            HowFoundId = 19,
            ServerCurrentResult = "Defect"
        };

        [Test]
        public void TestRepeatDefectInModel()
        {
            Defect.CILDefect defect = new Defect.CILDefect();
            Assert.IsTrue(defect.GetType().GetProperty("Repeat") != null);
        }

        [Test]
        public void TestRequiredDefectFields()
        {
            Defect.CILDefect defect = new Defect.CILDefect();
            Assert.IsTrue(defect.GetType().GetProperty("DefectComponentId") != null);
            Assert.IsTrue(defect.GetType().GetProperty("HowFoundId") != null);
            Assert.IsTrue(defect.GetType().GetProperty("PriorityId") != null);
        }

        [Test]
        public void TestConditionRequiredDefectFields()
        {
            Defect defect = new Defect();
            try
            {
                defect.AddDefect(myDefect, connectionStrings + database, eDHToken);
            }
            catch (Exception ex)
            {
                Assert.AreEqual("Defect Component, How Found and/or Priority: cannot be empty", ex.Message);
            }
        }
    }

    
}
