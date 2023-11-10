import axios, { post } from "axios";
import { getUserId } from "./auth";
import { baseURL } from "../../package.json";
import { requestError } from "../utils";

// 1) Raw Data File Upload
function readDataFromExcelFile(sheet) {
  return axios
    .get(baseURL + `api/versionmanagement/readdatafromexcelfile`, {
      params: {
        userId: getUserId(),
        sheet,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

// 2)  Raw Data File Validation
function readandValidateRawDatafile(
  path,
  sheet,
  linelevelcomparision,
  modulelevelcomparision
) {
  var userId = getUserId();

  return axios
    .get(baseURL + `api/versionmanagement/readandvalidaterawdatafile`, {
      params: {
        userId,
        path,
        sheet,
        linelevelcomparision,
        modulelevelcomparision,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

// 3) Proficy Data Upload
function readProficyData(
  path,
  moduleLeveComparision,
  lineLevelComparision,
  plId,
  puId
) {
  return axios
    .get(baseURL + `api/versionmanagement/readproficydata`, {
      params: {
        path,
        moduleLeveComparision,
        lineLevelComparision,
        plId,
        puId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

// 4) Proficy Plant Model Validation
function validateProficyPlantModelConfiguration(
  path,
  lineLevelComparision,
  modulelevelcomparision,
  lineId,
  puId,
  sheet
) {
  var userId = getUserId();

  return axios
    .get(
      baseURL + `api/versionmanagement/validateProficyPlantModelConfiguration`,
      {
        params: {
          path,
          lineLevelComparision,
          modulelevelcomparision,
          lineId,
          slaveUnitId: puId,
          userId,
          sheet,
        },
      }
    )
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function addNewModulestoPlantModelDataSource(
  path,
  lineLevelComparision,
  modulelevelcomparision,
  lineId,
  moduleId,
  sheet
) {
  var userId = getUserId();

  return axios
    .get(
      baseURL + `api/versionmanagement/addNewModulestoPlantModelDataSource`,
      {
        params: {
          path,
          lineLevelComparision,
          modulelevelcomparision,
          lineId,
          slaveUnitId: moduleId,
          userId,
          sheet,
        },
      }
    )
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

// 5)
function compareRawDataAndProficy(
  path,
  modulelevelcomparision,
  sheet,
  plId,
  puId
) {
  var userId = getUserId();

  return axios
    .get(baseURL + `api/versionmanagement/compareRawDataAndProficy`, {
      params: {
        path,
        modulelevelcomparision,
        userId,
        sheet,
        plId: plId,
        puId: puId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

// 6)
function taskToUpdate(
  path,
  sheet,
  lineLevelComparision,
  modulelevelcomparision,
  plId,
  puId
) {
  var userId = getUserId();
  return axios
    .get(baseURL + `api/versionmanagement/taskToUpdate`, {
      params: {
        path,
        userId,
        sheet,
        lineLevelComparision,
        modulelevelcomparision,
        plId: plId,
        puId: puId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getLineVersionStatistics(path, sheet, lineLevelComparision, lineId) {
  var userId = getUserId();

  return axios
    .get(baseURL + `api/versionmanagement/getLineVersionStatistics`, {
      params: {
        path,
        userId,
        sheet,
        lineLevelComparision,
        lineId: lineId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getModuleVersionStatistics(
  path,
  sheet,
  modulelevelcomparision,
  lineId
) {
  var userId = getUserId();

  return axios
    .get(baseURL + `api/versionmanagement/getModuleVersionStatistics`, {
      params: {
        userId,
        path,
        sheet,
        modulelevelcomparision,
        puId: lineId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function saveAndUploadExcelFile(formData, config) {
  let userId = getUserId();

  const url = baseURL + `api/versionmanagement/fileupload?userId=${userId}`;
  return post(url, formData, config)
    .then((response) => response)
    .catch((error) => "File upload error");
}

function deleteFile(path) {
  let userId = getUserId();

  return axios
    .delete(
      baseURL + `api/versionmanagement/deletefile?userId=${userId}&path=${path}`
    )
    .then((response) => response)
    .catch((error) => requestError(error.response));
}

export {
  readDataFromExcelFile,
  readandValidateRawDatafile,
  readProficyData,
  validateProficyPlantModelConfiguration,
  addNewModulestoPlantModelDataSource,
  compareRawDataAndProficy,
  taskToUpdate,
  getLineVersionStatistics,
  getModuleVersionStatistics,
  saveAndUploadExcelFile,
  deleteFile,
};
