using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Web.Http;
using NUnit.Framework;
using eCIL;
using eCIL_DataLayer;
using eCIL.Controllers;
using System.Configuration;

namespace eCIL.Tests.Controllers
{
    /// <summary>
    /// Summary description for CustomViewControllerTest
    /// </summary>
    //[TestFixture]
    public class CustomViewControllerTest
    {
        //private int userId;
        //[Test]
        public CustomViewControllerTest()
        {
            //userId = 1850;
        }

        //private TestContext testContextInstance;

        ///// <summary>
        /////Gets or sets the test context which provides
        /////information about and functionality for the current test run.
        /////</summary>
        //public TestContext TestContext
        //{
        //    get
        //    {
        //        return testContextInstance;
        //    }
        //    set
        //    {
        //        testContextInstance = value;
        //    }
        //}

        //#region Additional test attributes
        ////
        //// You can use the following additional attributes as you write your tests:
        ////
        //// Use ClassInitialize to run code before running the first test in the class
        //// [ClassInitialize()]
        //// public static void MyClassInitialize(TestContext testContext) { }
        ////
        //// Use ClassCleanup to run code after all tests in a class have run
        //// [ClassCleanup()]
        //// public static void MyClassCleanup() { }
        ////
        //// Use TestInitialize to run code before running each test 
        //// [TestInitialize()]
        //// public void MyTestInitialize() { }
        ////
        //// Use TestCleanup to run code after each test has run
        //// [TestCleanup()]
        //// public void MyTestCleanup() { }
        ////
        //#endregion

        //[TestMethod]
        //public void TestGetCustomViewsExpectGreaterThan4()
        //{
        //    CustomViewController custom = new CustomViewController();
        //    Assert.IsTrue(custom.Get(userId).Count >= 4); // 4 = System Views counter (Plan model View, FL View, Teams View, Routes View)
        //}

        //[TestMethod]
        //public void TestGetProductionLinesExpectListOfObjectTypes()
        //{
        //    PlantModelController plant = new PlantModelController();
        //    var result = plant.GetProductionLines(0);
        //    Assert.IsInstanceOfType(result, result.GetType());
        //}


    }
}
