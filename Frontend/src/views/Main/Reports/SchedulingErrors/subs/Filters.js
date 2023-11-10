import React, { PureComponent } from "react";
import SelectBox from "../../../../../components/SelectBox";
import {
  getDepartments,
  getLines,
  getUnits,
  getWorkcells,
  getProductionGroups,
} from "../../../../../services/plantModel";
import { setIdsByClassName } from "../../../../../utils/index";
import { updatePlantModelView } from "../options";
import styles from "../styles.module.scss";

const initialState = {
  data: [],
  departments: [],
  lines: [],
  units: [],
  workcells: [],
  groups: [],
  plantModel: {
    departments: [],
    lines: [],
    units: [],
    workcells: [],
    groups: [],
  },
};

class Filters extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      ...initialState,
    };
  }

  componentDidMount() {
    getDepartments().then((response) =>
      this.setState({ departments: response })
    );
  }

  componentDidUpdate = (prevProps, prevState) => {
    const { plantModel } = this.state;
    const { departments, lines, units, workcells } = plantModel;
    const {
      departments: prevDepartments,
      lines: prevLines,
      units: prevUnits,
      workcells: prevWorkcells,
    } = prevState.plantModel;

    if (prevDepartments !== departments && departments.length > 0) {
      getLines(departments.join(",")).then((response) => {
        if (this.state.plantModel.departments.length > 0)
          this.setState({ lines: response });
      });
    } else if (prevDepartments !== departments && departments.length === 0) {
      this.setState({ data: [] });
    }

    if (prevLines !== lines && lines.length > 0) {
      getUnits(lines.join(",")).then((response) => {
        if (this.state.plantModel.lines.length > 0)
          this.setState({ units: response });
      });
    }

    if (prevUnits !== units && units.length > 0) {
      getWorkcells(units.join(",")).then((response) => {
        if (this.state.plantModel.units.length > 0)
          this.setState({ workcells: response });
      });
    }

    if (prevWorkcells !== workcells && workcells.length > 0) {
      getProductionGroups(workcells.join(",")).then((response) => {
        if (this.state.plantModel.workcells.length > 0)
          this.setState({ groups: response });
      });
    }

    this.disabledToRun();
    this.setIdsComponents();
  };

  setIdsComponents = () => {
    setIdsByClassName([
      {
        idContainer: "sboDepartmentsSchedulingErrors",
        tagName: "input",
        ids: ["txtSearchsboDepartmentsSchedulingErrors"],
      },
      {
        idContainer: "sboDepartmentsSchedulingErrors",
        tagName: "button",
        ids: ["btnSboDepartmentsSchedulingErrors"],
        same: true,
      },
      {
        idContainer: "sboLinesSchedulingErrors",
        tagName: "input",
        ids: ["txtSearchsboLinesSchedulingErrors"],
      },
      {
        idContainer: "sboLinesSchedulingErrors",
        tagName: "button",
        ids: ["btnSboLinesSchedulingErrors"],
        same: true,
      },
      {
        idContainer: "sboUnitsSchedulingErrors",
        tagName: "input",
        ids: ["txtSearchsboUnitsSchedulingErrors"],
      },
      {
        idContainer: "sboUnitsSchedulingErrors",
        tagName: "button",
        ids: ["btnSboUnitsSchedulingErrors"],
        same: true,
      },
      {
        idContainer: "sboWorkcellsSchedulingErrors",
        tagName: "input",
        ids: ["txtSearchsboWorkcellsSchedulingErrors"],
      },
      {
        idContainer: "sboWorkcellsSchedulingErrors",
        tagName: "button",
        ids: ["btnSboWorkcellsSchedulingErrors"],
        same: true,
      },
      {
        idContainer: "sboGroupSchedulingErrors",
        tagName: "input",
        ids: ["txtSearchsboGroupsSchedulingErrors"],
      },
      {
        idContainer: "sboGroupSchedulingErrors",
        tagName: "button",
        ids: ["btnSboGroupsSchedulingErrors"],
        same: true,
      },
    ]);
  };

  disabledToRun = () => {
    const { plantModel } = this.state;
    const { departments } = plantModel;

    var disabled = false;

    if (departments.length === 0) {
      disabled = true;
    }

    document.getElementById("btnRunReport").disabled = disabled;
  };

  handlerSelectBox = (key, values) => {
    let filters = updatePlantModelView(key, values, this.state);
    this.setState({ plantModel: { ...this.state.plantModel }, ...filters });
  };

  render() {
    const { t } = this.props;
    const { departments, lines, units, workcells, groups, plantModel } =
      this.state;

    return (
      <React.Fragment>
        <div className={styles.filterContent}>
          <div className={styles.plantModelSelection}>
            <SelectBox
              id="sboDepartmentsSchedulingErrors"
              text={t("Department")}
              enableSelectAll={true}
              enableClear={true}
              store={departments}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.departments}
              onChange={(values) =>
                this.handlerSelectBox("departments", values)
              }
              labelKey="DeptDesc"
              valueKey="DeptId"
              isLoading={false}
            />
            <SelectBox
              id="sboLinesSchedulingErrors"
              text={t("Line")}
              enableSelectAll={true}
              enableClear={true}
              store={lines}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.lines}
              onChange={(values) => this.handlerSelectBox("lines", values)}
              labelKey="LineDesc"
              valueKey="LineId"
              isLoading={false}
            />
            <SelectBox
              id="sboUnitsSchedulingErrors"
              text={t("Primary Unit")}
              enableSelectAll={true}
              enableClear={true}
              store={units}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.units}
              onChange={(values) => this.handlerSelectBox("units", values)}
              labelKey="MasterDesc"
              valueKey="MasterId"
              isLoading={false}
            />
            <SelectBox
              id="sboWorkcellsSchedulingErrors"
              text={t("Module")}
              enableSelectAll={true}
              enableClear={true}
              store={workcells}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.workcells}
              onChange={(values) => this.handlerSelectBox("workcells", values)}
              labelKey="SlaveDesc"
              valueKey="SlaveId"
              isLoading={false}
            />
            <SelectBox
              id="sboGroupSchedulingErrors"
              text={t("Production Group")}
              enableSelectAll={true}
              enableClear={true}
              store={groups}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.groups}
              onChange={(values) => this.handlerSelectBox("groups", values)}
              labelKey="PUGDesc"
              valueKey="PUGId"
              isLoading={false}
            />
          </div>
        </div>
      </React.Fragment>
    );
  }
}

export default Filters;
