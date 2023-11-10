const VIEW = {
  TASK_SELECTION: {
    PlantModel: "Plant Model",
    MyTeams: "My Teams",
    Teams: "Teams",
    MyRoutes: "My Routes",
    Routes: "Routes",
  },
  ADMINISTRATION: {
    RoutesMgmt: "Routes Management",
    TeamsMgmt: "Teams Management",
    TasksMgmt: "Tasks Management",
    VersionMgmt: "Version Management",
    QrCodeByTask: "QR Code By Task",
    QrCodeByRoute: "QR Code By Route",
  },
  REPORT: {
    ComplianceRpt: "CIL Results Report",
    EmagRpt: "eMag Report",
    TasksPlanningRpt: "Tasks Planning Report",
    MultipleAssignmentsTasksRpt: "Multiple Assignments Tasks Report",
    TasksConfigurationRpt: "Tasks Configuration Report",
    UnassignedTasksRpt: "Unassigned Tasks Report",
    SchedulingErrorsRpt: "Scheduling Errors Report",
  },
};

const CUSTOM_VIEW_SCREEN_DESC = {
  TaskSelection: "DataEntry",
  TasksMgmt: "TasksManagement",
  TasksConfigurationRpt: "TasksConfigurationReport",
  TasksPlanningRpt: "TasksPlanningReport",
};

const CUSTOM_VIEW_TYPE = {
  FL: 1,
  PlantModel: 2,
  Routes: 3,
  Teams: 4,
  RawData: 5,
  UserDefined: 99,
};

const TASK_STATE = {
  Ok: "Ok",
  Defect: "Defect",
  Late: "Late",
  Pending: "Pending",
};

const TASK_STATE_BG = {
  Ok: "background-color: #1bff00 !important; color: black; position: relative;",
  Defect: "background: #e82015; color: white; position: relative;",
  Late: "background-color: #ffff00; color: black; position: relative;",
  Pending: "background-color: #3030ff; color: white; position: relative;",
};

const CL_TASKS_STATE = {
  inTarget: "background-color: #1bff00 !important; color: black;",
  outTarget: "background-color: #e82015; color: white;",
};

const GRANULARITY = {
  None: 0,
  Team: 1,
  Route: 2,
  Site: 3,
  Department: 4,
  Line: 5,
  MasterUnit: 6,
  Module: 7,
  Task: 8,
};

const CUSTOM_PERIOD = {
  None: 0,
  Yesterday: 1,
  Today: 2,
  Tomorrow: 3,
  LastWeek: 4,
  ThisWeek: 5,
  NextWeek: 6,
  LastMonth: 7,
  ThisMonth: 8,
  NextMonth: 9,
  Last30Days: 10,
  Next30Days: 11,
  UserDefined: 12,
};

const EMAG_COLOR = {
  0: "#000000",
  1: "#00b055", //Ok
  2: "#ff7000", //Done Late
  3: "#003daf", //Pending
  4: "#ffb80f", //Late
  5: "#101010", //Missed
  6: "#fe1a0e", //Defect
  7: "#333333", //Downtime
};

export {
  VIEW,
  CUSTOM_VIEW_SCREEN_DESC,
  CUSTOM_VIEW_TYPE,
  TASK_STATE,
  TASK_STATE_BG,
  GRANULARITY,
  CUSTOM_PERIOD,
  EMAG_COLOR,
  CL_TASKS_STATE,
};
