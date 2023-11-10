import axios from "axios";
import { requestError } from "../utils";
import { baseURL } from "../../package.json";

// function getDBServerName() {
//   return axios
//     .get(baseURL + "api/application/getsitename")
//     .then((response) => response.data)
//     .catch((error) => requestError(error.response));
//   // .then((data) => {
//   //   return PlantName = response.data);
//   // });
// }

function getDBServerName() {
  return axios({
    method: "get",
    url: baseURL + "api/application/getsitename",
    withCredentials: true,
  })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getSiteLang() {
  return axios({
    method: "GET",
    url: baseURL + "api/application/getsitelang",
  })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTimeFrames() {
  return axios
    .get(baseURL + "api/application/gettimeframes")
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getSiteParamSpecSetting() {
  return axios
    .get(baseURL + "api/application/getsiteparamspecsetting")
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

export { getDBServerName, getSiteLang, getTimeFrames, getSiteParamSpecSetting };
