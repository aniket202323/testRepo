using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace eCIL.Models
{
        public class TestValueRecord
        {
            public long testValueRecordId { get; set; }
            public Department department { get; set; }
            public Line line { get; set; }
            public Asset asset { get; set; }
            public DateTime testTime { get; set; }
            public Variable variable { get; set; }
            public int associatedEventRecordId { get; set; }
            public string testValue { get; set; }
            public object commentsThreadId { get; set; }
            public object eSignatureId { get; set; }
            public object secondUser { get; set; }
            public bool canceled { get; set; }
            public object arrayId { get; set; }
            public object hasHistory { get; set; }
            public int isLocked { get; set; }
            public DateTime entryOn { get; set; }
            public User user { get; set; }
            public int dataTypeId { get; set; }
            public object varPrecision { get; set; }
            public object activityId { get; set; }
        }

        public class Department
        {
            public string name { get; set; }
            public int assetId { get; set; }
            public string type { get; set; }
        }

        public class Line
        {
            public string name { get; set; }
            public int assetId { get; set; }
            public string type { get; set; }
        }

        public class Asset
        {
            public string name { get; set; }
            public int assetId { get; set; }
            public string type { get; set; }
        }

        public class Variable
        {
            public int id { get; set; }
            public string name { get; set; }
        }

        public class User
        {
            public int id { get; set; }
            public string name { get; set; }
        }
}