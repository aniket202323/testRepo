import axios from "axios";
import { getUserId } from "./auth";
import { requestSuccess, requestError } from "../utils";
import { baseURL } from "../../package.json";

function getAllTeams() {
  return axios
    .get(baseURL + `api/teams`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getMyTeams() {
  let userId = getUserId();

  return axios
    .get(baseURL + `api/teams?userId=${userId}`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTeams() {
  return axios
    .get(baseURL + `api/teams/getteamssummary`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTeamRoutes(teamId) {
  return axios
    .get(baseURL + `api/teams/getteamroutes`, {
      params: {
        teamId: teamId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getReportTeamRoutes(teamId) {
  return axios
    .get(baseURL + `api/teams/getreportteamroutes`, {
      params: {
        teamId: teamId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getReportTeamTasks(teamId) {
  return axios
    .get(baseURL + `api/teams/getreportteamtasks`, {
      params: {
        teamId: teamId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTeamTasks(teamId) {
  return axios
    .get(baseURL + `api/teams/getteamtasks`, {
      params: {
        teamId: teamId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTeamUsers(teamId) {
  return axios
    .get(baseURL + `api/teams/getteamsusers`, {
      params: {
        teamId: teamId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getReportAllTeamRoutes() {
  return axios
    .get(baseURL + `api/teams/getreportallteamroutes`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getReportAllTeamUsers() {
  return axios
    .get(baseURL + `api/teams/getreportallteamusers`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getReportAllTeamTasks() {
  return axios
    .get(baseURL + `api/teams/getreportallteamtasks`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function addTeam(team) {
  return axios
    .post(baseURL + "api/teams/addteam", team)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updateTeam(team) {
  return axios
    .put(baseURL + "api/teams", team)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function deleteTeams(teamIds) {
  return axios
    .delete(baseURL + `api/teams`, {
      params: {
        teamIds: teamIds,
      },
    })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updataTeamRoutesAssociations(team) {
  return axios
    .put(baseURL + "api/teams/updateteamroutesassociations", team)
    .then((response) => {
      requestSuccess();
      return response;
    })
    .catch((error) => requestError(error.response));
}

function updataTeamTasksAssociations(data) {
  return axios
    .put(baseURL + "api/teams/updateteamtasksassociations", data)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updataTeamUsersAssociations(data) {
  return axios
    .put(baseURL + "api/teams/updateteamusersassociations", data)
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

export {
  getAllTeams,
  getMyTeams,
  getTeams,
  getTeamRoutes,
  getReportTeamRoutes,
  getReportTeamTasks,
  getTeamTasks,
  getTeamUsers,
  addTeam,
  updateTeam,
  deleteTeams,
  updataTeamRoutesAssociations,
  updataTeamTasksAssociations,
  getReportAllTeamRoutes,
  getReportAllTeamUsers,
  getReportAllTeamTasks,
  updataTeamUsersAssociations,
};
