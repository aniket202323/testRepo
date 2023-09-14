using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace BatchDataLayer.Models
{
    public class GetOrderDetailStatus
    {
        public List<OrderDetails> orderDetails { get; set; }
        public Status status { get; set; }
    }
}