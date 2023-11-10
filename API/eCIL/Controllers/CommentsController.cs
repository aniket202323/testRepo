using eCIL.Models;
using eCIL.Filters;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Web.Http.Filters;
using System.Net;
using System.Text;
using System.Web.Http;
using System.Threading.Tasks;

namespace eCIL.Controllers
{
    public class CommentsController : ApiController
    {

        [HttpPost]
        [eCILAuthorization]
        [Route("api/tasks/AddComment")]
        public async Task<SingleUpdateResponse> AddComments([FromBody] Comment comment)
        {
            SingleUpdateResponse ret = new SingleUpdateResponse("Comments");
            ret.id = comment.entityId;

            try
            {
                IEnumerable<String> values;

                String url = "";
                url = "https://" + System.Configuration.ConfigurationManager.AppSettings["ProficyServer"] +
                    "/comment-service/comment/v2/commentThreads";

                using (HttpClient client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue(
                        Request.Headers.Authorization.Scheme,
                        Request.Headers.Authorization.Parameter);

                    client.DefaultRequestHeaders.ExpectContinue = false;

                    HttpResponseMessage resp = client.PostAsync(url,
                        new StringContent(
                            Newtonsoft.Json.JsonConvert.SerializeObject(comment),
                            Encoding.UTF32, "application/json"
                            )
                        ).Result;

                    if (resp.StatusCode != HttpStatusCode.Created)
                    {
                        throw new Exception("Error " + resp.StatusCode + " returned by Proficy");
                    }

                    ret.Succesfull = true;

                }
            }
            catch (Exception ex)
            {
                ret.Message = ex.Message;
            }

            return ret;
        }

        [HttpPost]
        [eCILAuthorization]
        [Route("api/tasks/AddComments")]
        public BulkUpdateResponse AddComments([FromBody] List<Comment> comments)
        {

            String result = "Update succesfull";
            BulkUpdateResponse response = new BulkUpdateResponse("Comments");

            List<System.Threading.Tasks.Task<SingleUpdateResponse>> tasks = new List<System.Threading.Tasks.Task<SingleUpdateResponse>>();

            foreach (Comment comment in comments)
            {
                try
                {
                    System.Threading.Tasks.Task<SingleUpdateResponse> t = AddComments(comment);
                    tasks.Add(t);
                }
                catch (Exception e)
                {
                    result = e.Message;
                }
            }

            System.Threading.Tasks.Task.WaitAll(tasks.ToArray());

            foreach (System.Threading.Tasks.Task<SingleUpdateResponse> task in tasks)
            {
                if (task.Result.Succesfull)
                {
                    response.SuccesfullUpdates.Add(task.Result.id);
                }
                else
                {
                    response.FailedUpdates.Add(task.Result.id);
                }
            }

            return response;
        }

        [HttpPut]
        [eCILAuthorization]
        [Route("api/tasks/UpdateComment")]
        public async Task<SingleUpdateResponse> UpdateComments([FromBody] UpdateComment updatecomment)
        {
            SingleUpdateResponse ret = new SingleUpdateResponse("UpdateComments");
            ret.id = updatecomment.entityId;

            try
            {
                IEnumerable<String> values;

                String url = "";
                url = "https://" + System.Configuration.ConfigurationManager.AppSettings["ProficyServer"] +
                    "/comment-service/comment/v2/commentThreads/"+updatecomment.threadId+"/comments/"+updatecomment.commentId;

                using (HttpClient client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue(
                        Request.Headers.Authorization.Scheme,
                        Request.Headers.Authorization.Parameter);

                    client.DefaultRequestHeaders.ExpectContinue = false;

                    HttpResponseMessage resp = client.PutAsync(url,
                        new StringContent(
                            Newtonsoft.Json.JsonConvert.SerializeObject(updatecomment),
                            Encoding.UTF32, "application/json"
                            )
                        ).Result;

                    if (resp.StatusCode != HttpStatusCode.OK)
                    {
                        throw new Exception("Error " + resp.StatusCode + " returned by Proficy");
                    }

                    ret.Succesfull = true;

                }
            }
            catch (Exception ex)
            {
                ret.Message = ex.Message;
            }

            return ret;
        }
        [HttpPut]
        [eCILAuthorization]
        [Route("api/tasks/UpdateComments")]
        public BulkUpdateResponse UpdateComments([FromBody] List<UpdateComment> updatecomments)
        {

            String result = "Update succesfull";
            BulkUpdateResponse response = new BulkUpdateResponse("UpdateComments");

            List<System.Threading.Tasks.Task<SingleUpdateResponse>> tasks = new List<System.Threading.Tasks.Task<SingleUpdateResponse>>();

            foreach (UpdateComment updatecomment in updatecomments)
            {
                try
                {
                    System.Threading.Tasks.Task<SingleUpdateResponse> t = UpdateComments(updatecomment);
                    tasks.Add(t);
                }
                catch (Exception e)
                {
                    result = e.Message;
                }
            }

            System.Threading.Tasks.Task.WaitAll(tasks.ToArray());

            foreach (System.Threading.Tasks.Task<SingleUpdateResponse> task in tasks)
            {
                if (task.Result.Succesfull)
                {
                    response.SuccesfullUpdates.Add(task.Result.id);
                }
                else
                {
                    response.FailedUpdates.Add(task.Result.id);
                }
            }

            return response;
        }
    }
}