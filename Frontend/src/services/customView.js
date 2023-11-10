import axios from "axios";
import { getUserId, getProfile } from "./auth";
import { requestSuccess, requestError } from "../utils";
import { baseURL } from "../../package.json";

// function getCustomView(screenDescription = "DataEntry") {
//   let userId = getUserId();

//   return axios
//     .get(baseURL + "api/customview", {
//       params: {
//         userId: userId,
//         screenDescription: screenDescription,
//       },
//     })
//     .then((response) => response.data)
//     .catch((error) => requestError(error.response));
// }

function getCustomView(screenDescription = "DataEntry") {
  let userId = getUserId();

  return axios({
    method: "get",
    url: baseURL + "api/customview",
    withCredentials: true,
    params: {
      userId: userId,
      screenDescription: screenDescription,
    },
  })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function deleteCustomView(upId) {
  return axios
    .delete(baseURL + "api/customView", {
      params: {
        UPId: upId,
      },
    })
    .then((success) => requestSuccess(success))
    .catch((error) => requestError(error.response));
}

function saveCustomView(view) {
  return axios
    .put(baseURL + `api/customview`, view)
    .then((success) => requestSuccess(success))
    .catch((error) => requestError(error.response));
}

function setSiteDefaultView(upId) {
  let langId = getProfile().LanguageId;

  return axios
    .put(baseURL + "api/customview/setsitedefaultview", null, {
      params: {
        UPId: upId,
        LanguageId: langId,
      },
    })
    .then((success) => requestSuccess(success))
    .catch((error) => requestError(error.response));
}

function setUserDefaultView(upId) {
  let userId = getUserId();
  let langId = getProfile().LanguageId;

  return axios
    .put(baseURL + "api/customview/setuserdefaultview", null, {
      params: {
        UPId: upId,
        UserId: userId,
        LanguageId: langId,
      },
    })
    .then((success) => requestSuccess(success))
    .catch((error) => requestError(error.response));
}

export {
  getCustomView,
  deleteCustomView,
  saveCustomView,
  setSiteDefaultView,
  setUserDefaultView,
};
