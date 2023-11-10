using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace eCIL.Models
{
    public class UpdateComment
    {
        public int threadId { get; set; }
        public int commentId { get; set; }
        public List<String> attachments { get; set; }
        public string commentText { get; set; }
        public string commentType { get; set; }
        public long entityId { get; set; }
        public string entityType { get; set; }
    }
}