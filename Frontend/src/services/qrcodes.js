import axios from "axios";
import { requestSuccess, requestError } from "../utils";
import { baseURL } from "../../package.json";
import { warning } from "./notification";

// BY ROUTES
function getQRPathForAssignByRoute(routeId, url) {
  return axios
    .get(baseURL + `api/routes/generateQRCodeForRoute`, {
      params: {
        RouteId: routeId,
        mainUrl: url,
      },
    })
    .then((response) => {
      return response.data;
    })
    .catch((error) => requestError(error.response));
}

function getAllQRForRoute() {
  return axios
    .get(baseURL + `api/QRCodes/getAllQRCodeInfoForRoute`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function deleteQRCode(qrId) {
  let qrcodesParam = {
    qrId,
  };
  return axios
    .post(baseURL + `api/routes/deleteQRCode`, qrcodesParam)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

// BY TASKS
function getQRCodeForTaskById(qrCodeProps) {
  return axios
    .post(baseURL + `api/routes/getQRCodeForTaskById `, qrCodeProps)
    .then((response) => {
      return response.data;
    })
    .catch((error) => requestError(error.response));
}

function getAllQRFortask() {
  return axios
    .get(baseURL + `api/QRCodes/getAllQRCodeInfoForTask`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function saveQRCodeInfo(qrCodeProps) {
  return axios
    .post(baseURL + `api/QRCodes/saveQRCodeInfo`, qrCodeProps)
    .then(() => requestSuccess())
    .catch((error) => {
      return error.response.data.ExceptionMessage;
    });
}

function updateQRDetailsForTask(qrcodesParam) {
  return axios
    .post(baseURL + `api/QRCodes/updateQRCodeInfoForTask`, qrcodesParam)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updateQRCodeName(qrDetailsProps) {
  return axios
    .post(baseURL + `api/routes/updateQRCodeName`, qrDetailsProps)
    .then(() => requestSuccess())
    .catch((error) => {
      if (error.response?.data?.ExceptionMessage.includes("duplicate"))
        warning("The Qr Name already exist.");
      else requestError(error.response);
    });
}

function getInfoForQRId(qrId, IsRouteId) {
  return axios
    .get(baseURL + `api/QRCodes/getInfoForQRId`, {
      params: { qrId, IsRouteId },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getURLInfoByQRId(qrId, IsRouteId) {
  return axios
    .get(baseURL + `api/QRCodes/getURLInfoByQRId`, {
      params: { qrId, IsRouteId },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

// new
function getTourStopListOfRoute(routeId) {
  return axios
    .get(baseURL + `api/tour/gettourstoplistofRoute`, {
      params: { routeId },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getQRCodeForTourStop(qrCodeProps) {
  return axios
    .post(baseURL + `api/routes/getQRCodeForTourStop`, qrCodeProps)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

// on Generate
// function saveQRCodeInfoForTourStop(qrCodeProps) {
//   return axios
//     .post(baseURL + `api/QRCodes/saveQRCodeInfoForTourStop`, qrCodeProps)
//     .then(() => requestSuccess())
//     .catch((error) => {
//       return error.response.data.ExceptionMessage;
//     });
// }

function getAllQRCodeInfoForTourStop() {
  return axios
    .get(baseURL + `api/QRCodes/getAllQRCodeInfoForTourStop`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

export {
  getQRPathForAssignByRoute,
  getAllQRForRoute,
  deleteQRCode,
  getQRCodeForTaskById,
  getAllQRFortask,
  saveQRCodeInfo,
  updateQRDetailsForTask,
  updateQRCodeName,
  getInfoForQRId,
  getURLInfoByQRId,
  getTourStopListOfRoute,
  getQRCodeForTourStop,
  // saveQRCodeInfoForTourStop,
  getAllQRCodeInfoForTourStop,
};
