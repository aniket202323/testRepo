import axios from "axios";
import i18next from "i18next";
import { getUserId } from "./auth";
import { displayPreload } from "../components/Framework/Preload";
import { requestSuccess, requestError } from "../utils";
import { baseURL } from "../../package.json";

// const promptPosition = {
//   1: "Pending",
//   2: "Ok",
//   3: "Defect",
//   4: "Late",
//   5: "Missed",
// };

// function getPrompts() {
//   return axios
//     .get(baseURL + `api/tasks/serverresultprompts`)
//     .then((response) => {
//       response.data.map((res) => (res.LangPrompt = i18next.t(res.UserPrompt)));
//       return response.data;
//     })
//     .catch((error) => requestError(error.response));
// }

function getPPAVersion() {
  return axios({
    method: "get",
    url: baseURL + "api/tasks/getppaversionaspected",
    withCredentials: true,
  })
    .then((response) => {
      return response.data;
    })
    .catch((error) => requestError(error.response));
}

function getPrompts() {
  return axios({
    method: "get",
    url: baseURL + "api/tasks/serverresultprompts",
    withCredentials: true,
  })
    .then((response) => {
      response.data.map((res) => (res.LangPrompt = i18next.t(res.UserPrompt)));
      return response.data;
    })
    .catch((error) => requestError(error.response));
}

function getLineTasks(line) {
  return axios
    .get(baseURL + `api/tasks?lineId=${line}`)
    .then((response) => response.data || [])
    .catch((error) => requestError(error.response));
}

function getTasksPlantModelEditList(deptIds, lineIds = null) {
  return axios
    .get(baseURL + `api/tasks/gettasksbyplantmodel`, {
      params: {
        deptIds: deptIds,
        lineIds,
      },
    })
    .then((response) => {
      response.data.forEach((row) => {
        row.Status = "";
        row.KeyFlag = Math.random().toString(36).slice(2).substring(0, 5);
        // row.AutoPostpone = row.AutoPostpone === 1;
        // row.PrimaryQFactor = row.PrimaryQFactor === "Yes" ? true : false;
        return row;
      });

      return response.data;
    })
    .catch((error) => requestError(error.response));
}

function getTasksFLEditList(flList) {
  return axios
    .get(baseURL + `api/tasks/gettasksbyfllist`, {
      params: {
        FlList: flList,
      },
    })
    .then((response) => {
      response.data.forEach((row) => {
        row.Status = "";
        return row;
      });

      return response.data;
    })
    .catch((error) => requestError(error.response));
}

function saveTasks(tasks) {
  let userId = getUserId();
  return (
    axios
      .post(baseURL + `api/tasks/savemgmttasks?userId=${userId}`, tasks)
      // .then(() => requestSuccess())
      .then((response) => response.data)
      .catch((error) => {
        requestError(error.response);
        throw error;
      })
  );
}

function saveTasksVersionMgmt(tasks) {
  let userId = getUserId();
  return axios
    .post(baseURL + `api/tasks/savemgmttasks?userId=${userId}`, tasks)
    .then((response) => {
      // requestSuccess();
      return response.data;
    })
    .catch((error) => {
      requestError(error.response);
      displayPreload(false);
    });
}

