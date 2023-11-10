import axios from "axios";
import { getUserId } from "./auth";
import { requestSuccess, requestError } from "../utils";
import { baseURL } from "../../package.json";

function getDepartments() {
  let userId = getUserId();

  return axios
    .get(baseURL + `api/plantmodel/getdepartments`, {
      params: {
        userId,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

// function getLines(deptId) {
//   let userId = getUserId();

//   return axios
//     .get(baseURL + `api/plantmodel/getlines`, {
//       params: {
//         userId: userId,
//         deptId: deptId,
//       },
//     })
//     .then((response) => response.data)
//     .catch((error) => requestError(error.response));
// }

function getLines(deptId, isRouteManagement) {
  let userId = getUserId();

  return axios({
    method: "get",
    url: baseURL + "api/plantmodel/getlines",
    withCredentials: true,
    params: {
      userId: userId,
      deptId: deptId,
      isRouteManagement,
    },
  })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getUnits(line) {
  return axios
    .get(baseURL + "api/plantmodel/getmasterunits", {
      params: {
        lineId: line,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getWorkcells(units) {
  return axios
    .get(baseURL + `api/plantmodel/getslaveunits`, {
      params: {
        masterId: units,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getProductionGroups(slaveUnitId) {
  if (slaveUnitId)
    return axios
      .get(baseURL + `api/plantmodel/getproductiongroups`, {
        params: {
          slaveUnitId: slaveUnitId,
        },
      })
      .then((response) => response.data)
      .catch((error) => requestError(error.response));
  else return Promise.resolve();
}

function getFL1() {
  return axios
    .get(baseURL + `api/plantmodel/getfl1`)
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getFL2(fl1) {
  return axios
    .get(baseURL + `api/plantmodel/getfl2`, {
      params: {
        Fl1: fl1,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getFL3(fl2) {
  return axios
    .get(baseURL + `api/plantmodel/getfl3`, {
      params: {
        Fl2: fl2,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function getFL4(fl3) {
  return axios
    .get(baseURL + `api/plantmodel/getfl4`, {
      params: {
        Fl3: fl3,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function addModule(lineId, lineDesc, masterUnitId, slaveUnitDesc, fl3) {
  let userId = getUserId();

  return axios
    .post(baseURL + `api/plantmodel/addmodule?userId=${userId}`, {
      LineId: lineId,
      LineDesc: lineDesc,
      MasterUnitId: masterUnitId,
      SlaveUnitDesc: slaveUnitDesc,
      FL3: fl3,
    })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function addProdGroup(
  lineDesc,
  slaveUnitId,
  slaveUnitDesc,
  productionGroupDesc,
  fl4
) {
  let userId = getUserId();

  return axios
    .post(baseURL + `api/plantmodel/addproductiongroup?userId=${userId}`, {
      LineDesc: lineDesc,
      SlaveUnitId: slaveUnitId,
      SlaveUnitDesc: slaveUnitDesc,
      ProductionGroupDesc: productionGroupDesc,
      FL4: fl4,
    })
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function getPlantModelEditMode(plId = 0, plantModelLevel = 4) {
  let userId = getUserId();

  return axios
    .get(baseURL + `api/plantmodel/getplantmodeleditable`, {
      params: {
        userId,
        plId,
        plantModelLevel,
      },
    })
    .then((response) => response.data)
    .catch((error) => requestError(error.response));
}

function updateProdLineUDP(lineDesc, udpName, udpValue) {
  var toDelete = udpValue === "" || udpValue === null;
  return axios
    .put(
      baseURL +
        `api/plantmodel/updateprodlineudp?lineDesc=${lineDesc}&udpName=${udpName}&udpValue=${udpValue}&toDelete=${toDelete}`
    )
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updateProdUnitUDP(lineDesc, unitDesc, udpName, udpValue) {
  var toDelete = udpValue === "" || udpValue === null;
  return axios
    .put(
      baseURL +
        `api/plantmodel/updateprodunitsudp?lineDesc=${lineDesc}&unitDesc=${unitDesc}&udpName=${udpName}&udpValue=${udpValue}&toDelete=${toDelete}`
    )
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

function updateProdGroupUDP(lineDesc, unitDesc, groupDesc, udpName, udpValue) {
  var toDelete = udpValue === "";
  return axios
    .put(
      baseURL +
        `api/plantmodel/updategroupudps?lineDesc=${lineDesc}&unitDesc=${unitDesc}&groupDesc=${groupDesc}&udpName=${udpName}&udpValue=${udpValue}&toDelete=${toDelete}`
    )
    .then(() => requestSuccess())
    .catch((error) => requestError(error.response));
}

export {
  getDepartments,
  getLines,
  getUnits,
  getWorkcells,
  getProductionGroups,
  getFL1,
  getFL2,
  getFL3,
  getFL4,
  addModule,
  addProdGroup,
  getPlantModelEditMode,
  updateProdLineUDP,
  updateProdUnitUDP,
  updateProdGroupUDP,
};
