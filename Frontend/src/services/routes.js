import axios from "axios";
import { getUserId } from "./auth";
import { requestSuccess, requestError } from "../utils";
import { baseURL } from "../../package.json";

function getAllRoutes() {
  return axios
    .get(baseURL + `api/routes`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getMyRoutes() {
  let userId = getUserId();

  return axios
    .get(baseURL + `api/routes?userId=${userId}`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getRoutes() {
  return axios
    .get(baseURL + `api/routes/getroutessummary`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getRouteTeams(routeId) {
  return axios
    .get(baseURL + `api/routes/getrouteteams`, {
      params: {
        RouteId: routeId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getReportRouteTasks(routeId) {
  return axios
    .get(baseURL + `api/routes/getreportroutetasks`, {
      params: {
        RouteId: routeId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getRouteTasks(routeId) {
  return axios
    .get(baseURL + `api/routes/getroutetasks`, {
      params: {
        RouteId: routeId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getReportRouteActivity(routeId) {
  return axios
    .get(baseURL + `api/routes/getreportrouteactivity`, {
      params: {
        RouteId: routeId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function addRoute(route) {
  return axios
    .post(baseURL + `api/routes`, route)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updateRoute(route) {
  return axios
    .put(baseURL + `api/routes`, route)
    .then((res) => {
      requestSuccess();
      return res;
    })
    .catch((error) => {
      requestError(error.response);
      return error;
    });
}

function UpdateSheetDesc(route) {
  return axios
    .put(baseURL + `api/routes/UpdateSheetDesc`, route)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function deleteRoutes(routeIds) {
  return axios
    .delete(baseURL + `api/routes`, {
      params: {
        RouteIds: routeIds,
      },
    })
    .then(() => requestSuccess())
    .catch((error) => "showErrorMessage(error.response)");
}

function updataRouteTeamsAssociations(data) {
  return axios
    .put(baseURL + `api/routes/updaterouteteamsassociations`, data)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updataRouteTasksAssociations(data) {
  return axios
    .put(baseURL + `api/routes/updateroutetasksassociations`, data)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function getReportAllRouteTeams() {
  return axios
    .get(baseURL + `api/routes/getreportallrouteteams`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getReportAllRouteTasks() {
  return axios
    .get(baseURL + `api/routes/getreportallroutetasks`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function findRouteId(Var_Id) {
  return axios
    .get(baseURL + `api/routes/findrouteId`, {
      params: {
        Var_Id,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function createRouteDisplay(Route, url) {
  return axios
    .put(baseURL + `api/routes/createroutedisplay`, Route, {
      params: { url },
    })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updateDisplayVariablesAssociations(route) {
  return axios
    .put(baseURL + `api/routes/updatedisplayvariablesassociations`, route)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

async function IsIntegratedRoute(Route_Id) {
  return axios
    .get(baseURL + `api/routes/IsIntegratedRoute`, {
      params: {
        Route_Id,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

async function CheckIfRouteHasQR(Route_Ids) {
  return axios
    .get(baseURL + `api/routes/CheckIfRouteHasQR`, {
      params: {
        Route_Ids,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

export {
  getAllRoutes,
  getMyRoutes,
  getRoutes,
  getRouteTeams,
  getReportRouteTasks,
  getRouteTasks,
  getReportRouteActivity,
  addRoute,
  updateRoute,
  deleteRoutes,
  updataRouteTeamsAssociations,
  updataRouteTasksAssociations,
  getReportAllRouteTeams,
  getReportAllRouteTasks,
  findRouteId,
  createRouteDisplay,
  updateDisplayVariablesAssociations,
  UpdateSheetDesc,
  IsIntegratedRoute,
  CheckIfRouteHasQR,
};
