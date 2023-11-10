import React, { PureComponent } from "react";
import SelectBox from "../../../../../components/SelectBox";
import DateTime from "../../../../../components/DateTime";
import dayjs from "dayjs";
import {
  getLines,
  getUnits,
  getWorkcells,
} from "../../../../../services/plantModel";
import { updatePlantModelView } from "../options";
import { setIdsByClassName } from "../../../../../utils/index";
import styles from "../styles.module.scss";

const initialState = {
  data: [],
  lines: [],
  units: [],
  workcells: [],
  plantModel: {
    lines: [],
    units: [],
    workcells: [],
  },
  // startDate: dayjs().add(-1, "month").format("YYYY-MM-DD HH:mm:ss"),
  endDate: dayjs().format("YYYY-MM-DD"),
};

class Filters extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      ...initialState,
    };
  }

  componentDidMount() {
    getLines().then((response) => this.setState({ lines: response }));
  }

  componentDidUpdate = (prevProps, prevState) => {
    const { plantModel } = this.state;
    const { lines, units } = plantModel;
    const { lines: prevLines, units: prevUnits } = prevState.plantModel;

    if (prevLines !== lines && lines.length > 0) {
      getUnits(lines.join(",")).then((response) =>
        this.setState({ units: response })
      );
    }

    if (prevUnits !== units && units.length > 0) {
      getWorkcells(units.join(",")).then((response) =>
        this.setState({ workcells: response })
      );
    }
    this.disabledToRun();
    this.setSelectBoxIds();
  };

  setSelectBoxIds = () => {
    setIdsByClassName([
      {
        idContainer: "sboLinesEmag",
        tagName: "input",
        ids: ["txtSearchSboLinesEmag"],
      },
      {
        idContainer: "sboUnitsEmag",
        tagName: "input",
        ids: ["txtSearchSboUnitsEmag"],
      },
      {
        idContainer: "sboWorkcellsEmag",
        tagName: "input",
        ids: ["txtSearchsboWorkcellsEmag"],
      },
    ]);
  };

  disabledToRun = () => {
    const { plantModel } = this.state;
    const { workcells } = plantModel;

    var disabled = false;

    if (workcells.length === 0) {
      disabled = true;
    }

    document.getElementById("btnRunReport").disabled = disabled;
  };

  handlerSelectBox = (key, values) => {
    let filters = updatePlantModelView(key, values, this.state);
    this.setState({ plantModel: { ...this.state.plantModel }, ...filters });
  };

  handlerDatePicker = (e) => {
    this.setState({
      endDate: e.value,
    });
  };

  render() {
    const { t } = this.props;
    const {
      lines,
      units,
      workcells,
      plantModel,
      // startDate,
      endDate,
    } = this.state;

    return (
      <React.Fragment>
        <div className={styles.filterContent}>
          <div className={styles.dataTimeContainer}>
            <label className={styles.title}>{t("End date")}:&nbsp;</label>
            <DateTime
              id="dbxEndDateEmag"
              type="date"
              onValueChanged={this.handlerDatePicker}
              value={endDate}
              pickerType="calendar"
              applyValueMode={"instantly"}
            />
          </div>
          <div className={styles.plantModelSelection}>
            <SelectBox
              id="sboLinesEmag"
              text={t("Production Line")}
              enableSelectAll={false}
              enableClear={false}
              store={lines}
              isMultiple={false}
              className={styles.selectBoxPM}
              value={plantModel.lines}
              onChange={(values) => this.handlerSelectBox("lines", values)}
              labelKey="LineDesc"
              valueKey="LineId"
              isLoading={false}
            />
            <SelectBox
              id="sboUnitsEmag"
              text={t("Primary Unit")}
              enableSelectAll={false}
              enableClear={false}
              store={units}
              isMultiple={false}
              className={styles.selectBoxPM}
              value={plantModel.units}
              onChange={(values) => this.handlerSelectBox("units", values)}
              labelKey="MasterDesc"
              valueKey="MasterId"
              isLoading={false}
            />
            <SelectBox
              id="sboWorkcellsEmag"
              text={t("Module")}
              enableSelectAll={false}
              enableClear={false}
              store={workcells}
              isMultiple={false}
              className={styles.selectBoxPM}
              value={plantModel.workcells}
              onChange={(values) => this.handlerSelectBox("workcells", values)}
              labelKey="SlaveDesc"
              valueKey="SlaveId"
              isLoading={false}
            />
          </div>
        </div>
      </React.Fragment>
    );
  }
}

export default Filters;
