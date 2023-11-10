import axios from "axios";
import { requestError } from "../utils";
import { getProfile, getUserId } from "./auth";
import { baseURL } from "../../package.json";

function getEmagReportData(puId, endDate) {
  return axios
    .get(baseURL + `api/report/getemagreportdata`, {
      params: { puId, endDate: endDate.toString().replace("+", " ") },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getEmagTrendReport(varId, endDate) {
  let languageId = getProfile().LanguageId;
  return axios
    .get(baseURL + `api/report/gettrendreport`, {
      params: {
        varId,
        endDate: endDate.toString().replace("+", " "),
        languageId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getEmagReportDowntime(puId, endDate) {
  return axios
    .get(baseURL + `api/report/getemagreportdowntimes`, {
      params: { puId, endDate: endDate.toString().replace("+", " ") },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getDowntimeDetails(puId, eventReasonName, endDate, dayOffset) {
  return axios
    .get(baseURL + `api/report/getdowntimedetails`, {
      params: {
        puId,
        eventReasonName,
        endDate: endDate.toString().replace("+", " "),
        dayOffset,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getMultipleAssignments(linesList) {
  return axios
    .get(baseURL + `api/report/getmultipleassignments`, {
      params: { linesList: linesList.join(",") },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getUnassignedTasks(plIds, routeFlag, teamFlag) {
  return axios
    .get(baseURL + `api/report/getunassignedtasks`, {
      params: { plIds, routeFlag, teamFlag },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTasksPlanning(
  granularity,
  topLevelId,
  startTime,
  endTime,
  routeIds,
  teamIds,
  teamDetails,
  departments,
  lines,
  units
) {
  let userId = getUserId();

  return axios
    .get(baseURL + `api/report/gettasksplanning`, {
      params: {
        granularity,
        startTime,
        endTime,
        userId,
        routeIds,
        teamIds,
        teamDetails,
        departments,
        lines,
        units,
        topLevelId,
        subLevel: 0,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTasksPlanningDetail(
  varId,
  granularity,
  topLevelId,
  startTime,
  endTime,
  routeIds,
  teamIds,
  teamDetails
) {
  let userId = getUserId();

  return axios
    .get(baseURL + `api/report/gettasksplanningdetail`, {
      params: {
        varId,
        granularity,
        startTime,
        endTime,
        userId,
        routeIds,
        teamIds,
        teamDetails,
        topLevelId,
        subLevel: 0,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getSchedulingErrors(
  deptIds,
  lineIds,
  masterIds,
  slaveIds,
  groupIds,
  variableIds
) {
  return axios
    .get(baseURL + `api/report/schedulingerrors`, {
      params: {
        deptIds,
        lineIds,
        masterIds,
        slaveIds,
        groupIds,
        variableIds,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getCompliance({
  granularity,
  topLevelId,
  subLevel,
  startTime,
  endTime,
  routeIds,
  teamIds,
  teamDetails,
  qFactorOnly,
  selectionItemId,
  HSEOnly,
  // MinimumUptimeOnly
}) {
  let userId = getUserId();

  return axios
    .get(baseURL + `api/report/getcompliance`, {
      params: {
        granularity,
        startTime,
        endTime,
        userId,
        routeIds,
        teamIds,
        teamDetails,
        qFactorOnly,
        topLevelId,
        subLevel,
        selectionItemId,
        HSEOnly,
        // MinimumUptimeOnly
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getComplianceSpecs(granularity, ids, startDate, endDate) {
  return axios
    .get(baseURL + `api/report/getcompliancespecs`, {
      params: {
        granularity,
        ids,
        startDate,
        endDate,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getCompliancePrint({
  granularity,
  topLevelId,
  subLevel,
  startTime,
  endTime,
  routeIds,
  teamIds,
  teamDetails,
  qFactorOnly,
  HSEOnly,
  // MinimumUptimeOnly
}) {
  let userId = getUserId();

  return axios
    .get(baseURL + `api/report/getcomplianceprint`, {
      params: {
        granularity,
        startTime,
        endTime,
        userId,
        routeIds,
        teamIds,
        teamDetails,
        qFactorOnly,
        topLevelId,
        subLevel,
        HSEOnly,
        // MinimumUptimeOnly
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

export {
  getEmagReportData,
  getEmagTrendReport,
  getEmagReportDowntime,
  getDowntimeDetails,
  getMultipleAssignments,
  getUnassignedTasks,
  getTasksPlanning,
  getTasksPlanningDetail,
  getSchedulingErrors,
  getCompliance,
  getComplianceSpecs,
  getCompliancePrint,
};
