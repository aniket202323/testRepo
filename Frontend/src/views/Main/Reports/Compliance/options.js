import { isTablet } from "../../../../utils";

//#region plant model filters

function updatePlantModelView(key, values, state) {
  const { departments, lines, units, teams, myteams, routes, myroutes } =
    state.plantModel;

  let temp = {};

  temp.departments = state.departments;
  temp.lines = state.lines;
  temp.units = state.units;

  temp.teams = state.teams;
  temp.myteams = state.myteams;
  temp.routes = state.routes;
  temp.myroutes = state.myroutes;

  temp.plantModel = {
    departments,
    lines,
    units,
    teams,
    myteams,
    routes,
    myroutes,
  };

  switch (key) {
    case "departments":
      temp.lines = [];
      temp.units = [];
      temp.plantModel.departments = values;
      temp.plantModel.lines = [];
      temp.plantModel.units = [];
      break;
    case "lines":
      temp.units = [];
      temp.plantModel.lines = values;
      temp.plantModel.units = [];
      break;
    case "units":
      temp.plantModel.units = values;
      break;
    default:
      break;
  }

  return temp;
}
//#endregion

//#region grid properties

function getComplianceGridColumns(level = 0) {
  return [
    {
      caption: "Level",
      dataField: "ItemDesc",
      specName: null,
      level: "All",
    },
    {
      caption: "FL3",
      dataField: "Fl3",
      specName: null,
      level: "Task",
      width: "50px",
    },
    {
      caption: "FL4",
      dataField: "Fl4",
      specName: null,
      level: "Task",
      width: "50px",
    },
    {
      caption: "Total Count",
      dataField: "TotalCount",
      specName: null,
      level: "All",
      width: !isTablet() ? "100px" : "50px",
    },
    {
      caption: "On Time",
      dataField: "OnTime",
      specName: null,
      level: "All",
      width: !isTablet() ? "100px" : "50px",
    },
    {
      caption: "Done Late",
      dataField: "DoneLate",
      specName: "Done Late",
      level: "All",
      width: !isTablet() ? "100px" : "50px",
    },
    {
      caption: "Missed",
      dataField: "NumberMissed",
      specName: "Number Missed",
      level: "All",
      width: !isTablet() ? "100px" : "50px",
    },
    {
      caption: "Due (Late)",
      dataField: "TaskDueLate",
      specName: null,
      level: "All",
      width: !isTablet() ? "100px" : "50px",
    },
    {
      caption: "% Done",
      dataField: "PctDone",
      specName: "Pct Done",
      level: "All",
      width: !isTablet() ? "100px" : "50px",
    },
    {
      caption: "Defects Found",
      dataField: "DefectsFound",
      specName: "Defects Found",
      level: "All",
      width: !isTablet() ? "100px" : "60px",
    },
    {
      caption: "Opened Defects",
      dataField: "OpenDefects",
      specName: "Opened Defects",
      level: "All",
      width: !isTablet() ? "100px" : "60px",
    },
    {
      caption: "Stops",
      dataField: "Stops",
      specName: "Stops",
      level: "All",
      width: !isTablet() ? "100px" : "50px",
    },
    {
      caption: "",
      dataField: "eMagReport",
      specName: null,
      level: "All",
      width: "50px",
    },
  ];
}

//#endregion

const Granularity = {
  1: "Team",
  2: "Route",
  3: "Site",
  4: "Department",
  5: "Line",
  6: "Primary Unit",
  7: "Module",
  8: "Task",
};

const CILResultSpec = {
  DoneLate: "Done Late",
  NumberMissed: "Number Missed",
  PctDone: "Pct Done",
  DefectsFound: "Defects Found",
  OpenDefects: "Opened Defects",
};

export {
  updatePlantModelView,
  getComplianceGridColumns,
  CILResultSpec,
  Granularity,
};
