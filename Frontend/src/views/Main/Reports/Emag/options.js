//#region plant model filters

function updatePlantModelView(key, values, state) {
  const { lines, units, workcells } = state.plantModel;

  let temp = {};

  temp.lines = state.lines;
  temp.units = state.units;
  temp.workcells = state.workcells;

  temp.plantModel = {
    lines,
    units,
    workcells,
  };

  switch (key) {
    case "lines":
      temp.units = [];
      temp.workcells = [];
      temp.plantModel.lines = values;
      temp.plantModel.units = [];
      temp.plantModel.workcells = [];
      break;
    case "units":
      temp.workcells = [];
      temp.plantModel.units = values;
      temp.plantModel.workcells = [];
      break;
    case "workcells":
      temp.groups = [];
      temp.plantModel.workcells = values;
      break;

    default:
      break;
  }

  return temp;
}
//#endregion

const infoDTDetails = [
  { type: "DataValue", title: "Location", field: "Location" },
  { type: "DataValue", title: "Duration", field: "Duration" },
  { type: "LineSeparator" },
  { type: "DataValue", title: "Start Time", field: "StartTime" },
  { type: "DataValue", title: "End Time", field: "EndTime" },
  { type: "LineSeparator" },
  { type: "DataValue", title: "Reason 1", field: "Reason1" },
  { type: "DataValue", title: "Reason 2", field: "Reason2" },
  { type: "DataValue", title: "Reason 3", field: "Reason3" },
  { type: "DataValue", title: "Reason 4", field: "Reason4" },
  { type: "LineSeparator" },
  { type: "DataValue", title: "Cause Comment", field: "CauseComment" },
  { type: "DataValue", title: "Action Comment", field: "ActionComment" },
];

export { updatePlantModelView, infoDTDetails };
