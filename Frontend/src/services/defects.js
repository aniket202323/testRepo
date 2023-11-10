import axios from "axios";
import { getProfile } from "./auth";
import { requestSuccess, requestError } from "../utils";
import { baseURL } from "../../package.json";
import { languages } from "../utils";

function getDefectTypes() {
  let eDHToken = getProfile().EDHAccessToken;
  let language = languages[getProfile().LanguageId ?? "en"];

  return axios
    .get(baseURL + `api/defects/defecttypes`, {
      headers: { EDHAccessToken: eDHToken },
      params: { language },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getDefectComponents() {
  let eDHToken = getProfile().EDHAccessToken;
  let language = languages[getProfile().LanguageId ?? "en"];

  return axios
    .get(baseURL + `api/defects/defectcomponents`, {
      headers: { EDHAccessToken: eDHToken },
      params: { language },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getDefectHowFoundList() {
  let eDHToken = getProfile().EDHAccessToken;
  let language = languages[getProfile().LanguageId ?? "en"];

  return axios
    .get(baseURL + `api/defects/defecthowfoundlist`, {
      headers: { EDHAccessToken: eDHToken },
      params: { language },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getDefectPriorities() {
  let eDHToken = getProfile().EDHAccessToken;
  let language = languages[getProfile().LanguageId ?? "en"];

  return axios
    .get(baseURL + `api/defects/defectpriorities`, {
      headers: { EDHAccessToken: eDHToken },
      params: { language },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getInstanceOpenedDefects(testId) {
  return axios
    .get(baseURL + `api/defects/getinstanceopeneddefects`, {
      params: {
        TestId: testId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getTaskOpenedDefects(varId) {
  return axios
    .get(baseURL + `api/defects/gettaskopeneddefects`, {
      params: {
        VarId: varId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getDefectsHistory(varId, nbrBack = 3) {
  return axios
    .get(baseURL + `api/defects/getdefectshistory`, {
      params: {
        VarId: varId,
        NbrBack: nbrBack,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getEmagDefectDetails(varId, ColumnTime) {
  return axios
    .get(baseURL + `api/defects/getemagdefectdetails`, {
      params: {
        VarId: varId,
        ColumnTime: ColumnTime,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getFLDefects(departmentId, prodLineId, prodUnitId) {
  let token = getProfile().EDHToken;
  let eDHToken = getProfile().EDHAccessToken;

  return axios
    .get(baseURL + `api/defects/getfldefects`, {
      params: {
        Credentials: token,
        DepartmentId: departmentId ?? "",
        ProdLineId: prodLineId ?? "",
        ProdUnitId: prodUnitId ?? "",
      },
      headers: { EDHAccessToken: eDHToken },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getPlantModelByFLCode(FLCode) {
  return axios
    .get(baseURL + `api/defects/getplantmodelbyflcode`, {
      params: {
        FLCode,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function addDefect(defect) {
  let eDHToken = getProfile().EDHAccessToken;

  return axios
    .post(baseURL + "api/defects/adddefect", defect, {
      headers: { EDHAccessToken: eDHToken },
    })
    .then((response) => {
      requestSuccess();
      if (response?.data.toLowerCase() !== "ok") {
        let message = response?.data?.toLowerCase().includes("sap error")
          ? response?.data.replace(",", " to").replace("SAP", "SAP,")
          : response?.data;
        requestError({
          status: 500,
          data: { ExceptionMessage: message || "" },
          isSecondNotification: true,
        });
      }
      return 1;
    })
    .catch((error) => {
      requestError(error.response);
      return -1;
    });
}

export {
  getDefectTypes,
  getDefectComponents,
  getDefectHowFoundList,
  getDefectPriorities,
  getInstanceOpenedDefects,
  getTaskOpenedDefects,
  getDefectsHistory,
  getEmagDefectDetails,
  getFLDefects,
  getPlantModelByFLCode,
  addDefect,
};
