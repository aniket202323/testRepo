using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class Status
    {
        private string orderStatus = string.Empty;
        public string OrderStatus { get => orderStatus; set => orderStatus = value; }
    }
}