import React, { PureComponent } from "react";
import SelectBox from "../../../../../components/SelectBox";
import RadioGroup from "../../../../../components/RadioGroup";
import {
  getDepartments,
  getLines,
  getUnits,
  getWorkcells,
  getProductionGroups,
  getFL2,
  getFL1,
  getFL3,
  getFL4,
} from "../../../../../services/plantModel";
import { getFLIds, updateFLView, updatePlantModelView } from "../options";
import { entriesCompare, setIdsByClassName } from "../../../../../utils/index";
import { displayPreload } from "../../../../../components/Framework/Preload";
import styles from "../styles.module.scss";

const initialState = {
  lines: [],
  units: [],
  workcells: [],
  groups: [],
  fl2: [],
  fl3: [],
  fl4: [],
  plantModel: {
    departments: [],
    lines: [],
    units: [],
    workcells: [],
    groups: [],
  },
  fl: {
    fl1: [],
    fl2: [],
    fl3: [],
    fl4: [],
  },
};

export default class Filters extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      tasksConfigFilterGroup: "Plant Model",
      departments: [],
      fl1: [],
      ...initialState,
    };
  }

  componentDidMount = () => {
    displayPreload(true);
    getDepartments().then((response) =>
      this.setState({ departments: response }, () => {
        document.getElementById("btnRunReport").disabled = true;
        displayPreload(false);
      })
    );
    // Promise.all([getDepartments(), getFL1()]).then((response) => {
    //   const [departments, fl1] = response;
    //   this.setState({ departments, fl1 });
    // });
  };

  componentDidUpdate = (prevProps, prevState) => {
    if (this.state.tasksConfigFilterGroup === "Plant Model") {
      const { departments, lines, units, workcells } = this.state.plantModel;
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
    } else {
      const { fl1, fl2, fl3 } = this.state.fl;
      const { fl1: prevFl1, fl2: prevFl2, fl3: prevFl3 } = prevState.fl;

      if (this.state.fl1.length === 0) {
        displayPreload(true);
        getFL1().then((response) =>
          this.setState({ fl1: response }, () => displayPreload(false))
        );
      }

      if (prevFl1 !== fl1 && fl1.length > 0) {
        let FLIds = getFLIds(this.state.fl1, fl1);

        getFL2(FLIds.join(",")).then((response) =>
          this.setState({ fl2: response })
        );
      } else if (prevFl1 !== fl1 && fl1.length === 0) {
        this.setState({ data: [] });
      }

      if (prevFl2 !== fl2 && fl2.length > 0) {
        let FLIds = getFLIds(this.state.fl2, fl2);

        getFL3(FLIds.join(",")).then((response) =>
          this.setState({ fl3: response })
        );
      }

      if (prevFl3 !== fl3 && fl3.length > 0) {
        let FLIds = getFLIds(this.state.fl3, fl3);

        getFL4(FLIds.join(",")).then((response) =>
          this.setState({ fl4: response })
        );
      }
    }
    this.disabledToRun();
    this.setIdsComponents();
  };

  setIdsComponents = () => {
    setIdsByClassName([
      {
        idContainer: "cdrFilters",
        class: "dx-radiobutton",
        ids: ["rbnPlantModelTasksConfiguration", "rbnFLTasksConfiguration"],
      },
      {
        idContainer: "sboDepartmentsTasksConfiguration",
        tagName: "input",
        ids: ["txtSearchsboDepartmentsTasksConfiguration"],
      },
      {
        idContainer: "sboDepartmentsTasksConfiguration",
        tagName: "button",
        ids: ["btnClearsboDepartmentsTasksConfiguration"],
      },
      {
        idContainer: "sboLinesTasksConfiguration",
        tagName: "input",
        ids: ["txtSearchsboLinesTasksConfiguration"],
      },
      {
        idContainer: "sboLinesTasksConfiguration",
        tagName: "button",
        ids: ["btnClearsboLinesTasksConfiguration"],
      },
      {
        idContainer: "sboUnitsTasksConfiguration",
        tagName: "input",
        ids: ["txtSearchsboUnitsTasksConfiguration"],
      },
      {
        idContainer: "sboUnitsTasksConfiguration",
        tagName: "button",
        ids: ["btnClearsboUnitsTasksConfiguration"],
      },
      {
        idContainer: "sboWorkcellsTasksConfiguration",
        tagName: "input",
        ids: ["txtSearchsboWorkcellsTasksConfiguration"],
      },
      {
        idContainer: "sboWorkcellsTasksConfiguration",
        tagName: "button",
        ids: ["btnClearsboWorkcellsTasksConfiguration"],
      },
      {
        idContainer: "sboGroupsTasksConfiguration",
        tagName: "input",
        ids: ["txtSearchsboGroupsTasksConfiguration"],
      },
      {
        idContainer: "sboGroupsTasksConfiguration",
        tagName: "button",
        ids: ["btnClearsboGroupsTasksConfiguration"],
      },
      {
        idContainer: "sboFl1TasksConfiguration",
        tagName: "input",
        ids: ["txtSearchsboFl1TasksConfiguration"],
      },
      {
        idContainer: "sboFl1TasksConfiguration",
        tagName: "button",
        ids: ["btnClearsboFl1TasksConfiguration"],
      },
      {
        idContainer: "sboFl2TasksConfiguration",
        tagName: "input",
        ids: ["txtSearchsboFl2TasksConfiguration"],
      },
      {
        idContainer: "sboFl2TasksConfiguration",
        tagName: "button",
        ids: ["btnClearsboFl2TasksConfiguration"],
      },
      {
        idContainer: "sboFl3TasksConfiguration",
        tagName: "input",
        ids: ["txtSearchsboFl3TasksConfiguration"],
      },
      {
        idContainer: "sboFl3TasksConfiguration",
        tagName: "button",
        ids: ["btnClearsboFl3TasksConfiguration"],
      },
      {
        idContainer: "sboFl4TasksConfiguration",
        tagName: "input",
        ids: ["txtSearchsboFl4TasksConfiguration"],
      },
      {
        idContainer: "sboFl4TasksConfiguration",
        tagName: "button",
        ids: ["btnClearsboFl4TasksConfiguration"],
      },
    ]);
  };

  disabledToRun = () => {
    const { tasksConfigFilterGroup, plantModel, fl } = this.state;

    var disabled = false;
    if (
      (tasksConfigFilterGroup === "Plant Model" &&
        plantModel.departments.length === 0) ||
      (tasksConfigFilterGroup === "Functional Location" && fl.fl1.length === 0)
    ) {
      disabled = true;
    }

    document.getElementById("btnRunReport").disabled = disabled;
  };

  handlerPM = (key, values) => {
    if (!entriesCompare(values, this.state.plantModel[key])) {
      this.setState({
        ...this.state,
        ...updatePlantModelView(key, values, this.state),
      });
    }
  };

  handlerFL = (key, values) => {
    if (!entriesCompare(values, this.state.fl[key])) {
      this.setState({
        ...this.state,
        ...updateFLView(key, values, this.state),
      });
    }
  };

  handlerTaskConfigFilterGroup = (e) => {
    this.setState({
      ...this.state,
      ...initialState,
      tasksConfigFilterGroup: e.value,
    });
  };

  render() {
    const { t } = this.props;
    const {
      tasksConfigFilterGroup,
      departments,
      lines,
      units,
      workcells,
      groups,
      fl1,
      fl2,
      fl3,
      fl4,
      plantModel,
      fl,
    } = this.state;

    return (
      <React.Fragment>
        <div className="tasksConfigFilterGroup">
          <RadioGroup
            items={[
              {
                text: t("Plant Model"),
                value: "Plant Model",
              },
              {
                text: t("Functional Location"),
                value: "Functional Location",
              },
            ]}
            valueExpr="value"
            displayExpr="text"
            value={tasksConfigFilterGroup}
            onValueChanged={this.handlerTaskConfigFilterGroup}
          />
        </div>
        {tasksConfigFilterGroup === "Plant Model" ? (
          <div className={styles.multiSelectionGroup}>
            <SelectBox
              id="sboDepartmentsTasksConfiguration"
              text={t("Department")}
              enableSelectAll={false}
              enableClear={true}
              store={departments}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.departments}
              onChange={(values) => this.handlerPM("departments", values)}
              labelKey="DeptDesc"
              valueKey="DeptId"
              isLoading={false}
              isDisable={false}
            />
            <SelectBox
              id="sboLinesTasksConfiguration"
              text={t("Production Line")}
              enableSelectAll={false}
              enableClear={true}
              store={lines}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.lines}
              onChange={(values) => this.handlerPM("lines", values)}
              labelKey="LineDesc"
              valueKey="LineId"
              isLoading={false}
              isDisable={false}
            />
            <SelectBox
              id="sboUnitsTasksConfiguration"
              text={t("Primary Unit")}
              enableSelectAll={false}
              enableClear={true}
              store={units}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.units}
              onChange={(values) => this.handlerPM("units", values)}
              labelKey="MasterDesc"
              valueKey="MasterId"
              isLoading={false}
              isDisable={false}
            />
            <SelectBox
              id="sboWorkcellsTasksConfiguration"
              text={t("Module")}
              enableSelectAll={false}
              enableClear={true}
              store={workcells}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.workcells}
              onChange={(values) => this.handlerPM("workcells", values)}
              labelKey="SlaveDesc"
              valueKey="SlaveId"
              isLoading={false}
              isDisable={false}
            />
            <SelectBox
              id="sboGroupsTasksConfiguration"
              text={t("Production Group")}
              enableSelectAll={false}
              enableClear={true}
              store={groups}
              isMultiple={true}
              className={styles.selectBoxPM}
              value={plantModel.groups}
              onChange={(values) => this.handlerPM("groups", values)}
              labelKey="PUGDesc"
              valueKey="PUGId"
              isLoading={false}
              isDisable={false}
            />
          </div>
        ) : (
          <div className={styles.multiSelectionGroup}>
            <SelectBox
              id="sboFl1TasksConfiguration"
              text={t("FL1")}
              enableSelectAll={false}
              enableClear={true}
              store={fl1}
              isMultiple={true}
              className={styles.selectBoxFL}
              value={fl.fl1}
              onChange={(values) => this.handlerFL("fl1", values)}
              labelKey="ItemDesc"
              valueKey="ItemDesc"
              isLoading={false}
              isDisable={false}
            />
            <SelectBox
              id="sboFl2TasksConfiguration"
              text={t("FL2")}
              enableSelectAll={false}
              enableClear={true}
              store={fl2}
              isMultiple={true}
              className={styles.selectBoxFL}
              value={fl.fl2}
              onChange={(values) => this.handlerFL("fl2", values)}
              labelKey="ItemDesc"
              valueKey="ItemDesc"
              isLoading={false}
              isDisable={false}
            />
            <SelectBox
              id="sboFl3TasksConfiguration"
              text={t("FL3")}
              enableSelectAll={false}
              enableClear={true}
              store={fl3}
              isMultiple={true}
              className={styles.selectBoxFL}
              value={fl.fl3}
              onChange={(values) => this.handlerFL("fl3", values)}
              labelKey="ItemDesc"
              valueKey="ItemDesc"
              isLoading={false}
              isDisable={false}
            />
            <SelectBox
              id="sboFl4TasksConfiguration"
              text={t("FL4")}
              enableSelectAll={false}
              enableClear={true}
              store={fl4}
              isMultiple={true}
              className={styles.selectBoxFL}
              value={fl.fl4}
              onChange={(values) => this.handlerFL("fl4", values)}
              labelKey="ItemDesc"
              valueKey="ItemDesc"
              isLoading={false}
              isDisable={false}
            />
          </div>
        )}
      </React.Fragment>
    );
  }
}
