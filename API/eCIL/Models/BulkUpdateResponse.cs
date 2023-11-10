using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace eCIL.Models
{
    public class BulkUpdateResponse
    {

        public BulkUpdateResponse(String type) {
            EntityType = type;
            SuccesfullUpdates = new List<long>();
            FailedUpdates = new List<long>();
            Message = "";
        }

        public String EntityType, Message;
        public List<long> SuccesfullUpdates, FailedUpdates;
    }
}