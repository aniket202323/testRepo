import axios from "axios";
import { requestSuccess, requestError } from "../utils";
import { baseURL } from "../../package.json";
import { warning } from "./notification";

function getTourStopInfo(routeId) {
  return axios
    .get(baseURL + `api/tourstop/getTourStopInfo`, { params: { routeId } })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTourStop(routeId) {
  return axios
    .get(baseURL + `api/tourstop/getTourStop`, { params: { routeId } })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTourMapImage(tourId) {
  return axios
    .get(baseURL + `api/TourStop/getTourMapImage`, { params: { tourId } })
    .then((response) => response.data)
    .catch((error) => {
      return error.response;
    });
}

function AddTourStop(TourStop) {
  return axios
    .post(baseURL + `api/tourstop/AddTourStop`, TourStop)
    .then((response) => {
      requestSuccess();
      return response.data;
    })
    .catch((error) => requestError(error.response));
}

function updatetourstoptasks(TourStop) {
  return axios
    .put(baseURL + `api/tourstop/updatetourstoptasks`, TourStop)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function deleteTourStop(TourStop) {
  return axios
    .delete(baseURL + `api/tourstop/DeleteTourStop`, {
      data: TourStop,
    })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updateTourStopDesc(TourStop) {
  return axios
    .put(baseURL + `api/tourstop/updateTourStopDesc`, TourStop)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

// function updateTourMapLink(TourStop) {
//   return axios
//     .put(baseURL + `api/tourstop/updateTourMapLink`, TourStop)
//     .then(() => requestSuccess())
//     .catch((error) => requestError(error.response));
// }

function uploadTourMap(formData, config) {
  const url = baseURL + `api/tourstop/uploadTourMapImage`;
  return axios
    .post(url, formData, config)
    .then(() => requestSuccess())
    .catch((error) => {
      if (error.response?.data?.ExceptionMessage.includes("No file"))
        warning("No file selected for upload.");
      if (error.response?.data?.ExceptionMessage.includes("5MB"))
        warning("Please select file less than 5MB.");
      if (error.response?.data?.ExceptionMessage.includes("format file"))
        warning("Please upload valid format (.JPG or .JPEG or .PNG) file.");
      else requestError(error.response);
    });
}

function getOpsHubServer() {
  return axios
    .get(baseURL + `api/get-opshub-server`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

// copy from other tour stop
function updateTourMapLink(tourStop) {
  return axios
    .put(baseURL + `api/tourstop/CopyTourStopMapImage`, tourStop)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

// unlink
function unlinkTourStopMapImage(tourStop) {
  return axios
    .put(baseURL + `api/tourstop/UnlinkTourStopMapImage`, tourStop)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function deleteTourStopMapImage(filename) {
  return axios
    .delete(baseURL + `api/tourstop/DeleteTourStopMapImage`, {
      params: { filename: filename },
    })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function getTourMapImageCount(tourMap) {
  return axios
    .get(baseURL + `api/TourStop/getTourMapImageCount`, { params: { tourMap } })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

export {
  getTourStopInfo,
  getTourStop,
  AddTourStop,
  updatetourstoptasks,
  deleteTourStop,
  updateTourStopDesc,
  updateTourMapLink,
  uploadTourMap,
  getTourMapImage,
  getOpsHubServer,
  // updateTourMapLink,
  unlinkTourStopMapImage,
  deleteTourStopMapImage,
  getTourMapImageCount,
};
