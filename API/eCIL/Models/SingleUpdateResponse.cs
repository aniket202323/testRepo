using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace eCIL.Models
{
    public class SingleUpdateResponse
    {
        public SingleUpdateResponse(String type) {
            EntityType = type;
            Succesfull = false;
            Message = "";
            id = -1;
        }

        public String EntityType;
        public String Message;
        public bool Succesfull;
        public long id;
    }
}