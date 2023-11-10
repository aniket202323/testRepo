using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace eCIL.Models
{
    public class Comment
    {
        public List<String> attachments { get; set; }
        public string commentText { get; set; }
        public string commentType { get; set; }
        public long entityId { get; set; }
        public string entityType { get; set; }
    }
}