function addTask(task) {
  let userId = getUserId();

  return axios
    .post(baseURL + `api/tasks/add?userId=${userId}`, task)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updateTask(task) {
  let userId = getUserId();

  return axios
    .put(baseURL + `api/tasks/update?userId=${userId}`, task)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function deleteTask(task) {
  let userId = getUserId();

  return axios
    .delete(baseURL + `api/tasks/delete?userId=${userId}`, {
      data: task,
    })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function getLineTasksSelection(line) {
  return axios
    .get(baseURL + `api/tasks?lineId=${line}`)
    .then((response) => {
      response.data.forEach((item) => {
        item.IsEdited = false;
        item.IsSelected = false;
        return item;
      });

      return response.data;
    })
    .catch((error) => requestError(error.response));
}

function getTaskInfo(testId) {
  return axios
    .get(baseURL + `api/tasks/gettaskdetails?testId=${testId}`)
    .then((response) => {
      return response.data;
    })
    .catch((error) => requestError(error.response));
}

function getTeamsTasksSelection(teams) {
  if (teams)
    return axios
      .get(baseURL + `api/tasks?teams=${teams}`)
      .then((response) => {
        response.data.forEach((item) => {
          item.IsEdited = false;
          item.IsSelected = false;
          return item;
        });

        return response.data;
      })
      .catch((error) => requestError(error.response));
  else return Promise.resolve();
}

function getRoutesTasksSelection(routes) {
  if (routes)
    return axios
      .get(baseURL + `api/tasks?routes=${routes}`)
      .then((response) => {
        response.data.forEach((item) => {
          item.IsEdited = false;
          item.IsSelected = false;
          return item;
        });

        return response.data;
      })
      .catch((error) => requestError(error.response));
  else return Promise.resolve();
}

function updateTaskSelection(task) {
  return axios
    .put(baseURL + `api/tasks`, task)
    .then((response) => {
      if (response.data === "OK") requestSuccess();
      else return response.data;
    })
    .catch((error) => requestError(error.response));
}

function saveTasksSelection(tasks) {
  return axios
    .put(baseURL + "api/tasks", tasks)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

// Test outside OpsHub adding the OpsHubToken in Header
// https://brtc-mslab131/AuthenticationService/Swagger/index.html
// POST https://brtc-mslab131/AuthenticationService/Authentication/UserCredentialsAuthentication
// Use the id_token for test
// Also add <add key="ProficyServer" value="brtc-mslab163.na.pg.com:5059" /> into appSettings web.config file

function setTasksValues(data) {
  let id_token = sessionStorage.getItem("OpsHubToken");
  let _data = formatObjectForCLTaskValue(data);
  let Authorization = "Bearer " + id_token;
  let headers = { Authorization };
  return axios
    .put(baseURL + "api/tasks/settasksvalues", _data, { headers })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function addComments(tasks) {
  let id_token = sessionStorage.getItem("OpsHubToken");
  let _tasks = formatObjectForCLComments(tasks);
  let Authorization = "Bearer " + id_token;
  let headers = { Authorization };
  return axios
    .post(baseURL + `api/tasks/AddComments`, _tasks, { headers })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updateComments(tasks) {
  let id_token = sessionStorage.getItem("OpsHubToken");
  let _tasks = formatObjectForCLComments(tasks, true);
  let Authorization = "Bearer " + id_token;
  let headers = { Authorization };
  return axios
    .put(baseURL + "api/tasks/UpdateComments", _tasks, { headers })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function formatObjectForCLComments(array, isUpdating = false) {
  let result = [];
  if (!isUpdating)
    array.forEach((data) => {
      let obj = {
        attachments: null,
        commentText: data.CommentInfo,
        commentType: "Tests",
        entityId: data.TestId,
        entityType: "Tests",
      };
      result.push(obj);
    });
  else
    array.forEach((data) => {
      let objUpdate = {
        threadId: data.CommentId,
        commentId: data.CommentId,
        attachments: null,
        commentText: data.CommentInfo,
        commentType: "Tests",
        entityId: data.TestId,
        entityType: "Tests",
      };
      result.push(objUpdate);
    });

  return result;
}

function formatObjectForCLTaskValue(array) {
  let result = [];
  array.forEach((data) => {
    result.push({
      testValueRecordId: data.TestId,
      department: null,
      line: {
        name: data.LineDesc,
        assetId: null,
        type: null,
      },
      asset: null,
      testTime: data.ResultOn,
      variable: {
        id: data.VarId,
        name: data.VarDesc,
      },
      associatedEventRecordId: null,
      testValue:
        data.CurrentResult === ""
          ? null
          : data.CurrentResult === "1"
          ? true
          : data.CurrentResult === "0"
          ? false
          : data.CurrentResult,
      commentsThreadId: null,
      eSignatureId: null,
      secondUser: null,
      canceled: null,
      arrayId: null,
      hasHistory: null,
      isLocked: null,
      entryOn: data.ScheduleTime,
      user: null,
      dataTypeId: null,
      varPrecision: null,
      activityId: null,
    });
  });

  return result;
}

export {
  getPPAVersion,
  getPrompts,
  getLineTasks,
  getTasksPlantModelEditList,
  getTasksFLEditList,
  addTask,
  updateTask,
  deleteTask,
  saveTasks,
  saveTasksVersionMgmt,
  getLineTasksSelection,
  getTaskInfo,
  getTeamsTasksSelection,
  getRoutesTasksSelection,
  updateTaskSelection,
  saveTasksSelection,
  setTasksValues,
  addComments,
  updateComments,
};
